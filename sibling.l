# Process the message and send the result to the child over the named pipe
[de kv-sibling-job (Pid Msg)
  (when *KV_persist (kv-save-aof Msg *Aof_desc))               # save the request to a log file first

  (let (Result (kv-process Pid Msg)
        Pipe_child (pil "tmp/" *PPid "/pipe_child_" Pid) )

    (wait 1)
    (kv-output "[msg]    to child: " (sym Result))
    (inc '*KV/%stats%/total_net_output_bytes (bytes Result))

    (if Result
        (inc '*KV/%stats%/keyspace_hits)
        (inc '*KV/%stats%/keyspace_misses) )

    (out Pipe_child (pr (cons "message" Result) ]

# Remove the child's process ID from the list of connected clients
[de kv-remove-client (Pid)
  (kv-stat "connected_clients" (filter '((N) (unless (= (car N) Pid) N)) *KV/%stats%/connected_clients))
  NIL ]                                                        # NIL breaks from (kv-sibling-loop)

# Increment some statistics counters for the INFO command when there's an error
[de kv-sibling-error (Pid Msg)
  (inc '*KV/%stats%/rejected_connections)
  (inc '*KV/%stats%/total_net_output_bytes (bytes Msg))
  (kv-remove-client Pid)
  NIL ]                                                        # NIL breaks from (kv-sibling-loop)

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
        (kv-bgsave-db *Aof_desc) ]

# Start the loop which listens for new messages
[de kv-sibling-loop ()
  (use (*Aof_desc *Start *Elapsed)
    (setq *Aof_desc (open *KV_aof))                            # obtain a file descriptor for the AOF
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
        (call 'rm "-f" *KV_aof_lock *KV_db_lock) )
  (kill *PPid) ]

# Fork another child process known as the 'sibling' which stores all the data
[de kv-sibling ()
  (kv-mkfifo "sibling")
  (unless (fork)
          (kv-output "[sibling]=" *Pid " started")
          (finally
            (kv-sibling-exit)
            (kv-sibling-restore)
            (kv-sibling-loop) ]
