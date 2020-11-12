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
               ("--commands"              "Show the full list of commands and exit")
               ()
               ("--decrypt"               "Enable decryption of values using a GPG public key (default: disabled)")
               ("--encrypt"               "Enable encryption of values using a GPG public key (default: disabled)")
               ("--name  <name>"          "Easily identifiable client name (default: randomly generated)")
               ("--host  <host>"          "Hostname or IP of the key/value server (default: localhost)")
               ("--pass  <data>"          "Password used to access the server (required)")
               ("--poll  <seconds>"       "Number of seconds for polling the key/value server (default: don't poll)")
               ("--port  <port>"          "TCP port of the key/value server (default: 6378)")
               ("-- STDIN"                "Reads an argument from STDIN")
               ()
               ("COMMAND LIST"    "Use '--commands' to see the full list of commands") )
  ("commands"
               ("COMMAND LIST"     "Commands are case-insensitive and don't always require arguments")
               ()
               ("APPEND key value"                  "^I^IAppend a value to a key")
               ("BGSAVE"                            "^I^IAsynchronously save the dataset to disk")
               ("CLIENT ID"                         "^I^IReturns the client ID for the current connection")
               ("CLIENT KILL ID id [id ..]"         "^I^IKill the connection of a client")
               ("CLIENT LIST"                       "^I^IGet the list of client connections")
               ("CONVERT"                           "^I^IConvert a plaintext database to binary or vice-versa")
               ("DEL key [key ..]"                  "^I^IDelete a key")
               ("EXISTS key [key ..]"               "^I^IDetermine if a key exists")
               ("GET key"                           "^I^IGet the value of a key")
               ("GETSET key value"                  "^I^ISet the string value of a key and return its old value")
               ("HDEL key field [field ..]"         "^I^IDelete one or more hash fields")
               ("HEXISTS key field"                 "^I^IDetermine if a hash field exists")
               ("HFIND key substring"               "^I^IFind a substring in a hash key's field")
               ("HGET key field"                    "^I^IGet the value of a hash field")
               ("HGETALL key"                       "^I^IGet all the fields and values in a hash")
               ("HKEYS key"                         "^I^IGet all the fields in a hash")
               ("HLEN key"                          "^I^IGet the number of fields in a hash")
               ("HMGET key field [field ..]"        "^IGet the values of all the given hash fields")
               ("HSET key field value [field value ..] Set the string value of a hash field")
               ("HSTRLEN key field"                 "^I^IGet the length of the value of a hash field")
               ("HVALS key"                         "^I^IGet all the values in a hash")
               ("INFO [section]"                    "^I^IGet information and statistics about the server")
               ("LINDEX key index"                  "^I^IGet an element from a list by its index")
               ("LLEN key"                          "^I^IGet the length of a list")
               ("LPOP key"                          "^I^IRemove and get the first element in a list")
               ("LPOPRPUSH source destination"      "^IRemove the first element in a list, append it to another list and return it")
               ("LPUSH key element [element ..]"    "^IPrepend one or multiple elements to a list")
               ("LRANGE key start stop"             "^I^IGet a range of elements from a list")
               ("LREM key count element"            "^I^IRemove elements from a list")
               ("LSET key index element"            "^I^ISet the value of an element in a list by its index")
               ("LTRIM key start stop"              "^I^ITrim a list to the specified range")
               ("MGET key [key ..]"                 "^I^IGet the values of all the given keys")
               ("MSET key value [key value ..]"     "^ISet multiple keys to multiple values")
               ("PING [message]"                    "^I^IPing the server")
               ("RPOP key"                          "^I^IRemove and get the last element in a list")
               ("RPOLRPUSH source destination"      "^IRemove the last element in a list, prepend it to another list and return it")
               ("RPUSH key element [element ..]"    "^IAppend one or multiple elements to a list")
               ("SAVE"                              "^I^ISynchronously save the dataset to disk")
               ("SET key value"                     "^I^ISet the string value of a key")
               ("STRLEN key"                        "^I^IGet the length of the value stored in a key") ]

(chdir (car (file)) (load "libkvclient.l" "clihelpers.l" "module.l"))

# START
[ifn  (argv)
      (kv-show-help)
      (while (opt)
        (case @
          (--help     (kv-show-help) (bye 1))
          (--commands (kv-show-commands) (bye 1))
          (--decrypt  (on *KV_decrypt))                        # decrypt all values using GPG
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
                #(kv-print @) # don't print the "OK <name>" reply
                (if *KV_poll
                    (loop
                      (NIL (when (kv-send-data *Cmdargs)
                                (kv-print @)
                                (wait (* 1000 (format *KV_poll)))
                                T ) ) )
                    (kv-print (kv-send-data *Cmdargs)) ]

(bye)
