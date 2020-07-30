#!/usr/bin/env pil
#
# Server example implementation
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

[de APP_HELP
  ("usage"     "./server.l --pass <pass> [options]")
  ("example"   "./server.l --pass foobared --port 6378 --verbose --persist 60^J")
  ("options"   ("--help"                  "Show this help message and exit")
               ()
               ("--binary"                "Store data in binary format instead of text (default: plaintext)")
               ("--pass <password>"       "Password used by clients to access the server (required)")
               ("--persist <seconds>"     "Number of seconds between database persists to disk (default: disabled)")
               ("--port <port>"           "TCP listen port for communication with clients (default: 6378)")
               ("--verbose"               "Verbose flag (default: False)") ]

(chdir (car (file)) (load "libkv.l" "clihelpers.l"))

# Enable storing the database in binary format (PLIO)
[de kv-enable-binary ()
  (on *KV_binary)
  (setq *KV_db "kv.bin")
  (kv-tmpfile-set) ]

# START
(ifn  (argv)
      (kv-show-help)
      (while (opt)
        (case @
          (--binary   (kv-enable-binary))                      # default 'off'
          (--verbose  (on *KV_verbose))                        # default 'off'
          (--port     (setq *KV_port (format (opt))))          # default '6378'
          (--persist  (setq *KV_persist (format (opt))))       # default 'off'
          (--pass     (setq *KV_pass (opt)))                   # required
          (T          (kv-show-help) (bye 1)) ) )
      (kv-listen) )

(bye)
