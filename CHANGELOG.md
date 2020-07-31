# Changelog

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
