#!/usr/bin/env pil

(load (pack (car (file)) ".modules/picolisp-unit/HEAD/unit.l"))

(load (pack (car (file)) "libkv.l"))

(setq
  *KV_pass "testpasswordfortests"
  *KV_port 46378 )

(unless (fork)
        (exec './server.l "--pass" *KV_pass "--port" *KV_port) )

(chdir (pack (car (file)) "test/")
  (mapcar load (filter '((N) (sub? "test_" N)) (dir "."))) )

(kill (car (kids)))
(report)
