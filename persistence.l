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
    *KV_aof_lock  (pack "." *KV_aof ".lock")
    *KV_aof_tmp   (pack "." *KV_aof ".tmp")
    *KV_aof_old   (pack "." *KV_aof ".old")
    *KV_db_lock   (pack "." *KV_db ".lock")
    *KV_db_tmp    (pack "." *KV_db ".tmp")
    *KV_db_old    (pack "." *KV_db ".old") ]

(kv-tmpfile-set)

# INITIALIZE
(zero *KV_aof_lines)

# Every statistic must be zero'd or wiped first.
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
# Truncate the AOF by removing only the lines we replayed
[de kv-truncate-aof ()
  (and
    (gt0 *KV_aof_lines)
    (or (kv-output "====== Writing AOF ======") T)
    (call 'cp *KV_aof *KV_aof_old)
    (out *KV_aof_tmp
      (in *KV_aof
        (do *KV_aof_lines (line)) (echo) ) )                   # skip N lines from the AOF, echo the rest
    (call 'mv *KV_aof_tmp *KV_aof)
    (call 'rm "-f" *KV_aof_old)
    (or (kv-output "====== AOF saved ======") T) ]

# Write the new AOF to disk
[de kv-write-aof (Bg)
  (ctl *KV_aof_lock                                            # try to obtain an exclusive lock
    (one *KV/%stats%/aof_rewrite_in_progress)
    (if Bg
        (kv-truncate-aof)
        (out *KV_aof (rewind)) )                               # 'rewind' wipes the entire AOF log

    (zero *KV/%stats%/aof_rewrite_in_progress) ]

# Write the new DB to disk and return T if successful
[de kv-write-db ()
  (kv-stat "rdb_last_cow_size" (car (info *KV_db_tmp)))
  (and
    (if (info *KV_db)
        (call 'cp *KV_db *KV_db_old)
        T )
    (or (kv-output "====== Writing DB ======") T)
    (call 'mv *KV_db_tmp *KV_db) )
    (or (kv-output "====== DB saved ======") T)
    T ]

# Write data to the DB, then write the AOF (truncate or wipe)
[de kv-write-data (Bg)
  (when (and (info *KV_db_tmp) (gt0 (car @)) (kv-write-db))
        (kv-write-aof Bg) ]

# Write the data in binary PLIO (pr) or plaintext (println) format
[de kv-save-data (Key)
  (let Result (kv-cmd-get Key)
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
[de kv-timestamp ()
  (format (in (list 'date "+%s") (line T) ]

# Save the entire DB keyspace to a file
[de kv-save-db (Bg)
  (if (kv-locked?)
      @
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
      (setq *KV_aof_lines (lines Aof))                          # set how many lines are in the AOF
      (unless (fork) (kv-save-db T) (bye))
      (kv-stat "rdb_last_bgsave_status" "Background saving started") ]

# Restore the in-memory database from entries stored in the DB file
[de kv-restore-db (Filename)
  (kv-stat "loading" 1)
  (kv-stat "rdb_last_cow_size" (car (info Filename)))

  (in Filename
    (while (if *KV_binary (rd) (read))
      (let Result @
        (inc '*ERROR_LINE)
        (kv-cmd-set (car Result) (cadr Result)) ) ) )

  (kv-stat "loading" 0) ]

# Replay the append-only log file to re-load all the missing keys into the DB
[de kv-replay-aof (Filename)
  (kv-stat "aof_base_size" (if (info Filename) (car @) 0))
  (kv-stat "loading_aof" 1)

  (in Filename
    (while (read)
      (let Log @
        (if (= (car Log) (hash (cadr Log)))
            (and
              (inc '*ERROR_LINE)
              (kv-process *Pid (cadr Log)) )                   # replay the entry from the log
            (quit "Mismatched AOF entry, incorrect hash") ) ) ) )

  (kv-stat "loading_aof" 0) ]

# Check if there was a read error, return the error message, and stop the parent
[de kv-read-error (Type Filename)
  (when *Msg
        (out 2 (prinl "^J======^JERROR: " Type " error on line " *ERROR_LINE " of " Filename ": " *Msg "^J======^J"))
        (kill *PPid) ]

# Restore the DB or replay the AOF if its filesize is greater than 0 bytes
[de kv-restore (Type Filename)
  (use *ERROR_LINE
    (one *ERROR_LINE)
    (when (and (info Filename) (gt0 (car @)))
          (finally
            (kv-read-error Type Filename)
            (catch '("EOF Overrun" "Mismatched" "List expected")
              (case Type
                ("AOF"    (kv-replay-aof Filename))
                ("DB"     (kv-restore-db Filename)) ]

# Save a write command to the append-only log file with a hash of the data
[de kv-save-aof (Request Aof)
  (when (member (car Request) '("DEL" "LPOP" "LPOPRPUSH" "RPUSH" "SET"))
        (ctl *KV_aof_lock                                      # try to obtain an exclusive lock
          (out (pack "+" Aof) (println (list (hash Request) Request)))
          (kv-stat "aof_last_write_status" (if @ "OK" "FAILED") ]
