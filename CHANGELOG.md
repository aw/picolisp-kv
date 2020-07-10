# Changelog

## 0.14.0 (TBD)

  * Fix bug where client IP is not saved in client list
  * Fix bug where client would not disconnect when sent a `kill` command
  * Removed the `IDENT` command from client library
  * Add `CLIENT ID`, `CLIENT EXIT`, and `CLIENT LIST` commands

## 0.13.0 (2020-06-27)

  * Fix issue where child process doesn't actually 'exit' when exiting (in a fork)
  * Split out some functions into smaller functions
  * Ensure password hashing is done on the server
  * Minor README fixes
