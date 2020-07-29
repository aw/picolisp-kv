# picolisp-kv - https://github.com/aw/picolisp-kv
#
# Persistence similar to Redis AOF/Snapshot: https://redis.io/topics/persistence
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

# CONSTANTS
(setq
  *KV_persist   NIL
  *KV_binary    NIL
  *KV_aof       "kv.aof"
  *KV_db        "kv.db" )

[de kv-tmpfile-set ()
  (setq
    *KV_aof_lock  (pack (dirname *KV_aof) "." (basename *KV_aof) ".lock")
    *KV_aof_tmp   (pack (dirname *KV_aof) "." (basename *KV_aof) ".tmp")
    *KV_db_lock   (pack (dirname *KV_db) "." (basename *KV_db) ".lock")
    *KV_db_tmp    (pack (dirname *KV_db) "." (basename *KV_db) ".tmp") ]

(kv-tmpfile-set)

# INITIALIZE
(off
  *KV/%stats%/rdb_last_bgsave_status )
(zero
  *KV/%stats%/loading
  *KV/%stats%/rdb_changes_since_last_save
  *KV/%stats%/rdb_bgsave_in_progress
  *KV/%stats%/rdb_last_save_time
  *KV/%stats%/rdb_last_cow_size
  *KV/%stats%/aof_rewrite_in_progress
  *KV/%stats%/aof_current_size
  *KV/%stats%/aof_base_size )

# PERSISTENCE
# Rewrite the AOF with new entries if they were added
[de kv-rewrite-aof ()
  (ctl *KV_aof_lock
    (one *KV/%stats%/aof_rewrite_in_progress)
    (when (info *KV_aof_tmp)
          (kv-output "====== Rewriting AOF ======")
          (out (pack "+" *KV_aof_tmp) (in *KV_aof (echo)))  # Append the current AOF into the temporary AOF
          (out *KV_aof (in *KV_aof_tmp (echo)))             # Copy the temporary AOF into the current AOF
          (call 'rm "-f" *KV_aof_tmp)
          (kv-output "====== AOF saved ======") )
    (zero *KV/%stats%/aof_rewrite_in_progress) ]

[de kv-remove-aof (Bg)
  (unless Bg (out *KV_aof (rewind)))
  (call 'rm "-f" *KV_aof_tmp) ]

# Write the new DB to disk
[de kv-write-db ()
  (kv-stat "rdb_last_cow_size" (car (info *KV_db_tmp)))
  (and
    (if (info *KV_db)
        (call 'cp *KV_db (pack (dirname *KV_db) "." (basename *KV_db) ".old"))
        T )
    (or (kv-output "====== Writing DB ======") T)
    (call 'mv *KV_db_tmp *KV_db) )
    (or (kv-output "====== DB saved ======") T) ]

# Write data to the DB, then write the AOF (truncate or wipe)
[de kv-write-data (Bg)
  (and (info *KV_db_tmp) (gt0 (car @)) (kv-write-db) (kv-remove-aof Bg) ]

# Write the data in binary PLIO (pr) or plaintext (println) format
[de kv-save-data (Key)
  (let Result (kv-value Key)
    (when Result
          (if *KV_binary
              (pr (list Key Result))
              (println (list Key Result)) ]

# Write all the known keys to a temporary DB file
[de kv-save-db-keys ()
  (out *KV_db_tmp
    (mapcar kv-save-data (kv-cmd-get "keys") ]

# Perform some maintenance tasks when save ends
[de kv-save-cleanup ()
  (call 'rm "-f" *KV_aof_lock *KV_db_lock) ]

# Obtain a UNIX timestamp
[de kv-timestamp (Ns)
  (in (list 'date (if Ns "+%s.%N" "+%s")) (line T) ]

# Save the entire DB keyspace to a file
[de kv-save-db (Bg)
  (if (kv-locked?)
      (kv-rewrite-aof)                                         # restore the AOF if the DB is locked
      (out *KV_db_lock (prinl *Pid))
      (kv-output "[dbwriter]=" *Pid " Saving the DB to " *KV_db)
      (kv-stat "rdb_last_save_time" (kv-timestamp))

      (finally
        (kv-save-cleanup)
        (kv-save-db-keys)
        (kv-write-data Bg)
        (unless *PPid (bye))

        (kv-stat "rdb_last_bgsave_status" "OK") ]

# Check if the DB is locked for writing, and return the error message
[de kv-locked? ()
  (when (info *KV_db_lock)
        (out 2 (prinl "^J======^JDB is locked for writing by Pid " (in *KV_db_lock (line T)) ", not saving^J======^J"))
        (kv-stat "rdb_last_bgsave_status" "Error: DB is locked for writing") ]

# Save the entire DB keyspace to a file in the background (fork)
[de kv-bgsave-db (Aof)
  (if (kv-locked?)
      @
      (kv-stat "rdb_last_save_time" (kv-timestamp))
      (call 'cp *KV_aof *KV_aof_tmp)                           # make a copy of the AOF before we dump the DB to disk
      (out Aof (rewind))                                       # wipe the contents of the AOF
      (unless (fork) (kv-save-db T) (bye))
      (kv-stat "rdb_last_bgsave_status" "Background saving started") ]

# Restore the in-memory database from entries stored in the DB file
[de kv-restore-db (Filename)
  (kv-stat "loading" 1)
  (kv-stat "rdb_last_cow_size" (car (info Filename)))

  (in Filename
    (while (if *KV_binary (rd) (read))
      (inc '*ERROR_LINE)
      (let Result @
        (kv-cmd-set (car Result) (cadr Result)) ) ) )

  (kv-stat "loading" 0) ]

# Replay the append-only log file to re-load all the missing keys into the DB
[de kv-replay-aof (Filename)
  (kv-stat "aof_base_size" (car (info Filename)))
  (kv-stat "loading_aof" 1)

  (in Filename
    (while (read)
      (inc '*ERROR_LINE)
      (let Log @
        (if (= (cadr Log) (hash (caddr Log)))
            (kv-process *Pid (caddr Log))                      # replay the entry from the log
            (quit "Mismatched AOF entry, incorrect hash") ) ) ) )

  (kv-stat "loading_aof" 0) ]

# Check if there was a read error, return the error message, and stop the parent
[de kv-read-error (Type Filename)
  (when *Msg
        (out 2 (prinl "^J======^JERROR: " Type " error on line " *ERROR_LINE " of " Filename ": " *Msg "^J======^J"))
        (kill *PPid)
        (bye 1) ]

# Restore the DB or replay the AOF if its filesize is greater than 0 bytes
[de kv-restore (Type Filename)
  (use *ERROR_LINE
    (zero *ERROR_LINE)
    (when (and (info Filename) (gt0 (car @)))
          (catch '("EOF Overrun" "Mismatched" "List expected" "Bad input")
            (finally
              (kv-read-error Type Filename)
              (if (= "AOF" Type)
                  (kv-replay-aof Filename)
                  (kv-restore-db Filename) ]

# Save a write command to the append-only log file with a timestamp and hash of the data
[de kv-save-aof (Request Aof) # Aof is a file descriptor
  (when (member (car Request) '("DEL" "GETSET" "LPOP" "LPOPRPUSH" "RPUSH" "SET"))
        (ctl *KV_aof_lock                                      # try to obtain an exclusive lock
          (out Aof (println (list (kv-timestamp T) (hash Request) Request)))
          (kv-stat "aof_last_write_status" (if @ "OK" "FAILED") ]
