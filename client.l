#!/usr/bin/env pil
#
# Client example implementation
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

[de APP_HELP
  ("usage"     "./client.l --pass <pass> COMMAND [arguments]")
  ("example"   "./client.l --pass foobared --encrypt SET mysecret -- <(echo 'mypass')^J")
  ("options"   ("--help"                  "Show this help message and exit")
               ()
               ("--encrypt"               "Enable encryption of values using a GPG public key (default: disabled)")
               ("--name  <name>"          "Easily identifiable client name (default: randomly generated)")
               ("--host  <host>"          "Hostname or IP of the key/value server (default: localhost)")
               ("--pass  <data>"          "Password used to access the server (required)")
               ("--poll  <seconds>"       "Number of seconds for polling the key/value server (default: don't poll)")
               ("--port  <port>"          "TCP port of the key/value server (default: 6378)")
               ("-- STDIN"                "Allows reading an argument from STDIN")
               ()
               ("COMMAND LIST"     "Commands are case-insensitive and don't always require arguments.^J^I^I^I^I^IExamples:")
               ()
               ("  APPEND key value"                  "^I^IAPPEND mykey hello")
               ("  BGSAVE"                            "^I^IBGSAVE")
               ("  CLIENT ID|KILL|LIST id [id ..]"    "^ICLIENT LIST")
               ("  CONVERT"                           "^I^ICONVERT")
               ("  DEL key [key ..]"                  "^I^IDEL key1 key2 key3")
               ("  EXISTS key [key ..]"               "^I^IEXISTS key1 key2 key3")
               ("  GET key"                           "^I^IGET key1")
               ("  GETSET key value"                  "^I^IGETSET mykey hello")
               ("  INFO [section]"                    "^I^IINFO memory")
               ("  LINDEX key index"                  "^I^ILINDEX mylist 0")
               ("  LLEN key"                          "^I^ILLEN mylist")
               ("  LPOP key"                          "^I^ILPOP mylist")
               ("  LPOPRPUSH source destination"      "^ILPOPRPUSH mylist myotherlist")
               ("  LPUSH key element [element ..]"    "^ILPUSH mylist task1 task2 task3")
               ("  LRANGE key start stop"             "^I^ILRANGE mylist 0 10")
               ("  LREM key count element"            "^I^ILREM mylist 2 task")
               ("  LSET key index element"            "^I^ILSET mylist 0 newtask1")
               ("  LTRIM key start stop"              "^I^ILTRIM mylist task1 task2 task3")
               ("  PING [message]"                    "^I^IPING hello")
               ("  RPOP key"                          "^I^IRPOP mylist")
               ("  RPOLRPUSH source destination"      "^IRPOPRPUSH mylist myotherlist")
               ("  RPUSH key element [element ..]"    "^IRPUSH mylist task1 task2 task3")
               ("  SAVE"                              "^I^ISAVE")
               ("  SET key value"                     "^I^ISET mykey hello") ]

(chdir (car (file)) (load "libkvclient.l" "clihelpers.l" "module.l"))

# START
[ifn  (argv)
      (kv-show-help)
      (while (opt)
        (case @
          (--help     (kv-show-help) (bye 1))
          (--encrypt  (on *KV_encrypt))                        # encrypt all values using GPG
          (--host     (setq *KV_host (opt)))                   # default 'localhost'
          (--port     (setq *KV_port (opt)))                   # default '6378'
          (--name     (setq *KV_clientid (opt)))               # default '<randomly generated>'
          (--poll     (setq *KV_poll (opt)))                   # enable polling of command
          (--pass     (setq *KV_pass (opt)))                   # required password
          (--         (queue '*Cmdargs (in (opt) (line T))))   # reads the argument from STDIN
          (T          (queue '*Cmdargs @)) ) )                 # save remaining cmdline arguments

      (finally
        (when *Msg (bye 1))
        (catch 'kv-error
          (when (kv-start-client)
                (kv-print @)
                (if *KV_poll
                    (loop
                      (NIL (when (kv-send-data *Cmdargs)
                                (kv-print @)
                                (wait (* 1000 (format *KV_poll)))
                                T ) ) )
                    (kv-print (kv-send-data *Cmdargs)) ]

(bye)
