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
(load "module.l" "commands.l" "lolwut.l")

# STATS
# Process the message and send the result to the child over the named pipe
[de kv-sibling-job (Pid Msg)
  (let (Result (kv-process Pid Msg)      # here's the magic, process the message
        Pipe_child (pil "tmp/" *PPid "/pipe_child_" Pid) )

    (wait 1)
    (kv-output "[msg]   to client: " (sym Result))
    (inc '*KV/%stats%/total_net_output_bytes (bytes Result))

    (if Result
        (inc '*KV/%stats%/keyspace_hits)
        (inc '*KV/%stats%/keyspace_misses) )

    (out Pipe_child                      # named pipe of the child process
      (pr (cons "message" Result) ]

# Remove the child's process ID from the list of connected clients
[de kv-remove-client (Pid)
  (setq *KV/%stats%/connected_clients
    (filter '((N) (unless (= (car N) Pid) N))
            *KV/%stats%/connected_clients) )
  NIL ]                                  # NIL breaks from the (kv-parent) loop

# Increment some statistics counters for the INFO command when there's an error
[de kv-sibling-error (Pid Msg)
  (inc '*KV/%stats%/rejected_connections)
  (inc '*KV/%stats%/total_net_output_bytes (bytes Msg))
  (kv-remove-client Pid)                 # seriously, forget about the child
  NIL ]                                  # NIL breaks from the (kv-parent) loop

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
  (kv-output "[sibling]=" *Pid " exiting") ]

# Receive a message in the sibling, from the child, over a named pipe, then
# process the message and send the reply back to the child
[de kv-listen-sibling ()
  (in *Pipe_sibling                      # named pipe
    (when (rd)                           # expect one message from the child
          (let Msg @
            (kv-output "[msg] from child : (pid: " (cadr Msg) ") " (sym Msg))
            (kv-stats-update (cadr Msg) (caddr Msg))
            (kv-sibling-message          # process the child's message
              (car Msg)                  # should be the 'type' of message
              (cadr Msg)                 # should be the 'sender' of the message
              (caddr Msg) ]              # should be the actual message

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
    (= *KV_pass (caddr Auth))            # shared password
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
  (when *KV_verbose (prinl (rest) ]

# Perform some tasks when the child exits
[de kv-child-exit ()
  (kv-output "[child]=" *Pid " exiting")
  (kv-out-sibling "done")        # tell the sibling the child is done
  (when (info *Pipe_child)
        (call 'rm *Pipe_child) ) # remove the temporary named pipe
  (wait 1)                       # prevent the child from exiting fast
  (close *Sock)                  # close the socket when all is done
  (bye) ]                        # R.I.P.

# Receive the initial auth in a child process from the client over a TCP socket
[de kv-child ()
  (kv-output "[child]=" *Pid " [parent]=" *PPid)
  (kv-mkfifo "child")                    # make a named pipe for the child

  (in *Sock                              # TCP Socket
    (if (kv-auth (rd))                   # try to authenticate
        (kv-listen-sock)                 # auth OK, listen for client messages
        (kv-out-sibling "error" "NOAUTH")# auth NOT OK, tell the sibling
        (kv-out-sock "AUTH" "NOAUTH") ]  # auth NOT OK, tell the client

# Fork another child process known as the 'sibling' which stores all the data
[de kv-parent ()
  (when (= (length (kids)) 1)            # we only ever want 1 "sibling"
        (unless (fork)
          (kv-output "[sibling]=" *Pid)
          (finally
            (kv-sibling-exit)            # sibling exits
            (loop (kv-listen-sibling) ]  # loop breaks when the result is NIL

# Cleanup child processes before exiting
[de kv-cleanup-kids ()
  (when (kids)
        (kv-output "[parent]=" *Pid " ending child processes: " (kids))
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
    (setq *Portsock (port *KV_port))       # open a TCP port
    (finally
      (kv-cleanup-kids)
      (loop                                # loop for new clients
        (setq *Sock (listen *Portsock))    # listen for TCP connections
        (kv-mkfifo "sibling")              # make a named pipe for the sibling
        (if (fork)                         # fork each new client TCP connection
            (kv-parent)                    # parent process
            (kv-child)                     # child process
            (kv-child-exit) ]              # child exits
