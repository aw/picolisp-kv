# Client/Server tests

[de test-client-cmd @
  (append (list './client.l "--port" *KV_port "--name" *Client_id "--pass" *KV_pass) (rest) ]

[de tests-execute ()
  (call './client.l "--port" *KV_port "--name" *Client_id "--pass" *KV_pass "INFO")
  (assert-equal (pack "OK " *Client_id) (in (test-client-cmd "INFO" "server") (line T))             "[CLIENT/SERVER] Test INFO command")
  (assert-equal "OK" (in (test-client-cmd "SET" "testkey" "testdata") (line) (line T))             "[CLIENT/SERVER] Test SET command")
  (assert-equal "testdata" (in (test-client-cmd "GET" "testkey") (line) (line T))                  "[CLIENT/SERVER] Test GET command")
  (assert-equal "no data" (in (test-client-cmd "GET" "nokey") (line) (line T))                     "[CLIENT/SERVER] Test NO DATA result")
  (assert-nil (call './client.l "--port" *KV_port "--name" *Client_id "--pass" *KV_pass "UNKNOWN")    "[CLIENT/SERVER] Test UNKNOWN command")
  (assert-nil (call './client.l "--port" *KV_port "--name" *Client_id "--pass" "badpass" "GET")       "[CLIENT/SERVER] Test AUTH with bad password")
  (assert-kind-of 'Number (in (test-client-cmd "GET" "%stats%/keyspace_hits") (line) (format (line T))) "[CLIENT/SERVER] Test STATS command")
  (assert-includes (pack "name=" *Client_id " addr=") (in (test-client-cmd "CLIENT" "LIST") (line) (line T)) "[CLIENT/SERVER] Test CLIENT LIST command")
  (assert-kind-of 'Number (in (test-client-cmd "CLIENT" "ID") (line) (format (line T))) "[CLIENT/SERVER] Test CLIENT ID command")
  ]

[de tests-client-server ()
  (use *Client_id
    (setq *Client_id "52D77057")

    (execute
      '(tests-execute) ]

[chdir ".."
  (tests-client-server) ]
