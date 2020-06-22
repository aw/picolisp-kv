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
(load "module.l" "commands.l" "persistence.l")

# IPC
(load "child.l")
(load "sibling.l")

# Set the value of a statistic
[de kv-stat (Key Value)
  (set (any (pack "*KV/%stats%/" Key)) Value) ]

# Create named pipes in the tmp directory of the parent process
[de kv-mkfifo (Type)
  (let Filename
    (if (= Type "child")
        (setq *Pipe_child (pil "tmp/" *PPid "/pipe_child_" *Pid))
        (setq *Pipe_sibling (tmp "pipe_sibling")) )

    (unless (info Filename) (call "mkfifo" Filename) ]

# Loop on a TCP socket listening for client connections
[de kv-listen-loop ()
  (loop
    (setq *Sock (listen *Portsock))
    (NIL (fork) (close *Portsock))
    (close *Sock) ]

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
