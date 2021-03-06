#!/usr/bin/env pil

(load (pack (car (file)) ".modules/picolisp-unit/HEAD/unit.l"))

(load (pack (car (file)) "libkv.l"))

(setq
  *KV_pass "testpasswordfortests"
  *KV_persist 600 # 10 minutes
  *KV_port (rand 40001 49999) )

(prinl "Starting server on port: " *KV_port)

# run key/value store tests with persistence
(chdir (pack (car (file)) "test/")
  (call 'rm "-f" *KV_db (pack *KV_db ".old") *KV_aof *KV_aof_lock) # cleanup first
  (unless (fork)
    (kv-listen) )
  (mapcar load (filter '((N) (sub? "test_kv" N)) (dir "."))) )

(mapcar kill (kids))
(wait 1000)

(setq *KV_port (rand 40001 49999))

# run the client/server tests without persistence
#{ # NOTE: disabled integration tests
(chdir (pack (car (file)) "test/")
  (call 'rm "-f" *KV_db (pack *KV_db ".old") *KV_aof *KV_aof_lock) # cleanup first
  (unless (fork)
    (exec '../server.l "--pass" *KV_pass "--port" *KV_port) )
  (mapcar load (filter '((N) (sub? "test_cs" N)) (dir "."))) )

(kill (car (kids))) # ensure the server is stopped
}#

(report)
