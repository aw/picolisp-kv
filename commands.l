# picolisp-kv - https://github.com/aw/picolisp-kv
#
# Commands which mimic Redis: https://redis.io/commands
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

# MAIN
[de kv-process (Child Request)
  (let Key (when (cadr Request) (kv-name (cadr Request)))
    (case (uppc (car Request))
      ["BGSAVE"     (kv-bgsave-db *KV_aof) ]
      ["DEL"        (kv-cmd-del (cadr Request) (; Request 3) ]
      ["GET"        (kv-cmd-get (cadr Request) ]
      ["IDENT"      (kv-cmd-ident Child (cdr Request) ]
      ["INFO"       (kv-cmd-info (cadr Request) ]
      ["LINDEX"     (kv-cmd-lindex Key (; Request 3) ]
      ["LLEN"       (kv-cmd-llen Key) ]
      ["LOLWUT"     (kv-cmd-lolwut (cadr Request) ]
      ["LPOP"       (kv-cmd-lpop Key) ]
      ["LPOPRPUSH"  (kv-cmd-lpoprpush Key (; Request 3) ]
      ["RPUSH"      (kv-cmd-rpush (cadr Request) Key (; Request 3) ]
      ["SAVE"       (kv-save-db) ]
      ["SET"        (kv-cmd-set (cadr Request) (; Request 3) ]
      [T            "Error: Unknown command" ] ]

# COMMANDS
[de kv-cmd-flushall ()
  (mapcar '((N) (off (kv-name N))) Keys) ]

[de kv-cmd-del (Key Elements)
  (if (and Key (not (pre? "%stats%/" Key)))
      (length (wipe (extract '((N) (unless (pre? "%stats%/" N) (kv-name N))) (conc (list Key) Elements))))
      0 ]                                                      # return 0 if no key is specified

[de kv-cmd-ident (Child Elements)
  (when (and Child Elements (lst? Elements))                   # NIL if the IDENT isn't a list
        [push1 '*KV/%stats%/connected_clients                  # only add unique clients to the list
          (list Child (append Elements (list (cons "ip" *Adr) ]
        (pack "OK " (cdr (assoc "id" Elements) ]

[de kv-cmd-info (Section)
  (case (lowc Section)
    ["server"      (kv-info-format "Server" (kv-info-server) ]
    ["clients"     (kv-info-format "Clients" (kv-info-clients) ]
    ["memory"      (kv-info-format "Memory" (kv-info-memory) ]
    ["persistence" (kv-info-format "Persistence" (kv-info-persistence) ]
    ["stats"       (kv-info-format "Stats" (kv-info-stats) ]
    (T             (kv-info-default) ]

[de kv-cmd-lindex (Src Index)
  (when (and Src (num? Index))
        (cond
          ((= -1 Index)   (last (car Src)))
          ((lt0 Index)    (last (head (+ 1 Index) (car Src))))
          (T              (get (car Src) (+ 1 Index) ]

[de kv-cmd-llen (Key)
  (length (car Key) ]

[de kv-cmd-lpop (Src)
  (when (and Src (not (pre? "*KV/%stats%/" Src))) (pop Src) ]

[de kv-cmd-lpoprpush (Src Dst)
  (when (and Src Dst (not (pre? "*KV/%stats%/" Src)) (not (pre? "%stats%/" Dst)) (pop Src))
        (let Result @
          (kv-cmd-rpush Dst (kv-name Dst) (list Result))
          Result ]

[de kv-cmd-rpush (Key Dst Elements)
  (when (and Dst Elements (lst? Elements) (not (pre? "%stats%/" Key)))
        (push1 (kv-name "keys") Key)                           # keep a list of all the keys
        (mapc '((N) (queue Dst N)) Elements)
        (length (car Dst) ]

[de kv-cmd-set (Key Value)
  (when (and Key Value (not (pre? "%stats%/" Key)) (set (kv-name Key) Value))
        (push1 (kv-name "keys") Key)                           # keep a list of all the keys
        "OK" ]

[de kv-cmd-get (Key)
  (when Key (get (kv-value Key) ]

# COMMAND helpers
[de kv-name (Name)
  (car (str (pack "*KV/" Name) ]

[de kv-value (Name)
  (car (any (pack "*KV/" Name) ]

# INFO command helpers
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
    (cons "total_connections_received" (length *KV/%stats%/total_connections_received))
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
