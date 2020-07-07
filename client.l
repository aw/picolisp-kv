#!/usr/bin/env pil
#
# Client example implementation
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

[de APP_HELP
  ("usage"     "./client.l --pass <pass> COMMAND [arguments]")
  ("example"   "./client.l --pass foobared --port 6378 INFO server'^J")
  ("options"   ("--help"                  "Show this help message and exit")
               ()
               ("--id <id>"               "Uniquely identifiable client ID (default: randomly generated)")
               ("--host  <host>"          "Hostname or IP of the key/value server (default: localhost)")
               ("--pass  <data>"          "Password used to access the server (required)")
               ("--poll  <seconds>"       "Number of seconds for polling the key/value server (default: don't poll)")
               ("--port  <port>"          "TCP port of the key/value server (default: 6378)")
               ()
               ("COMMAND LIST"     "Commands are case-insensitive and don't always require arguments.^J^I^I^I^I^IExamples:")
               ()
               ("  BGSAVE"                            "^I^IBGSAVE")
               ("  DEL key [key ..]"                  "^I^IDEL key1 key2 key3")
               ("  GET key"                           "^I^IGET key1")
               ("  INFO [section]"                    "^I^IINFO memory")
               ("  LINDEX key index"                  "^I^ILINDEX mylist 0")
               ("  LLEN key"                          "^I^ILLEN mylist")
               ("  LOLWUT number"                     "^I^ILOLWUT 5")
               ("  LPOP key"                          "^I^ILPOP mylist")
               ("  LPOPRPUSH source destination"      "^ILPOPRPUSH mylist myotherlist")
               ("  RPUSH key element [element ..]"    "^IRPUSH mylist task1 task2 task3")
               ("  SAVE"                              "^I^ISAVE")
               ("  SET key value"                     "^I^ISET mykey hello") ]

(chdir (car (file)) (load "libkvclient.l" "clihelpers.l"))

# START
[ifn  (argv)
      (kv-show-help)
      (while (opt)
        (case @
          (--host     (setq *KV_host (opt)))                   # default 'localhost'
          (--port     (setq *KV_port (opt)))                   # default '6378'
          (--id       (setq *KV_clientid (opt)))               # default '<randomly generated>'
          (--poll     (setq *KV_poll (opt)))                   # enable polling of command
          (--pass     (setq *KV_pass (opt)))                   # required password
          (T          (queue '*Cmdargs @)) ) )                 # save remaining cmdline arguments

      (finally (unless (=T @) (bye 1))
        (catch 'kv-error
          (when (kv-start-client)
                (setq *KV_server_ok (kv-identify))
                (kv-print *KV_server_ok)
                (if *KV_poll
                    (loop
                      (kv-print (kv-send-data *Cmdargs))       # send the data to the server (loop)
                      (wait (* 1000 (format *KV_poll))) )      # wait N seconds before looping again
                    (kv-print (kv-send-data *Cmdargs)) ]       # send the data to the server once

(bye)
