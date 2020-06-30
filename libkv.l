# picolisp-kv - https://github.com/aw/picolisp-kv
#
# Server library to be included in other PicoLisp tools
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

# CONSTANTS
(setq
  *KV_verbose NIL
  *KV_port  6378
  *KV_pass  NIL
  *KV_uuid  "7672FDB2-4D29-4F10-BA7C-8EAD0E29626E" # for client handshake
  *KV_startup_memory (* (heap) 1024 1024) )

# INITIALIZE
# Every integer statistic must be zero'd first. Others are wiped first
(off *KV/%stats%/connected_clients)
(zero
  *KV/%stats%/total_connections_received
  *KV/%stats%/total_commands_processed
  *KV/%stats%/total_net_input_bytes
  *KV/%stats%/total_net_output_bytes
  *KV/%stats%/rejected_connections
  *KV/%stats%/keyspace_hits
  *KV/%stats%/keyspace_misses )

# LOAD
(load "module.l" "commands.l" "lolwut.l" "persistence.l")

# STATS
[de kv-stat (Key Value)
  (set (any (pack "*KV/%stats%/" Key)) Value) ]

# Process the message and send the result to the child over the named pipe
[de kv-sibling-job (Pid Msg)
  (let (Result (kv-process Pid Msg)      # here's the magic, process the message
        Pipe_child (pil "tmp/" *PPid "/pipe_child_" Pid) )

    (wait 1)
    (kv-output "[msg]   to client: " (sym Result))
    (inc '*KV/%stats%/total_net_output_bytes (bytes Result))

    (ifn  Result
          (inc '*KV/%stats%/keyspace_misses)
          (inc '*KV/%stats%/keyspace_hits)
          (when *KV_persist
                (kv-save-aof Msg *KV_aof)) )# save the request to a log file

    (out Pipe_child                      # named pipe of the child process
      (pr (cons "message" Result) ]

# Remove the child's process ID from the list of connected clients
[de kv-remove-client (Pid)
  (kv-stat "connected_clients"
    (filter '((N) (unless (= (car N) Pid) N))
            *KV/%stats%/connected_clients) )
  NIL ]                                  # NIL breaks from the (kv-sibling) loop

# Increment some statistics counters for the INFO command when there's an error
[de kv-sibling-error (Pid Msg)
  (inc '*KV/%stats%/rejected_connections)
  (inc '*KV/%stats%/total_net_output_bytes (bytes Msg))
  (kv-remove-client Pid)                 # seriously, forget about the child
  NIL ]                                  # NIL breaks from the (kv-sibling) loop

# Process the message depending on its type
[de kv-sibling-message (Type Pid Msg)
  (case Type
    ("error" (kv-sibling-error Pid Msg)) # things aren't working out
    ("done"  (kv-remove-client Pid))     # forget about the child, it's over
    ("message" (kv-sibling-job Pid Msg) ]# do some work in the sibling

# Increment some statistics counters for the INFO command
[de kv-stats-update (Pid Msg)
  (inc '*KV/%stats%/total_commands_processed)
  (inc '*KV/%stats%/total_net_input_bytes (bytes Msg))
  (push1 '*KV/%stats%/total_connections_received Pid) ]

# IPC
# Perform some tasks when the sibling exits
[de kv-sibling-exit ()
  (kv-output "[sibling]=" *Pid " exiting")
  (when *KV_persist
        (when (info *KV_db_lock)
              (kill (in *KV_db_lock (format (line T))) 9) ) # remove a locked process
        (call 'rm "-f" *KV_aof_lock *KV_db_lock)
        (unless *Msg (kv-save-db) ]

# Receive a message in the sibling, from the child, over a named pipe, then
# process the message and send the reply back to the child
[de kv-listen-sibling ()
  [in *Pipe_sibling                      # named pipe
    (when (rd)                           # expect one message from the child
          (let Msg @
            (kv-stats-update (cadr Msg) (caddr Msg))
            (kv-sibling-message          # process the child's message
              (car Msg)                  # should be the 'type' of message
              (cadr Msg)                 # should be the 'sender' of the message
              (caddr Msg) ]              # should be the actual message
  T ]

# Receive a message from a sibling over a named pipe and send it to the client
[de kv-listen-child ()
  (in *Pipe_child                        # named pipe
    (when (rd)                           # expect one message from the sibling
          (let Result @
            (kv-out-sock  "message"      # send the message to the client
                          (cdr Result) ]

# Receive a message from the client over the TCP socket
[de kv-listen-sock ()
  (in *Sock                              # TCP socket
    (while (rd)                          # get multiple messages from the client
      (let Msg @
        (kv-output "[msg] from client: (pid: " *Pid ") " *Adr " " (sym Msg))
        (kv-out-sibling "message" Msg)   # tell the sibling what the client said
        (kv-listen-child) ]              # listen for sibling messages

# Send a message to the sibling over a named pipe
[de kv-out-sibling (Type . @)
  (out *Pipe_sibling                     # named pipe
    (pr (list Type *Pid (car (rest) ]

# Send a message to the client over a TCP socket
[de kv-out-sock (Type Msg)
  (out *Sock (pr (cons Type Msg) ]       # TCP socket

[de kv-hash (String)
  (hash String) ]                        # non cryptographically secure hash

# Authenticate the client via handshake, and authorizate with a password
[de kv-auth (Auth)
  (and
    (lst? Auth)                          # is the client even sending a list?
    (= "AUTH" (car Auth))                # handshake
    (= (kv-hash *KV_pass) (caddr Auth))  # shared password
    (kv-out-sock
      "AUTH"
      (kv-hash (pack (cadr Auth) *KV_uuid) ] # tell the client we're good

# Create named pipes in the tmp directory of the parent process
[de kv-mkfifo (Type)
  (let Filename
    (if (= Type "child")
        (setq *Pipe_child (pil "tmp/" *PPid "/pipe_child_" *Pid))
        (setq *Pipe_sibling (tmp "pipe_sibling")) )

    (unless (info Filename)
            (call "mkfifo" Filename) ]

# Send some output to the console
[de kv-output @
  (when *KV_verbose (prinl "[" (dat$ (date) "-") "T" (tim$ (time) T) "] " (rest) ]

# Perform some tasks when the child exits
[de kv-child-exit ()
  (kv-output "[child]=" *Pid " exiting")
  (kv-out-sibling "done")                # tell the sibling the child is done
  (when (info *Pipe_child)
        (call 'rm *Pipe_child) )         # remove the temporary named pipe
  (bye) ]

# Receive the initial auth in a child process from the client over a TCP socket
[de kv-child ()
  (kv-output "[child]=" *Pid " [parent]=" *PPid)
  (kv-mkfifo "child")                    # make a named pipe for the child

  (in *Sock                              # TCP Socket
    (if (kv-auth (rd))                   # try to authenticate
        (kv-listen-sock)                 # auth OK, listen for client messages
        (kv-out-sibling "error" "NOAUTH")# auth NOT OK, tell the sibling
        (kv-out-sock "AUTH" "NOAUTH") ]  # auth NOT OK, tell the client

# Timer to check if a BGSAVE should be made or not
[de kv-bgsave-timer ()
  (setq *Elapsed (- (time) *Start))      # how much time elapsed since timer started
  (ifn  (>= *Elapsed *KV_persist)        # is the timer expired?
        (abort (- *KV_persist *Elapsed)  # stop processing if N seconds elapsed
          (kv-listen-sibling) )          # listen for messages on the named pipe
        (setq *Start (time))             # restart the timer because it expired
        (kv-bgsave-db *KV_aof) ]                 # perform a BGSAVE

# Start the loop which listens for new messages
[de kv-sibling-loop ()
  (use (*Start *Elapsed)
    (setq *Start (time))                 # set a timer for the BGSAVE
    (loop                                # loop breaks when the result is NIL
      (if *KV_persist
          (kv-bgsave-timer)              # checker the timer then listen for messages
          (kv-listen-sibling) ]          # listen for messages on the named pipe

# Fork another child process known as the 'sibling' which stores all the data
[de kv-sibling ()
  (kv-mkfifo "sibling")                  # make a named pipe for the sibling
  (unless (fork)
          (kv-output "[sibling]=" *Pid)
          (finally
            (kv-sibling-exit)            # sibling exits
            (when *KV_persist
                  (kv-restore "DB" *KV_db)   # restore the DB from the database file
                  (kv-restore "AOF" *KV_aof) # replay the AOF log and load the data
                  (kv-save-db) )         # save the DB after loading AOF entries
            (kv-sibling-loop) ]          # start the sibling loop

# Cleanup child processes before exiting
[de kv-cleanup-kids ()
  (when (kids)
        (kv-output "[parent]=" *Pid " ending child processes: " (glue "," (kids)))
        (tell 'bye) )                    # tell all the child processes to exit
  (kv-output "[parent]=" *Pid " exiting") ]

# Launch a TCP listener and process some messages asynchronously
[de kv-listen ()
  (unless *KV_pass
    (setq *Bye
      '((msg "ERROR: *KV_pass not set, define it or use --pass <yourpass>")) )
    (bye 1) )

  (kv-output "Parent PID: " *Pid)

  (use (*Portsock *Sock *Pipe_sibling *Pipe_child)
    (setq *Portsock (port *KV_port))     # open a TCP port
    (finally
      (kv-cleanup-kids)
      (kv-sibling)                       # sibling process
      (loop                              # loop for new clients
        (setq *Sock (listen *Portsock))  # listen for TCP connections
        (NIL (fork) (close *Portsock))   # fork each new client TCP connection
        (close *Sock) )                  # close the socket when we're done

      (kv-child)                         # child process
      (kv-child-exit) ]                   # final cleanup before the child exits
