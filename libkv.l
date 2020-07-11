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
  *KV_uuid  "7672FDB2-4D29-4F10-BA7C-8EAD0E29626E" # for client handshake, do not change
  *KV_startup_memory (* (heap) 1024 1024) )

# INITIALIZE
# Every statistic must be zero'd or wiped first.
(off *KV/%stats%/connected_clients)
(zero
  *KV/%stats%/total_connections_received
  *KV/%stats%/total_commands_processed
  *KV/%stats%/total_net_input_bytes
  *KV/%stats%/total_net_output_bytes
  *KV/%stats%/rejected_connections
  *KV/%stats%/keyspace_hits
  *KV/%stats%/keyspace_misses
  *KV/%stats%/last_client )

# LOAD
(load "module.l" "commands.l" "lolwut.l" "persistence.l")

# IPC
# Perform some tasks when the child exits
[de kv-child-exit ()
  (kv-output "[child]=" *Pid " exiting")
  (kv-out-sibling "done")
  (when (info *Pipe_child) (call 'rm *Pipe_child)) ]

# Receive a message from a sibling over a named pipe and send it to the client
[de kv-listen-child ()
  (in *Pipe_child
    (when (rd) (kv-out-client "message" (cdr @) ]

# Send a message to the sibling over a named pipe
[de kv-out-sibling (Type . @)
  (out *Pipe_sibling
    (pr (list Type *Pid (car (rest) ]

# Receive a message from the client over the TCP socket
[de kv-listen-sock ()
  (in *Sock
    (while (rd)
      (let Msg @
        (kv-output "[msg] from client: (pid: " *Pid ") " *Adr " " (sym Msg))
        (kv-out-sibling "message" Msg)
        (kv-listen-child) ]

# Send a message to the client over a TCP socket
[de kv-out-client (Type Msg)
  (out *Sock (pr (cons Type Msg) ]

# non cryptographically secure hash, can be changed in the future
[de kv-hash (String)
  (hash String) ]

# Authenticate the client via handshake, and authorizate with a hashed password
[de kv-auth (Auth)
  (and
    (lst? Auth)
    (= "AUTH" (car Auth))
    (= (kv-hash *KV_pass) (caddr Auth))
    (kv-out-client "AUTH" (kv-hash (pack (cadr Auth) *KV_uuid)))
    (kv-out-sibling "message" (list "IDENT" (cons "name" (cadr Auth)) (cons "addr" *Adr) (cons "fd" *Sock)))
    (kv-listen-child) ]

# Receive the initial auth in a child process from the client over a TCP socket
[de kv-child ()
  (kv-output "[child]=" *Pid " [parent]=" *PPid)
  (kv-mkfifo "child")

  (in *Sock
    (if (kv-auth (rd))
        (kv-listen-sock)
        (kv-out-sibling "error" "NOAUTH")                      # auth NOT OK, tell the sibling
        (kv-out-client "AUTH" "NOAUTH") ]                      # auth NOT OK, tell the client

# Loop on a TCP socket listening for client connections
[de kv-listen-loop ()
  (loop
    (setq *Sock (listen *Portsock))
    (NIL (fork) (close *Portsock))
    (close *Sock) ]

# Process the message and send the result to the child over the named pipe
[de kv-sibling-job (Pid Msg)
  (let (Result (kv-process Pid Msg)
        Pipe_child (pil "tmp/" *PPid "/pipe_child_" Pid) )

    (wait 1)
    (kv-output "[msg]   to client: " (sym Result))
    (inc '*KV/%stats%/total_net_output_bytes (bytes Result))

    (ifn  Result
          (inc '*KV/%stats%/keyspace_misses)
          (inc '*KV/%stats%/keyspace_hits)
          (when *KV_persist (kv-save-aof Msg *KV_aof)) )       # save the request to a log file

    (out Pipe_child (pr (cons "message" Result) ]

# Set the value of a statistic
[de kv-stat (Key Value)
  (set (any (pack "*KV/%stats%/" Key)) Value) ]

# Remove the child's process ID from the list of connected clients
[de kv-remove-client (Pid)
  (kill Pid)
  (kv-stat "connected_clients" (filter '((N) (unless (= (car N) Pid) N)) *KV/%stats%/connected_clients))
  NIL ]                                  # NIL breaks from (kv-sibling-loop)

# Increment some statistics counters for the INFO command when there's an error
[de kv-sibling-error (Pid Msg)
  (inc '*KV/%stats%/rejected_connections)
  (inc '*KV/%stats%/total_net_output_bytes (bytes Msg))
  (kv-remove-client Pid)
  NIL ]                                  # NIL breaks from (kv-sibling-loop)

# Process the message depending on its type
[de kv-sibling-message (Type Pid Msg)
  (case Type
    ("error" (kv-sibling-error Pid Msg))
    ("done"  (kv-remove-client Pid))
    ("message" (kv-sibling-job Pid Msg) ]

# Increment some statistics counters for the INFO command
[de kv-stats-update (Pid Msg)
  (inc '*KV/%stats%/total_commands_processed)
  (inc '*KV/%stats%/total_net_input_bytes (bytes Msg))
  (push1 '*KV/%stats%/total_connections_received Pid) ]

# Receive a message in the sibling, from the child, over a named pipe, then
# process the message and send the reply back to the child
[de kv-listen-sibling ()
  [in *Pipe_sibling
    (when (rd)
          (let Msg @
            (kv-stats-update (cadr Msg) (caddr Msg))
            (kv-sibling-message
              (car Msg)                                        # should be the 'type' of message
              (cadr Msg)                                       # should be the sender's Pid
              (caddr Msg) ]                                    # should be the actual message
  T ]

# Timer to make a BGSAVE if necessary
[de kv-bgsave-timer ()
  (setq *Elapsed (- (time) *Start))                            # how much time elapsed since timer started
  (ifn  (>= *Elapsed *KV_persist)
        (abort (- *KV_persist *Elapsed) (kv-listen-sibling))
        (setq *Start (time))                                   # restart the timer because it expired
        (kv-bgsave-db *KV_aof) ]

# Start the loop which listens for new messages
[de kv-sibling-loop ()
  (use (*Start *Elapsed)
    (setq *Start (time))                                       # start the clock for the bgsave timer
    (loop
      (if *KV_persist
          (kv-bgsave-timer)
          (kv-listen-sibling) ]

# Restore the DB and AOF, then save it in the foreground (blocking)
[de kv-sibling-restore ()
  (when *KV_persist
        (kv-restore "DB" *KV_db)
        (kv-restore "AOF" *KV_aof)
        (kv-save-db) ]

# Remove a locked process with SIGKILL
[de kv-remove-locked ()
  (when (info *KV_db_lock) (kill (in *KV_db_lock (format (line T))) 9) ]

# Perform some tasks when the sibling exits, such as removing locks on the DB and AOF
[de kv-sibling-exit ()
  (kv-output "[sibling]=" *Pid " exiting")
  (when *KV_persist
        (kv-remove-locked)
        (call 'rm "-f" *KV_aof_lock *KV_db_lock)
        (unless *Msg (kv-save-db) ]

# Create named pipes in the tmp directory of the parent process
[de kv-mkfifo (Type)
  (let Filename
    (if (= Type "child")
        (setq *Pipe_child (pil "tmp/" *PPid "/pipe_child_" *Pid))
        (setq *Pipe_sibling (tmp "pipe_sibling")) )

    (unless (info Filename) (call "mkfifo" Filename) ]

# Fork another child process known as the 'sibling' which stores all the data
[de kv-sibling ()
  (kv-mkfifo "sibling")
  (unless (fork)
          (kv-output "[sibling]=" *Pid)
          (finally
            (kv-sibling-exit)
            (kv-sibling-restore)
            (kv-sibling-loop) ]

# Cleanup child processes before exiting
[de kv-cleanup-kids ()
  (when (kids)
        (kv-output "[parent]=" *Pid " ending child processes: " (glue "," (kids)))
        (tell 'bye) )
  (kv-output "[parent]=" *Pid " exiting") ]

# Send some output to the console
[de kv-output @
  (when *KV_verbose (prinl "[" (dat$ (date) "-") "T" (tim$ (time) T) "] " (rest) ]

# START
# Launch a TCP listener and process some messages asynchronously
[de kv-listen ()
  (unless *KV_pass
    (setq *Bye
      '((msg "ERROR: *KV_pass not set, define it or use --pass <yourpass>")) )
    (bye 1) )

  (kv-output "Parent PID: " *Pid)

  (use (*Portsock *Sock *Pipe_sibling *Pipe_child)
    (setq *Portsock (port *KV_port))
    (finally
      (kv-cleanup-kids)
      (kv-sibling)
      (kv-listen-loop)
      (finally
        (kv-child-exit)
        (kv-child) ]
