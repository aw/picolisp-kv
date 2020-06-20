#!/usr/bin/env pil
#
# Server example implementation
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

[de APP_HELP
  ("usage"     "./server.l --pass <pass> [options]")
  ("example"   "./server.l --pass foobared --port 6378 --verbose'^J")
  ("options"   ("--help"                  "Show this help message and exit")
               ()
               ("--pass <password>"       "Password used by clients to access the server (required)")
               ("--port <port>"           "TCP listen port for communication with clients (default: 6378)")
               ("--verbose"               "Verbose flag (default: False)") ]

(chdir (car (file)) (load "libkv.l" "clihelpers.l"))

# START
(ifn  (argv)
      (kv-show-help)
      (while (opt)
        (case @
          (--verbose  (on *KV_verbose))               # default 'off'
          (--port     (setq *KV_port (format (opt)))) # default '6378'
          (--pass     (setq *KV_pass (opt)))          # required
          (T          (kv-show-help) (bye 1)) ) )
      (kv-listen) )

(bye)
