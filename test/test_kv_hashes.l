# Key/Value Hashes tests

[de test-commands-hdel ()
  (kv-cmd-hset "hashdelkey" '("one" "1" "two" "2"))
  (kv-cmd-set "hashkeyz" "string")
  (assert-nil (kv-cmd-hdel) "[HDEL] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-hdel "hashdelkey") "[HDEL] Should return NIL if no field is provided")
  (assert-nil (kv-cmd-hdel "hashkeyz") "[HDEL] Should return NIL if the key isn't a list")
  (assert-nil (kv-cmd-hdel "hashkeyzmissing") "[HDEL] Should return NIL if the key doesn't exist")
  (assert-nil (kv-cmd-hdel "hashdelkey" "one") "[HDEL] Should return NIL if the fields are not a list")
  (assert-equal 1 (kv-cmd-hdel "hashdelkey" '("one")) "[HDEL] Should return 1 if the field is deleted")
  (assert-equal 0 (kv-cmd-hdel "hashdelkey" '("three")) "[HDEL] Should return 0 if the field is not deleted")
  ]

[de test-commands-hexists ()
  (kv-cmd-hset "hashexistskey" '("one" "1" "two" "2"))
  (kv-cmd-set "hashkeyz" "string")
  (assert-equal 0 (kv-cmd-hexists) "[HEXISTS] Should return 0 if no key is provided")
  (assert-equal 0 (kv-cmd-hexists "hashexistskey") "[HEXISTS] Should return 0 if no field is provided")
  (assert-nil (kv-cmd-hget "hashkeyz") "[HEXISTS] Should return NIL if key is not a list")
  (assert-equal 0 (kv-cmd-hexists "hashkeyzmissing") "[HEXISTS] Should return 0 if the key doesn't exist")
  (assert-equal 0 (kv-cmd-hexists "hashexistskey" "three") "[HEXISTS] Should return 0 if the field doesn't exist")
  (assert-equal 1 (kv-cmd-hexists "hashexistskey" "one") "[HEXISTS] Should return 1 if the key and field exists")
  ]

[de test-commands-hget ()
  (kv-cmd-hset "hashgetkey" '("one" "1" "two" "2"))
  (kv-cmd-set "hashkeyz" "string")
  (assert-nil (kv-cmd-hget) "[HGET] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-hget "hashgetkey") "[HGET] Should return NIL if no field is provided")
  (assert-nil (kv-cmd-hget "hashkeyz") "[HGET] Should return NIL if key is not a list")
  (assert-nil (kv-cmd-hget "hashkeyzmissing") "[HGET] Should return NIL if the key doesn't exist")
  (assert-equal "1" (kv-cmd-hget "hashgetkey" "one") "[HGET] Should return 1 if the field has a value")
  (assert-equal NIL (kv-cmd-hget "hashgetkey" "three") "[HGET] Should return NIL if the field has no value")
  ]

[de test-commands-hgetall ()
  (kv-cmd-hset "hashgetallkey" '("one" "1" "two" "2"))
  (kv-cmd-set "hashkeyz" "string")
  (assert-nil (kv-cmd-hgetall) "[HGETALL] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-hgetall "hashkeyz") "[HGETALL] Should return NIL if the key is not a list")
  (assert-nil (kv-cmd-hgetall "hashkeyzmissing") "[HGETALL] Should return NIL if the key doesn't exist")
  (assert-equal '(("one" . "1") ("two" . "2")) (kv-cmd-hgetall "hashgetallkey") "[HGETALL] Should return all fields and values")
  ]

[de test-commands-hkeys ()
  (kv-cmd-hset "hashkeyskey" '("one" "1" "two" "2"))
  (kv-cmd-set "hashkeyz" "string")
  (assert-nil (kv-cmd-hkeys) "[HKEYS] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-hkeys "hashkeyz") "[HKEYS] Should return NIL if the key is not a list")
  (assert-nil (kv-cmd-hkeys "hashkeyzmissing") "[HKEYS] Should return NIL if the key doesn't exist")
  (assert-equal '("one" "two") (kv-cmd-hkeys "hashkeyskey") "[HKEYS] Should return all fields")
  ]

[de test-commands-hlen ()
  (kv-cmd-hset "hashlenkey" '("one" "1" "two" "2"))
  (kv-cmd-set "hashkeyz" "string")
  (assert-nil (kv-cmd-hlen) "[HLEN] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-hlen "hashkeyz") "[HLEN] Should return NIL if the key is not a list")
  (assert-equal 0 (kv-cmd-hlen "hashkeyzmissing") "[HLEN] Should return 0 if the key doesn't exist")
  (assert-equal 2 (kv-cmd-hlen "hashlenkey") "[HLEN] Should return all fields")
  ]

[de test-commands-hmget ()
  (kv-cmd-hset "hashmgetkey" '("one" "1" "two" "2"))
  (kv-cmd-set "hashkeyz" "string")
  (assert-nil (kv-cmd-hmget) "[HMGET] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-hmget "hashmgetkey") "[HMGET] Should return NIL if no field is provided")
  (assert-nil (kv-cmd-hmget "hashkeyz") "[HMGET] Should return NIL if key is not a list")
  (assert-nil (kv-cmd-hmget "hashkeyzmissing") "[HMGET] Should return NIL if the key doesn't exist")
  (assert-equal '("1" "2") (kv-cmd-hmget "hashmgetkey" '("one" "two")) "[HMGET] Should return a list if the field has a value")
  (assert-equal '(NIL) (kv-cmd-hmget "hashmgetkey" '("three")) "[HMGET] Should return an empty list if the field has no value")
  ]

[execute
  (prinl "^J  Testing Key/Value Hashes^J")

  '(test-commands-hdel)
  '(test-commands-hexists)
  '(test-commands-hget)
  '(test-commands-hgetall)
  '(test-commands-hkeys)
  '(test-commands-hlen)
  '(test-commands-hmget)
  ]
