# Changelog

## 0.18.2 (2020-11-30)

  ### Bug fixes

  * Ensure --port value is handled as a number not a string by client.l

## 0.18.1 (2020-11-12)

  ### New features

  * [commands] Add the following Hash COMMAND: `HFIND`

## 0.18.0 (2020-11-10)

  ### New features

  * [documentation] Add the diagrams for _how_ this library works in the `diagrams/` directory

  ### Misc changes

  * Add support for `pil21`
  * Update github actions to use `picolisp-action` version 2
  * Update unit test library to use newer version of `picolisp-unit` which is 10x faster

## 0.17.1 (2020-08-22)

  ### Bug fixes

  * Catch all IO errors when saving the database to disk

## 0.17.0 (2020-08-20)

  ### Bug fixes

  * Catch all IO errors when saving the database to disk

  ### Misc changes

  * Simplified the database save process (persistence)
  * Foreground database saving has been removed, it will _always_ happen in the background
  * The AOF is opened/closed for every write as opposed to being open forever
  * The `SAVE` command is now exactly the same as `BGSAVE`

## 0.16.0 (2020-08-17)

  ### New features

  * [commands] Add the following Hash COMMANDS: `HDEL, HEXISTS, HGET, HGETALL, HKEYS, HLEN, HMGET, HSET, HSTRLEN, HVALS`
  * [commands] Add the following List COMMANDS: `LPUSH, LRANGE, LREM, LSET, LTRIM, RPOP, RPOPLPUSH`
  * [commands] Add the following String COMMANDS: `APPEND, MSET, MGET, STRLEN`
  * [client] Add `--commands` to view the list of all commands
  * [client] Add `--encrypt` and `--decrypt` options to encrypt/decrypt data using a GPG keypair
  * [client] Add `--` option to read last argument data from STDIN

  ### Bug fixes

  * Ensure listening on a socket will abort after `*KV_abort` seconds
  * Reading frorm a socket shouldn't return "no data" or "unknown data" if there's no data. It should just print an empty string.
  * Errors should throw/raise an error with the message, for the client to parse
  * Perform more validations on individual commands, ex: ensuring a Key is a list, etc
  * Temporarily disabled integrations tests because they cause false/positives

  ### Misc changes

  * Change the way IDENT and AUTH is performed in client and server
  * Client doesn't print "OK <name>" anymore for every command
  * Simplify much of the kv command processing code

## 0.15.1 (2020-07-31)

  * Move the global list of all keys to '%stats%/keys' so it can't be deleted or modified
  * Allow 'EXISTS' command on all keys including keys prefixed with '%stats%/'

## 0.15.0 (2020-07-31)

  * Consolidate all server library code into one file: libkv.l
  * Fix loading of module.l
  * Simplify storage location and settings for temporary/lock files
  * Explicitly make the child exit when it's finished processing

## 0.14.2 (2020-07-30)

  * Ensure clients actually exit when a 'CLIENT KILL' command is received

## 0.14.1 (2020-07-30)

  * Ensure clients can poll, by listening with (while) instead of (when)
  * Update documentation with examples of 'CLIENT' commands

## 0.14.0 (2020-07-27)

  * Fix bug where client IP is not saved in client list
  * Fix bug where client would not disconnect when sent a `kill` command
  * Add persistence which writes commands in an AOF using WAL method
  * Saves and restores a DB from disk
  * Replays the AOF after restoring the DB
  * Add 'SAVE' and 'BGSAVE' commands
  * Add 'CLIENT' command
  * Add 'PING' command
  * Add 'EXISTS' command
  * Add 'GETSET' command
  * Add 'CONVERT' command
  * Remove 'LOLWUT' command
  * Run BGSAVE as a scheduled task
  * Add statistics for 'persistence'
  * Add option to save the DB in binary format
  * Add and fix unit tests
  * Add timestamp to output and cleanup error messages etc
  * Don't require IDENT to be sent by the client during auth
  * Fix problem where messages were lost, abort a client connection that takes too long (60s)
  * Major optimization, RPUSH with multiple elements is O(N) instead of O(2^N)
  * Other minor fixes and code cleanup

## 0.13.0 (2020-06-27)

  * Fix issue where child process doesn't actually 'exit' when exiting (in a fork)
  * Split out some functions into smaller functions
  * Ensure password hashing is done on the server
  * Minor README fixes
