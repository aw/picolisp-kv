# Key/Value tests

[de test-commands-append ()
  (kv-cmd-rpush "appendlist" '("one" "two"))
  (assert-nil (kv-cmd-append) "[APPEND] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-append "testkey") "[APPEND] Should return NIL if no value is provided")
  (assert-nil (kv-cmd-append "appendlist" "test") "[APPEND] Should return NIL if the key is not a string")
  (kv-cmd-set "appendkey" "hello")
  (assert-equal 10 (kv-cmd-append "appendkey" "world") "[APPEND] Should append a key and return its length")
  (assert-equal "helloworld" (kv-cmd-get "appendkey") "[GET] Should return the value of the key")
  ]

[de test-commands-client ()
  (kv-cmd-ident 12345 (list (cons "name" "abc")))
  (assert-kind-of 'Number (kv-cmd-client 12345 '("ID")) "[CLIENT LIST] Should return a client id")
  (assert-kind-of 'String (kv-cmd-client NIL '("LIST")) "[CLIENT LIST] Should return a client list")
  (assert-equal 1 (kv-cmd-client NIL '("KILL" "ID" "1")) "[CLIENT LIST] Should kill a client")
  (assert-equal 0 (kv-cmd-client NIL '("KILL" "ID" "2")) "[CLIENT LIST] Should not kill a client that doesn't exist")
  ]

[de test-commands-get-set ()
  (assert-nil (kv-cmd-set) "[SET] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-set "testkey") "[SET] Should return NIL if no value is provided")
  (assert-nil (kv-cmd-get) "[GET] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-get (kv-name "nonexistant")) "[GET] Should return NIL if the key doesn't exist")
  (assert-equal "OK" (kv-cmd-set "testkey" "testvalue") "[SET] Should set a key and return OK")
  (assert-equal "testvalue" (kv-cmd-get "testkey") "[GET] Should return the value of the key")
  (assert-equal "testvalue" (kv-cmd-getset "testkey" "newvalue") "[GETSET] Should return the old value")
  (assert-equal "newvalue" (kv-cmd-get "testkey") "[GETSET] Should return the new value")
  (assert-nil (kv-cmd-mset "key1" "val1" "key2" "val2") "[MSET] Should return NIL if key/values aren't in a list")
  (assert-equal "OK" (kv-cmd-mset '("key1" "val1" "key2" "val2")) "[MSET] Should set multiple keys and values and return OK")
  (assert-nil (kv-cmd-mget "key1" "key2") "[MGET] Should return NIL if key aren't in a list")
  (assert-equal '("val1" "val2") (kv-cmd-mget '("key1" "key2")) "[MGET] Should return multiple values in a list")
  ]

[de test-commands-stats-failures ()
  (assert-nil (kv-cmd-set "%stats%/connected_clients" 0) "[SET] Should fail to overwrite a stats key")
  (assert-nil (kv-cmd-rpush "%stats%/connected_clients" '(1 2 3)) "[RPUSH] Should fail to rpush to a stats key")
  (assert-nil (kv-cmd-lpop (kv-name "%stats%/connected_clients")) "[LPOP] Should fail to left-pop a stats key")
  (assert-nil (kv-cmd-lpoprpush (kv-name "%stats%/connected_clients") "destkey") "[LPOPRPUSH] Should fail to left-pop a stats key")
  (assert-nil (kv-cmd-lpoprpush (kv-name "sourcekey") "%stats%/connected_clients") "[LPOPRPUSH] Should fail to rpush to a stats key")
  (assert-equal 0 (kv-cmd-del "%stats%/connected_clients") "[DEL] Should fail to delete a stats key")
  (assert-equal 1 (kv-cmd-del "validkey" (list "%stats%/connected_clients")) "[DEL] Should fail to delete multiple stats key")
  ]

[de test-commands-ident ()
  (assert-nil (kv-cmd-ident) "[IDENT] Should return NIL if no child pid is provided")
  (assert-nil (kv-cmd-ident 12345) "[IDENT] Should return NIL if no elements are provided")
  (assert-nil (kv-cmd-ident 12345 "abc") "[IDENT] Should return NIL if elements aren't a list")
  (assert-equal "OK abc" (kv-cmd-ident 12345 (list (cons "name" "abc"))) "[IDENT] Should return OK with the client ID")
  (assert-kind-of 'Number (kv-cmd-strlen "%stats%/connected_clients") "[LLEN] Should show only 1 connected client")
  ]

[de test-commands-info ()
  (assert-equal *KV_port (cdr (assoc "tcp_port" (kv-info-server))) "[INFO-SERVER] Should return a list of server INFO")
  (assert-nil (cdr (assoc "connected_clients" (kv-info-server))) "[INFO-CLIENTS] Should return a list of clients INFO")
  (assert-kind-of 'String (cdr (assoc "used_memory_human" (kv-info-memory))) "[INFO-MEMORY] Should return a list of memory INFO")
  (assert-kind-of 'Number (cdr (assoc "total_connections_received" (kv-info-stats))) "[INFO-STATS] Should return a list of stats INFO")
  (assert-kind-of 'String (kv-info-default) "[INFO] Should return a string of INFO")
  ]

[de test-commands-del ()
  (kv-cmd-set "delkey1" "deletekey")
  (assert-equal 1 (kv-cmd-del "delkey1") "[DEL] Should delete a single key")
  (kv-cmd-rpush "delkey2" '(0 0 1 1 0 1 0 0))
  (kv-cmd-rpush "delkey3" '(0 0 1 1 0 1 1 0))
  (assert-equal 4 (kv-cmd-del "delkey2" (list "delkey3" "delkey4" "delkey5")) "[DEL] Should delete multiple keys and return how many were deleted")
  (assert-equal 0 (kv-cmd-strlen "delkey2") "[LLEN] Should confirm if delkey2 was deleted")
  (assert-equal 0 (kv-cmd-strlen "delkey3") "[LLEN] Should confirm if delkey3 was deleted")
  (assert-equal 0 (kv-cmd-del) "[DEL] Should not delete a key that isn't provided")
  ]

[de test-commands-process ()
  (assert-equal "Error: Unknown command" (kv-process 12345 (list "UNKNOWN")) "[PROCESS] Should return an ERROR message if the command is unknown")
  (assert-equal "OK" (kv-process 12345 (list "SET" '("processkey2" "processvalue"))) "[PROCESS] Should process the SET command")
  (assert-equal 3 (kv-process 12345 (list "RPUSH" '("processkeytest" 11 22 33))) "[PROCESS] Should process the RPUSH command")
  (assert-equal 3 (kv-process 12345 (list "LLEN" '("processkeytest"))) "[PROCESS] Should process the LLEN command")
  (assert-kind-of 'String (kv-process 12345 (list "info" '("server"))) "[PROCESS] Should process a lowercase command")
  ]

[de test-commands-bgsave ()
  (kv-cmd-rpush "mylist" '("1" "2" "3" "4" "5" "6" "7" "8" "9" "10"))
  (let KV_desc (open *KV_aof)
    (kv-save-aof '("RPUSH" '("mylist" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10")) KV_desc)
    (close KV_desc) )
  (assert-equal "OK" (kv-cmd-get "%stats%/aof_last_write_status") "[BGSAVE] Should be OK for saving a valid AOF entry")
  (kv-save-db-keys)
  (kv-write-db)
  (assert-equal 0 (kv-restore "DB" *KV_db) "[BGSAVE] Should return 0 when restoring the DB")
  (out *KV_db_lock (prinl "12345"))
  (assert-equal "Error: DB is locked for writing" (kv-locked?) "[BGSAVE] Should return an error if the DB is locked")
  (call 'rm "-f" *KV_db_lock)
  (assert-nil (kv-locked?) "[BGSAVE] Should return NIL if the DB is not locked")
  (assert-kind-of 'String (kv-timestamp) "[BGSAVE] Should return a UNIX timestamp")
  (kv-save-db-keys)
  (assert-kind-of 'List (info *KV_db_tmp) "[BGSAVE] Should return a list if a temp DB exists after saving the keys")
  (assert-t (kv-write-db) "[BGSAVE] Should write the DB to disk")
  (assert-equal 0 (kv-rewrite-aof) "[BGSAVE] Should return 0 when writing the AOF to disk")
  ]

[de test-commands-exists ()
  (kv-cmd-rpush "existlist" '("1" "2" "3" "4" "5" "6" "7" "8" "9" "10"))
  (kv-cmd-rpush "existlist2" '("1" "2" "3" "4" "5" "6" "7" "8" "9" "10"))
  (assert-equal 1 (kv-cmd-exists "existlist") "[EXISTS] Should return 1 if the key exists")
  (assert-equal 0 (kv-cmd-exists "nonexists") "[EXISTS] Should return 0 if the key doesn't exist")
  (assert-equal 2 (kv-cmd-exists "existlist" '("existlist2")) "[EXISTS] Should return 2 if the two keys exist")
  (assert-equal 3 (kv-cmd-exists "existlist" '("existlist" "existlist2")) "[EXISTS] Should return 3 if the two keys exist and one is a duplicate")
  ]

[de test-commands-ping ()
  (assert-equal "PONG" (kv-cmd-ping) "[PING] Should return PONG")
  (assert-equal "Hello" (kv-cmd-ping "Hello") "[PING] Should return Hello")
  ]

[de test-commands-strlen ()
  (kv-cmd-set "lengthkey" "hello")
  (assert-nil (kv-cmd-strlen) "[STRLEN] Should return NIL if the key isn't provided")
  (assert-equal 0 (kv-cmd-strlen "nonexists") "[STRLEN] Should return 0 if the key doesn't exist")
  (assert-equal 5 (kv-cmd-strlen "lengthkey") "[STRLEN] Should return the length of the key's value")
  ]

[execute
  (prinl "^J  Testing Key/Value^J")

  '(assert-equal 0 (kv-cmd-strlen "nonexistant") "[LLEN] Should return 0 if the key doesn't exist")
  '(test-commands-append)
  '(test-commands-client)
  '(test-commands-del)
  '(test-commands-get-set)
  '(test-commands-ident)
  '(test-commands-info)
  '(test-commands-stats-failures)
  '(test-commands-process)
  '(test-commands-bgsave)
  '(test-commands-exists)
  '(test-commands-ping)
  '(test-commands-strlen)
  ]
