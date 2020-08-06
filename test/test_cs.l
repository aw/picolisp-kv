# Client/Server tests

[de test-client-cmd @
  (append (list './client.l "--port" *KV_port "--name" *Client_id "--pass" *KV_pass) (rest) ]

[de tests-execute ()
  (call './client.l "--port" *KV_port "--name" *Client_id "--pass" *KV_pass "INFO")
  (assert-equal "# Server" (in (test-client-cmd "INFO" "server") (line) (line T))                   "[CLIENT/SERVER] Test INFO command")
  (assert-equal "OK" (in (test-client-cmd "SET" "testkey" "testdata") (line T))                     "[CLIENT/SERVER] Test SET command")
  (assert-equal "testdata" (in (test-client-cmd "GET" "testkey") (line T))                          "[CLIENT/SERVER] Test GET command")
  (assert-nil (in (test-client-cmd "GET" "nokey") (line T))                                         "[CLIENT/SERVER] Test NO DATA result")
  (assert-t (call './client.l "--port" *KV_port "--name" *Client_id "--pass" *KV_pass "UNKNOWN")    "[CLIENT/SERVER] Test UNKNOWN command")
  (assert-nil (call './client.l "--port" *KV_port "--name" *Client_id "--pass" "badpass" "GET")      "[CLIENT/SERVER] Test AUTH with bad password")
  (assert-kind-of 'Number (in (test-client-cmd "GET" "%stats%/keyspace_hits") (format (line T)))     "[CLIENT/SERVER] Test STATS command")
  (assert-includes (pack "name=" *Client_id " addr") (in (test-client-cmd "CLIENT" "LIST") (line T)) "[CLIENT/SERVER] Test CLIENT LIST command")
  (assert-kind-of 'Number (in (test-client-cmd "CLIENT" "ID") (format (line T)))                     "[CLIENT/SERVER] Test CLIENT ID command")
  ]

[de tests-client-server ()
  (use *Client_id
    (setq *Client_id "52D77057")

    (execute
      '(tests-execute) ]

[chdir ".."
  (tests-client-server) ]
