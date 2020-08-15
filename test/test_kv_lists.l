# Key/Value Lists tests

[de test-commands-lindex ()
  (assert-nil (kv-cmd-lindex) "[LINDEX] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-lindex "testindex") "[LINDEX] Should return NIL if no index is provided")
  (assert-nil (kv-cmd-lindex "nonexistant") "[LINDEX] Should return NIL if the key doesn't exist")
  (assert-nil (kv-cmd-lindex "testindex" "abc") "[LINDEX] Should return NIL if index isn't a number")
  ]

[de test-commands-lpop ()
  (assert-nil (kv-cmd-lpop) "[LPOP] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-lpop "nonexistant") "[LPOP] Should return NIL if the key doesn't exist")
  ]

[de test-commands-lpoprpush ()
  (off *KV/inkey)
  (off *KV/outkey)
  (assert-nil (kv-cmd-lpoprpush) "[LPOPRPUSH] Should return NIL if no source is provided")
  (assert-nil (kv-cmd-lpoprpush "inkey") "[LPOPRPUSH] Should return NIL if no dest is provided")
  (assert-nil (kv-cmd-lpoprpush "nonexistant") "[LPOPRPUSH] Should return NIL if the key doesn't exist")
  (kv-cmd-rpush "inkey" '(5 6 7 8 9))
  (assert-equal 5 (kv-cmd-lpoprpush "inkey" "outkey") "[LPOPRPUSH] Should return the element being popped")
  (assert-equal 4 (kv-cmd-strlen "inkey") "[LLEN] Should list only 4 elements in the source key")
  (assert-equal 1 (kv-cmd-strlen "outkey") "[LLEN] Should list only 1 element in the dest key")
  (assert-equal 5 (kv-cmd-lindex "outkey" 0) "[LINDEX] Should return the value of the popped key")
  (assert-equal 6 (kv-cmd-lindex "inkey" 0) "[LINDEX] Should return the value of the first key")
  (assert-equal 6 (kv-cmd-lpoprpush "inkey" "outkey") "[LPOPRPUSH] Should return the element being popped (again)")
  ]

[de test-commands-lpush ()
  (assert-nil (kv-cmd-lpush) "[LPUSH] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-lpush "tasks") "[LPUSH] Should return NIL if only 1 key is provided")
  (assert-nil (kv-cmd-lpush "tasks") "[LPUSH] Should return NIL if no elements are provided")
  (assert-nil (kv-cmd-lpush "tasks" "element 1") "[LPUSH] Should return NIL if the elements aren't a list")
  (off *KV/%stats%/keys)
  (off *KV/tasks)
  (assert-equal 5 (kv-cmd-lpush "tasks" '("task1" "task2" "task3" "task4" "task5")) "[LPUSH] Should return the length of the new list")
  (assert-equal 7 (kv-cmd-lpush "tasks" '("task6" "task7")) "[LPUSH] Should return the extended length of the list")
  (assert-equal "task7" (kv-cmd-lindex "tasks" 0) "[LINDEX] Should return the key at index 0")
  (assert-equal "task3" (kv-cmd-lindex "tasks" 4) "[LINDEX] Should return the key at index 5")
  (assert-equal "task1" (kv-cmd-lindex "tasks" -1) "[LINDEX] Should return the last key")
  (assert-equal "task2" (kv-cmd-lindex "tasks" -2) "[LINDEX] Should return the penultimate key")
  (assert-nil (kv-cmd-lindex "tasks" 10) "[LINDEX] Should return NIL if no value exists at the index")
  (assert-equal 1 (kv-cmd-strlen "%stats%/keys") "[LLEN] Should return the number of keys in the keys list")
  (assert-equal "task7" (kv-cmd-lpop "tasks") "[LPOP] Should return the first value added to the tasks list")
  (assert-equal 6 (kv-cmd-strlen "tasks") "[LLEN] Should return the number of keys remaining in the tasks list")
  ]

[de test-commands-lrange ()
  (assert-nil (kv-cmd-lrange) "[LRANGE] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-lrange "nonexistant") "[LRANGE] Should return NIL if the key doesn't exist")
  (assert-nil (kv-cmd-lrange "inkey" -1 -2) "[LRANGE] Should return NIL if the range has a negative number")
  ]

[de test-commands-lrem ()
  (assert-equal 0 (kv-cmd-lrem) "[LREM] Should return NIL if no key is provided")
  (assert-equal 0 (kv-cmd-lrem "nonexistant") "[LREM] Should return NIL if the key doesn't exist")
  (assert-equal 0 (kv-cmd-lrem "inkey" -1 "value") "[LREM] Should return NIL if the count has a negative number")
  ]

[de test-commands-lset ()
  (assert-nil (kv-cmd-lset) "[LSET] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-lset "nonexistant") "[LSET] Should return NIL if the key doesn't exist")
  (assert-nil (kv-cmd-lset "inkey" -1 "value" "one") "[LSET] Should return NIL if the index has a negative number")
  ]

[de test-commands-ltrim ()
  (assert-nil (kv-cmd-ltrim) "[LTRIM] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-ltrim "nonexistant") "[LTRIM] Should return NIL if the key doesn't exist")
  (assert-nil (kv-cmd-ltrim "inkey" -1 -2) "[LTRIM] Should return NIL if the range has a negative number")
  ]

[de test-commands-rpop ()
  (assert-nil (kv-cmd-rpop) "[RPOP] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-rpop "nonexistant") "[RPOP] Should return NIL if the key doesn't exist")
  ]

[de test-commands-rpoplpush ()
  (off *KV/inkey)
  (off *KV/outkey)
  (assert-nil (kv-cmd-rpoplpush) "[RPOPLPUSH] Should return NIL if no source is provided")
  (assert-nil (kv-cmd-rpoplpush "inkey") "[RPOPLPUSH] Should return NIL if no dest is provided")
  (assert-nil (kv-cmd-rpoplpush "nonexistant") "[RPOPLPUSH] Should return NIL if the key doesn't exist")
  (kv-cmd-rpush "inkey2" '(5 6 7 8 9))
  (assert-equal 9 (kv-cmd-rpoplpush "inkey2" "outkey2") "[RPOPLPUSH] Should return the element being popped")
  (assert-equal 4 (kv-cmd-strlen "inkey2") "[LLEN] Should list only 4 elements in the source key")
  (assert-equal 1 (kv-cmd-strlen "outkey2") "[LLEN] Should list only 1 element in the dest key")
  (assert-equal 9 (kv-cmd-lindex "outkey2" 0) "[LINDEX] Should return the value of the popped key")
  (assert-equal 5 (kv-cmd-lindex "inkey2" 0) "[LINDEX] Should return the value of the first key")
  (assert-equal 8 (kv-cmd-rpoplpush "inkey2" "outkey2") "[RPOPLPUSH] Should return the element being popped (again)")
  ]

[de test-commands-rpush ()
  (assert-nil (kv-cmd-rpush) "[RPUSH] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-rpush "tasks") "[RPUSH] Should return NIL if only 1 key is provided")
  (assert-nil (kv-cmd-rpush "tasks") "[RPUSH] Should return NIL if no elements are provided")
  (assert-nil (kv-cmd-rpush "tasks" "element 1") "[RPUSH] Should return NIL if the elements aren't a list")
  (off *KV/%stats%/keys)
  (off *KV/tasks)
  (assert-equal 5 (kv-cmd-rpush "tasks" '("task1" "task2" "task3" "task4" "task5")) "[RPUSH] Should return the length of the new list")
  (assert-equal 7 (kv-cmd-rpush "tasks" '("task6" "task7")) "[RPUSH] Should return the extended length of the list")
  (assert-equal '("task1" "task2") (kv-cmd-lrange "tasks" 0 1) "[LRANGE] Should return the keys in the range 0 1")
  (assert-equal "task1" (kv-cmd-lindex "tasks" 0) "[LINDEX] Should return the key at index 0")
  (assert-equal "task5" (kv-cmd-lindex "tasks" 4) "[LINDEX] Should return the key at index 5")
  (assert-equal "task7" (kv-cmd-lindex "tasks" -1) "[LINDEX] Should return the last key")
  (assert-equal "task6" (kv-cmd-lindex "tasks" -2) "[LINDEX] Should return the penultimate key")
  (assert-nil (kv-cmd-lindex "tasks" 10) "[LINDEX] Should return NIL if no value exists at the index")
  (assert-equal 1 (kv-cmd-strlen "%stats%/keys") "[LLEN] Should return the number of keys in the keys list")
  (assert-equal "task1" (kv-cmd-lpop "tasks") "[LPOP] Should return the first value added to the tasks list")
  (assert-equal 6 (kv-cmd-strlen "tasks") "[LLEN] Should return the number of keys remaining in the tasks list")
  (assert-equal 1 (kv-cmd-lrem "tasks" 3 "task3") "[LREM] Should return the number of keys removed from the task list")
  (assert-equal 5 (kv-cmd-strlen "tasks") "[LLEN] Should return the number of keys in the keys list (shortened)")
  (assert-equal "OK" (kv-cmd-lset "tasks" 4 "task8") "[LSET] Should return OK if the task value was replaced")
  (assert-nil (kv-cmd-lset "tasks" 10 "task8") "[LSET] Should return NIL if the task value can't be replaced")
  (assert-equal "task8" (kv-cmd-lindex "tasks" 4) "[LINDEX] Should return the value of the key in the keys list")
  (assert-equal "OK" (kv-cmd-ltrim "tasks" 0 1) "[LTRIM] Should return OK when if the task list is trimmed")
  (assert-equal 2 (kv-cmd-strlen "tasks") "[LLEN] Should return the number of keys in the keys list (shortened again)")
  ]

[execute
  '(test-commands-lindex)
  '(test-commands-lpop)
  '(test-commands-lpoprpush)
  '(test-commands-lpush)
  '(test-commands-lrange)
  '(test-commands-lrem)
  '(test-commands-lset)
  '(test-commands-ltrim)
  '(test-commands-rpop)
  '(test-commands-rpoplpush)
  '(test-commands-rpush)
  ]
