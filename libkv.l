# picolisp-kv - https://github.com/aw/picolisp-kv
#
# Server library to be included in other PicoLisp tools
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

# CONSTANTS
(load "module.l")

(setq
  *KV_verbose NIL
  *KV_port  6378
  *KV_pass  NIL
  *KV_uuid  "7672FDB2-4D29-4F10-BA7C-8EAD0E29626E" # for client handshake, do not change
  *KV_startup_memory (* (heap) 1024 1024)
  *KV_persist   NIL
  *KV_binary    NIL
  *KV_aof       "kv.aof"
  *KV_db        "kv.db"
  *KV_aof_lock  (tmp "kv.aof.lock")
  *KV_aof_tmp   (tmp "kv.aof.tmp")
  *KV_db_lock   (tmp "kv.db.lock")
  *KV_db_tmp    (tmp "kv.db.tmp")
  *KV_write_commands '("APPEND" "DEL" "GETSET" "HDEL" "HSET" "LPOP" "LPOPRPUSH" "LPUSH" "LREM" "LSET" "MSET" "RPOP" "RPOPLPUSH" "RPUSH" "SET") )

# INITIALIZE
(off *KV/%stats%/connected_clients *KV/%stats%/rdb_last_bgsave_status)
(zero
  *KV/%stats%/total_connections_received
  *KV/%stats%/total_commands_processed
  *KV/%stats%/total_net_input_bytes
  *KV/%stats%/total_net_output_bytes
  *KV/%stats%/rejected_connections
  *KV/%stats%/keyspace_hits
  *KV/%stats%/keyspace_misses
  *KV/%stats%/last_client
  *KV/%stats%/loading
  *KV/%stats%/rdb_changes_since_last_save
  *KV/%stats%/rdb_bgsave_in_progress
  *KV/%stats%/rdb_last_save_time
  *KV/%stats%/rdb_last_cow_size
  *KV/%stats%/aof_rewrite_in_progress
  *KV/%stats%/aof_current_size
  *KV/%stats%/aof_base_size )

###
# COMMANDS
###

[de kv-process (Child Request)
  (let Key (when (caadr Request) (kv-name (caadr Request)))
    (case (uppc (car Request))
      ["APPEND"     (kv-cmd-append (caadr Request) (cdadr Request) ]
      ["BGSAVE"     (kv-bgsave-db *Aof_desc) ]
      ["CLIENT"     (kv-cmd-client Child (cadr Request) ]
      ["CONVERT"    (kv-cmd-convert) ]
      ["DEL"        (kv-cmd-del (caadr Request) (cdadr Request) ]
      ["EXISTS"     (kv-cmd-exists (caadr Request) (cdadr Request) ]
      ["GET"        (kv-cmd-get (caadr Request) ]
      ["GETSET"     (kv-cmd-getset (caadr Request) (cadadr Request) ]
      ["HDEL"       (kv-cmd-hdel (caadr Request) (cdadr Request) ]
      ["HEXISTS"    (kv-cmd-hexists (caadr Request) (cadadr Request) ]
      ["HGET"       (kv-cmd-hget (caadr Request) (cadadr Request) ]
      ["HGETALL"    (kv-cmd-hgetall (caadr Request) ]
      ["HKEYS"      (kv-cmd-hkeys (caadr Request) ]
      ["HLEN"       (kv-cmd-hlen (caadr Request) ]
      ["HMGET"      (kv-cmd-hmget (caadr Request) (cdadr Request) ]
      ["HSET"       (kv-cmd-hset (caadr Request) (cdadr Request) ]
      ["HVALS"      (kv-cmd-hvals (caadr Request) ]
      ["IDENT"      (kv-cmd-ident Child (cdr Request) ]
      ["INFO"       (kv-cmd-info (caadr Request) ]
      ["LINDEX"     (kv-cmd-lindex (caadr Request) (format (cadadr Request) ]
      ["LLEN"       (kv-cmd-llen Key) ]
      ["LPOP"       (kv-cmd-lpop (caadr Request) ]
      ["LPOPRPUSH"  (kv-cmd-lpoprpush (caadr Request) (cadadr Request) ]
      ["LPUSH"      (kv-cmd-lpush (caadr Request) Key (cdadr Request) ]
      ["LRANGE"     (kv-cmd-lrange (caadr Request) (format (cadadr Request)) (format (; (cadr Request) 3) ]
      ["LREM"       (kv-cmd-lrem (caadr Request) (format (cadadr Request)) (; (cadr Request) 3) ]
      ["LSET"       (kv-cmd-lset (caadr Request) (format (cadadr Request)) (; (cadr Request) 3) ]
      ["LTRIM"      (kv-cmd-ltrim (caadr Request) (format (cadadr Request)) (format (; (cadr Request) 3) ]
      ["MGET"       (kv-cmd-mget (cadr Request) ]
      ["MSET"       (kv-cmd-mset (cadr Request) ]
      ["PING"       (kv-cmd-ping (caadr Request) ]
      ["RPOP"       (kv-cmd-rpop (caadr Request) ]
      ["RPOPLPUSH"  (kv-cmd-rpoplpush (caadr Request) (cadadr Request) ]
      ["RPUSH"      (kv-cmd-rpush (caadr Request) Key (cdadr Request) ]
      ["SAVE"       (kv-save-db) ]
      ["SET"        (kv-cmd-set (caadr Request) (cadadr Request) ]
      ["STRLEN"     (kv-cmd-strlen (caadr Request) ]
      [T            "Error: Unknown command" ] ]

[de kv-cmd-flushall ()
  (mapcar '((N) (off (kv-name N))) Keys) ]

[de kv-cmd-append (Key Value)
  (when (and Key Value (str? (kv-value Key))  (not (pre? "%stats%/" Key)))
        (set (kv-name Key) (pack (kv-value Key) Value))
        (push1 (kv-name "%stats%/keys") Key)
        (length (kv-value Key) ]

[de kv-cmd-client (Child Cmd)
  (case (uppc (car Cmd))
    ("ID"   (kv-cmd-client-id Child))
    ("KILL" (kv-cmd-client-kill (; Cmd 2) (format (; Cmd 3))))
    ("LIST" (kv-cmd-client-list))
    (T      "Error: Unknown client command") ]

[de kv-cmd-client-id (Child)
  (cdr (assoc "id" (cadr (assoc Child (get (kv-value "%stats%/connected_clients") ]

[de kv-cmd-client-kill (Filter Arg)
  (case (uppc Filter)
    ["ID"  (length (make (mapcar '((N) (when (= Arg (cdr (assoc "id" (cadr N)))) (kv-remove-client (car N) T) (link T))) (get (kv-value "%stats%/connected_clients") ]
    (T      0) ]

[de kv-cmd-client-list ()
  (glue "^J" (mapcar '((N) (glue " " (mapcar '((S) (pack (car S) "=" (cdr S))) (cadr N)))) (get (kv-value "%stats%/connected_clients") ]

# convert a database to/from plaintext<->binary
[de kv-cmd-convert ()
  (setq *KV_binary (onOff *KV_binary))
  (setq *KV_db (pack (dirname *KV_db) (glue "." (append (head -1 (split (chop *KV_db) ".")) (if *KV_binary '(("b" "i" "n")) '(("d" "b")))))))
  (kv-save-db) ]

[de kv-cmd-del (Key Elements)
  (if (and Key (not (pre? "%stats%/" Key)))
      (length (wipe (extract '((N) (unless (pre? "%stats%/" N) (kv-name N))) (conc (list Key) Elements))))
      0 ]                                                      # return 0 if no key is specified

[de kv-cmd-exists (Key Elements)
  (if Key
      (cnt '((N) (kv-value N)) (conc (list Key) Elements))
      0 ]                                                      # return 0 if no key is specified

[de kv-cmd-get (Key)
  (kv-value Key) ]

[de kv-cmd-getset (Key Value)
  (swap (kv-name Key) Value) ]

[de kv-cmd-hdel (Key Elements)
  (when (and Key Elements (lst? (kv-value Key)) (lst? Elements) (not (pre? "%stats%/" Key)))
        (length
          (extract '((N)
                   (when (assoc N (kv-value Key)) (set (kv-name Key) (delete @ (kv-value Key))) T) )
                    Elements ]

[de kv-cmd-hexists (Key Field)
  (if (assoc Field (kv-value Key))
      1
      0 ]

[de kv-cmd-hget (Key Field)
  (cdr (assoc Field (kv-value Key) ]

[de kv-cmd-hgetall (Key)
  (when (and Key (lst? (kv-value Key)) (not (pre? "%stats%/" Key)))
        (extract '((N) (when (lst? N) N)) (kv-value Key) ]

[de kv-cmd-hkeys (Key)
  (when (and Key (lst? (kv-value Key)) (not (pre? "%stats%/" Key)))
        (extract '((N) (when (lst? N) (car N))) (kv-value Key) ]

[de kv-cmd-hlen (Key)
  (when (and Key (lst? (kv-value Key)) (not (pre? "%stats%/" Key)))
        (length (kv-value Key) ]

[de kv-cmd-hmget (Key Elements)
  (mapcar '((N) (kv-cmd-hget Key N)) Elements) ]

[de kv-cmd-hset (Key Elements)
  (use *Num
    (zero *Num)
    (when (and Key Elements (lst? (kv-value Key)) (lst? Elements) (not (pre? "%stats%/" Key)))
          (while (cut 2 'Elements)
            (let Str @
              (when (cadr Str)
                    (inc '*Num)
                    (if (assoc (car Str) (kv-value Key))
                        (kv-cmd-set Key (replace (kv-value Key) @ (cons (car Str) (cadr Str))))
                        (kv-cmd-set Key (append (kv-value Key) (list (cons (car Str) (cadr Str))))) ) ) ) )
          *Num ]

[de kv-cmd-hvals (Key)
  (when (and Key (lst? (kv-value Key)) (not (pre? "%stats%/" Key)))
        (extract '((N) (when (lst? N) (cdr N))) (kv-value Key) ]

[de kv-cmd-ident (Child Elements)
  (when (and Child Elements (lst? Elements))                   # NIL if the IDENT isn't a list
        [push1 '*KV/%stats%/connected_clients                  # only add unique clients to the list
          (list Child (append (list (cons "id" (inc '*KV/%stats%/last_client)) (cons "pid" Child)) Elements) ]
        (inc '*KV/%stats%/total_connections_received)
        (pack "OK " (cdr (assoc "name" Elements) ]

[de kv-cmd-info (Section)
  (case (lowc Section)
    ["server"      (kv-info-format "Server" (kv-info-server) ]
    ["clients"     (kv-info-format "Clients" (kv-info-clients) ]
    ["memory"      (kv-info-format "Memory" (kv-info-memory) ]
    ["persistence" (kv-info-format "Persistence" (kv-info-persistence) ]
    ["stats"       (kv-info-format "Stats" (kv-info-stats) ]
    (T             (kv-info-default) ]

[de kv-cmd-lindex (Key Index)
  (let Src (kv-name Key)
    (when (and Src (lst? (kv-value Key)) (num? Index))
          (cond
            ((= -1 Index)   (last (car Src)))
            ((lt0 Index)    (last (head (+ 1 Index) (car Src))))
            (T              (get (car Src) (+ 1 Index) ]

[de kv-cmd-llen (Key)
  (length (car Key) ]

[de kv-cmd-lpop (Key)
  (let Src (kv-name Key)
    (when (and Src (lst? (kv-value Key)) (not (pre? "*KV/%stats%/" Src))) (pop Src) ]

[de kv-cmd-lpoprpush (Src Dst)
  (when (and Src Dst (not (pre? "*KV/%stats%/" Src)) (not (pre? "%stats%/" Dst)) (kv-cmd-lpop Src))
        (let Result @
          (kv-cmd-rpush Dst (kv-name Dst) (list Result))
          Result ]

[de kv-cmd-lpush (Key Dst Elements)
  (when (and Dst Elements (lst? (kv-value Key)) (lst? Elements) (not (pre? "%stats%/" Key)))
        (kv-cmd-set Key (append (reverse Elements) (kv-value Key)))
        (length (car Dst) ]

[de kv-cmd-lrange (Key Start Stop)
  (let Src (kv-name Key)
    (when (and Src Start Stop (ge0 Start) (ge0 Stop) (lst? (kv-value Key)) (not (pre? "*KV/%stats%/" Src)))
          (head (+ 1 (- Stop Start)) (nth (kv-value Key) (+ 1 Start) ]

[de kv-cmd-lrem (Key Count Element)
  (let Src (kv-name Key)
    (if (and Src Count Element (ge0 Count) (lst? (kv-value Key)) (not (pre? "*KV/%stats%/" Src)))
        (let Len (length (kv-value Key))
          (cond
            ((= 0 Count)  (del Element Src T))
            (T            (do Count (del Element Src))) )
          (- Len (length (kv-value Key))) )
        0 ]

[de kv-cmd-lset (Key Index Element)
  (let Src (kv-name Key)
    (when (and Src (lst? (kv-value Key)) (ge0 Index) (< Index (length (kv-value Key)))  (not (pre? "*KV/%stats%/" Src)))
          (kv-cmd-set Key (place (+ 1 Index) (kv-value Key) Element) ]

[de kv-cmd-ltrim (Key Start Stop)
  (let Src (kv-name Key)
    (when (and Src Start Stop (ge0 Start) (ge0 Stop) (lst? (kv-value Key)) (not (pre? "*KV/%stats%/" Src)))
          (kv-cmd-set Key (head (+ 1 (- Stop Start)) (nth (kv-value Key) (+ 1 Start) ]

[de kv-cmd-mget (Elements)
  (mapcar kv-cmd-get Elements) ]

[de kv-cmd-mset (Elements)
  (when (and Elements (lst? Elements) (not (pre? "%stats%/" Key)))
        (while (cut 2 'Elements)
          (let Str @
            (kv-cmd-set (car Str) (cadr Str)) ) )
        "OK" ]

[de kv-cmd-rpoplpush (Src Dst)
  (when (and Src Dst (not (pre? "*KV/%stats%/" Src)) (not (pre? "%stats%/" Dst)) (kv-cmd-rpop Src))
        (let Result @
          (kv-cmd-lpush Dst (kv-name Dst) (list Result))
          Result ]

[de kv-cmd-ping (Msg)
  (if Msg @ "PONG") ]

[de kv-cmd-rpop (Key)
  (let Src (kv-name Key)
    (when (and Src (lst? (kv-value Key)) (not (pre? "*KV/%stats%/" Src))) (rot (kv-value Key)) (pop Src) ]

[de kv-cmd-rpush (Key Dst Elements)
  (when (and Dst Elements (lst? (kv-value Key)) (lst? Elements) (not (pre? "%stats%/" Key)))
        (kv-cmd-set Key (append (kv-value Key) Elements))
        (length (car Dst) ]

[de kv-cmd-set (Key Value)
  (when (and Key Value (not (pre? "%stats%/" Key)) (set (kv-name Key) Value))
        (push1 (kv-name "%stats%/keys") Key)                   # keep a list of all the keys
        "OK" ]

[de kv-cmd-strlen (Key)
  (length (kv-value Key) ]

[de kv-name (Name)
  (any (pack "*KV/" Name) ]

[de kv-value (Name)
  (car (any (pack "*KV/" Name) ]

###
# INFO
###

[de kv-info-format (Title Info)
  (pack "^J# " Title "^J"
    (mapcar '((S) (pack (car S) ":" (cdr S) "^J")) (clip Info) ]

[de kv-info-server ()
  (list
    (cons "app_version" (cadr (assoc "version" APP_INFO)))
    (cons "os" (in (list 'uname "-srm") (line T)))
    (cons "arch_bits" (if *CPU 64 32))
    (cons "process_id" *Pid)
    (cons "tcp_port" *KV_port)
    (cons "uptime_in_seconds" (/ (usec) 1000000))
    (cons "uptime_in_days" (/ (usec) 1000000 60 60 24))
    (cons "executable" (cmd)) ]

[de kv-info-clients ()
  (list
    (cons "connected_clients" (length *KV/%stats%/connected_clients)) ]

[de kv-info-memory-split ()
  (car (split (clip (in "/proc/meminfo" (from "MemTotal:") (till "^J"))) " ")) ]

[de kv-info-memory ()
  (make
    (link
      (cons "total_keys" (length *KV/%stats%/keys))
      (cons "used_memory" (* (heap) 1024 1024))
      (cons "used_memory_human" (pack (heap) "M"))
      (cons "used_memory_startup" *KV_startup_memory) )
    (when (= *OS "Linux")
          (let Total_memory (* (format (kv-info-memory-split)) 1024 1024)
            (link
              (cons "total_system_memory" Total_memory)
              (cons "total_system_memory_human" (/ Total_memory 1024 1024 1024) "M") ]

[de kv-info-persistence ()
  (list
    (cons "db_format" (if *KV_binary "binary" "plaintext"))
    (cons "loading" *KV/%stats%/loading)
    (cons "rdb_changes_since_last_save" (if (info *KV_aof) (lines *KV_aof) 0))
    (cons "rdb_bgsave_in_progress" (if (info *KV_db_lock) 1 0))
    (cons "rdb_last_save_time" *KV/%stats%/rdb_last_save_time)
    (cons "rdb_last_bgsave_status" *KV/%stats%/rdb_last_bgsave_status)
    (cons "rdb_last_cow_size" *KV/%stats%/rdb_last_cow_size)
    (cons "aof_enabled" (if *KV_persist 1 0))
    (cons "aof_rewrite_in_progress" *KV/%stats%/aof_rewrite_in_progress)
    (cons "aof_last_write_status" *KV/%stats%/aof_last_write_status)
    (cons "aof_current_size" (if (info *KV_aof) (car @) 0))
    (cons "aof_base_size" *KV/%stats%/aof_base_size)
  ]

[de kv-info-stats ()
  (list
    (cons "total_connections_received" *KV/%stats%/total_connections_received)
    (cons "total_commands_processed" *KV/%stats%/total_commands_processed)
    (cons "total_net_input_bytes" *KV/%stats%/total_net_input_bytes)
    (cons "total_net_output_bytes" *KV/%stats%/total_net_output_bytes)
    (cons "rejected_connections" *KV/%stats%/rejected_connections)
    (cons "keyspace_hits" *KV/%stats%/keyspace_hits)
    (cons "keyspace_misses" *KV/%stats%/keyspace_misses) ]

[de kv-info-default ()
  (pack
    (kv-info-format "Server"      (kv-info-server))
    (kv-info-format "Clients"     (kv-info-clients))
    (kv-info-format "Memory"      (kv-info-memory))
    (kv-info-format "Persistence" (kv-info-persistence))
    (kv-info-format "Stats"       (kv-info-stats)) ]

###
# PERSISTENCE
###

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
        (call 'cp *KV_db (pack *KV_db ".old"))
        T )
    (or (kv-output "====== Writing DB ======") T)
    (call 'mv *KV_db_tmp *KV_db) )
    (or (kv-output "====== DB saved ======") T) ]

# Write data to the DB, then write the AOF (truncate or wipe)
[de kv-write-data (Bg)
  (and (info *KV_db_tmp) (kv-write-db) (kv-remove-aof Bg) ]

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
    (mapcar kv-save-data (kv-cmd-get "%stats%/keys") ]

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

  # TODO: currently allocating 5x more than DB filesize, must validate
  (gc (+ 1 (* 5 (/ (kv-value "%stats%/rdb_last_cow_size") 1024 1024)))) # pre-allocate enough memory for the entire DB

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
        (if (= (cadr Log) (kv-hash (caddr Log)))
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
  (when (member (car Request) *KV_write_commands)
        (ctl *KV_aof_lock                                      # try to obtain an exclusive lock
          (out Aof (println (list (kv-timestamp T) (kv-hash Request) Request)))
          (kv-stat "aof_last_write_status" (if @ "OK" "FAILED") ]

###
# CHILD
###

# Perform some tasks when the child exits
[de kv-child-exit ()
  (kv-output "[child]=" *Pid " exiting")
  (kv-out-sibling "done")
  (when (info *Pipe_child) (call 'rm "-f" *Pipe_child)) ]

# Receive a message from a sibling over a named pipe and send it to the client
[de kv-listen-child ()
  (in *Pipe_child
    (when (rd) (out *Sock (pr @) ]                             # pipe the message as-is to the client

# Send a message to the sibling over a named pipe
[de kv-out-sibling (Type . @)
  (wait 1)                                                     # required or messages get lost
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
    (kv-out-client "auth" (kv-hash (pack (cadr Auth) *KV_uuid)))
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
        (kv-out-client "error" "NOAUTH") ]                     # auth NOT OK, tell the client

###
# SIBLING
###

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
[de kv-remove-client (Pid Kill)
  (when Kill (kill Pid))
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
    ("error"    (kv-sibling-error Pid Msg))
    ("done"     (kv-remove-client Pid))
    ("message"  (kv-sibling-job Pid Msg) ]

# Increment some statistics counters for the INFO command
[de kv-stats-update (Msg)
  (inc '*KV/%stats%/total_commands_processed)
  (inc '*KV/%stats%/total_net_input_bytes (bytes Msg) ]

# Receive a message in the sibling, from the child, over a named pipe, then
# process the message and send the reply back to the child
[de kv-listen-sibling ()
  [in *Pipe_sibling
    (when (rd)
          (let Msg @
            (kv-stats-update (caddr Msg))
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

###
# MAIN
###

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
        (kv-child)
        (bye) ]
