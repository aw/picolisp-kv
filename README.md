# Redis-inspired key/value store written in PicoLisp

This program mimics functionality of a [Redis™](https://redis.io) in-memory database, but is designed specifically for [PicoLisp](https://picolisp.com) applications with optional on-disk persistence and encryption.

> **Note:** This library **DOES NOT** use the [RESP protocol](https://redis.io/topics/protocol) and thus cannot work with the `redis-cli` or other _Redis_ clients/servers.

The included `server.l` and `client.l` can be used to send and receive _"Redis-like"_ commands over TCP or UNIX named pipess.

![GET/SET](https://user-images.githubusercontent.com/153401/84755112-ca381780-afb0-11ea-8d13-31d1a2152d2a.png)

  1. [Requirements](#requirements)
  2. [Getting Started](#getting-started)
  3. [Usage](#usage)
  4. [Note and Limitations](#notes-and-limitations)
  5. [How it works](#how-it-works)
  6. [Persistence](#persistence)
  7. [Testing](#testing)
  8. [Contributing](#contributing)
  9. [Changelog](#changelog)
  10. [Notice](#notice)
  11. [License](#license)

# Requirements

  * PicoLisp 32-bit/64-bit `v17.12` to `v20.6.29`, or `pil21`
  * Linux or UNIX-like OS (with support for named pipes)

# Getting Started

This library is written in pure PicoLisp and contains **no external dependencies**.

To ensure everything works on your system, run the tests first: `make check`

### Using the CLI tools

  1. Launch a server with: `./server.l --pass <yourpass> --verbose`
  2. Check the server info with: `./client.l --pass <yourpass> INFO`

That should return some interesting info about your server. See below for more examples.

### Using as a library

**Server**

  1. Load the library in your project: `(load "libkv.l")`
  2. Set the server password: `(setq *KV_pass "yourpass")`
  3. Start listening for requests: `(kv-listen)`

**Client**

  1. Load the client library in your project: `(load "libkvclient.l")`
  2. Set the server password `(setq *KV_pass "yourpass")`
  3. Start the client listener with `(kv-start-client)`
  4. Send your command and arguments with `(kv-send-data '("INFO" "server"))`

Received data will be returned as-is (list, integer, string, etc). Wrap the result like: `(kv-print Result)` to send the output to `STDOUT`:

```
: (load "libkvclient.l")
-> kv-start-client
: (setq *KV_pass "yourpass")
-> "yourpass"
: (kv-start-client)         
-> T
: (kv-send-data '("set" "mykey" 12345))
-> "OK"
: (kv-send-data '("get" "mykey"))      
-> 12345
: (kv-send-data '("set" "yourkey" "12345"))
-> "OK"
: (kv-send-data '("get" "yourkey"))        
-> "12345"
```

Feel free to observe the example code in [client.l](client.l).

> **Note**: Using `(kv-send-data)` will send the data to the server and automatically block the client while waiting for a response.

# Usage

This section describes usage information for the CLI tools `server.l` and `client.l`.

## Server

The server listens in the foreground for TCP connections on port `6378` by default. Only the `password`, `port`, `persistence`, and `verbosity` are configurable, and a `password` is required:

```
# server.l
Usage:                    ./server.l --pass <pass> [options]

Example:                  ./server.l --pass foobared --port 6378 --verbose --persist 60

Options:
--help                    Show this help message and exit

--binary                  Store data in binary format instead of text (default: plaintext)
--pass <password>         Password used by clients to access the server (required)
--persist <seconds>       Number of seconds between database persists to disk (default: disabled)
--port <port>             TCP listen port for communication with clients (default: 6378)
--verbose                 Verbose flag (default: False)
```

### Examples

```
./server.l --pass yourpass --verbose
Parent PID: 38867
[sibling]=38874
[child]=38873 [parent]=38867
[msg] from client: (pid: 38873) ::ffff:127.0.0.1 ("IDENT" ("id" . "3F21CC32") ("hostname" . "meta.lan"))
[msg] from child : (pid: 38873) ("message" 38873 ("IDENT" ("id" . "3F21CC32") ("hostname" . "meta.lan")))
[msg]   to client: "OK 3F21CC32"
[msg] from client: (pid: 38873) ::ffff:127.0.0.1 ("INFO" "server")
[msg] from child : (pid: 38873) ("message" 38873 ("INFO" "server"))
[msg]   to client: "^J# Server^Japp_version:0.11.0^Jos:Linux 4.19.34-tinycore64 x86_64^Jarch_bits:64^Jprocess_id:38874^Jtcp_port:6378^Juptime_in_seconds:1^Juptime_in_days:0^Jexecutable:/usr/bin/picolisp^J"
[child]=38873 exiting
[msg] from child : (pid: 38873) ("done" 38873 NIL)
```

## Client

The client handles authentication, identification, and sending of _"Redis-like"_ commands to the server. It then prints the result to `STDOUT` and can be parsed by standard _*NIX_ tools. The client receives _PLIO_ data over a TCP socket, or named pipe (if client/server are on the same system).

```
# client.l
Usage:                    ./client.l --pass <pass> COMMAND [arguments]

Example:                  ./client.l --pass foobared --encrypt SET mysecret -- <(echo 'mypass')

Options:
--help                    Show this help message and exit
--commands                Show the full list of commands and exit

--decrypt                 Enable decryption of values using a GPG public key (default: disabled)
--encrypt                 Enable encryption of values using a GPG public key (default: disabled)
--name  <name>            Easily identifiable client name (default: randomly generated)
--host  <host>            Hostname or IP of the key/value server (default: localhost)
--pass  <data>            Password used to access the server (required)
--poll  <seconds>         Number of seconds for polling the key/value server (default: don't poll)
--port  <port>            TCP port of the key/value server (default: 6378)
-- STDIN                  Reads an argument from STDIN

COMMAND LIST              Commands are case-insensitive and don't always require arguments

  APPEND key value          		Append a value to a key
  BGSAVE                    		Asynchronously save the dataset to disk
  CLIENT ID                 		Returns the client ID for the current connection
  CLIENT KILL ID id [id ..]    		Kill the connection of a client
  CLIENT LIST               		Get the list of client connections
  CONVERT                   		Convert a plaintext database to binary or vice-versa
  DEL key [key ..]          		Delete a key
  EXISTS key [key ..]       		Determine if a key exists
  GET key                   		Get the value of a key
  GETSET key value          		Set the string value of a key and return its old value
  HDEL key field [field ..]    		Delete one or more hash fields
  HEXISTS key field         		Determine if a hash field exists
  HGET key field            		Get the value of a hash field
  HGETALL key               		Get all the fields and values in a hash
  HKEYS key                 		Get all the fields in a hash
  HLEN key                  		Get the number of fields in a hash
  HMGET key field [field ..]    	Get the values of all the given hash fields
  HSET key field value [field value ..] Set the string value of a hash field
  HSTRLEN key field         		Get the length of the value of a hash field
  HVALS key                 		Get all the values in a hash
  INFO [section]            		Get information and statistics about the server
  LINDEX key index          		Get an element from a list by its index
  LLEN key                  		Get the length of a list
  LPOP key                  		Remove and get the first element in a list
  LPOPRPUSH source destination    	Remove the first element in a list, append it to another list and return it
  LPUSH key element [element ..]    	Prepend one or multiple elements to a list
  LRANGE key start stop     		Get a range of elements from a list
  LREM key count element    		Remove elements from a list
  LSET key index element    		Set the value of an element in a list by its index
  LTRIM key start stop      		Trim a list to the specified range
  MGET key [key ..]         		Get the values of all the given keys
  MSET key value [key value ..]    	Set multiple keys to multiple values
  PING [message]            		Ping the server
  RPOP key                  		Remove and get the last element in a list
  RPOLRPUSH source destination    	Remove the last element in a list, prepend it to another list and return it
  RPUSH key element [element ..]    	Append one or multiple elements to a list
  SAVE                      		Synchronously save the dataset to disk
  SET key value             		Set the string value of a key
  STRLEN key                		Get the length of the value stored in a key
```

# Notes and limitations

This section will explain some important technical details about the code, and limitations on what this library can and can't do.

## Technical notes

  * All keys are stored under the prefix `*KV/`, example: `*KV/mykeys`. This prefix is hardcoded everywhere and shouldn't be changed.
  * Requests and commands generate statistics which are stored in memory (and lost when the server exits). Statistics are stored under the `*KV/%stats%/` prefix and are _read-only_ by external clients.
  * Similar to the [WebSockets protocol](https://tools.ietf.org/html/rfc6455#section-1.3), a unique UUID: `7672FDB2-4D29-4F10-BA7C-8EAD0E29626E` is used during the handshake sequence between all clients and servers. For compatibility with future tools, please do not change it.
  * Passwords are hashed using a very simple and collision-prone hashing function. It is not cryptographically secure or used for that purpose. If using this library over a public network, please use [stunnel](https://www.stunnel.org/) or [hitch](https://github.com/varnish/hitch) as a TLS proxy between the client and server.
  * Output from the `client.l` uses `(prinl)`, so a result `"2"` and `2` will both appear the same. Lists are concatenated with a `,` comma and also output using `(prinl)`. Error messages are sent to `STDERR` and the client exits with error code `1`.
  * Named pipes are created in the `(tmp)` directory of the server's parent process, and will be removed when the parent **exits cleanly**. Please do not kill the parent process with `kill -9` (or `kill -KILL`) as it will leave an unresponsive zombie sibling with the TCP socket still open, and the named pipes will not be removed.
  * A best effort has been made to return the same datatypes and response types as _Redis_. Example: the `SET` command returns `OK` if the key was set. Not all responses are absolutely identical to _Redis_ though. Please remember this library isn't designed to be a perfect clone of _Redis_ (see Limitations below).

## Limitations

  * This library is not used in production and has not been tested extensively (despite all the unit/integration tests). Please use at your own risk.
  * This library **DOES NOT** use the [RESP protocol](https://redis.io/topics/protocol) and thus cannot work with the `redis-cli` or other _Redis_ clients.
  * Since PicoLisp is not _event-based_, each new TCP connection spawns a new process, which limits concurrency to the host's available resources.
  * Not all [Redis commands](https://redis.io/commands) are implemented, because I didn't have an immediate need for them. There are plans to slowly add new commands as the need arises.
  * Using the `client.l` on the command-line, all values are stored as strings. Please use the TCP socket or named pipe directly to store integers and lists.
  * ~~Unlike _Redis_, there is no on-disk persistence and **all keys will be lost** when the server is restarted. This library was originally designed to be used as a temporary FIFO queue, with no need to persist the data. Support for persistence can be added eventually, and I'm open to pull-requests.~~ Support for persistence has been added, see [Persistence](#persistence) below.

# How it works

For the server, everything starts with the `(kv-listen)` function, which is where the TCP server is started:

```text
+------------+   +---------------------+    +----------------+
| TCP client |   | (parent)            |    | (sibling)      |
+-----+---+--+   |    +-------------+  |    | +------------+ |
      ^   |      |    | TCP server  |  |    | | Key/Value  | |
      |   +---------> | (kv-listen) |  |    | | in-memory  | |
      |          |    +-------------+  |    | |     DB     | |
      |          |                     |    | +------------+ |
+-----+-------------> pipe_sibling +------> |                |
|                |                     |    +-+-+-+----------+
|  +--------+    |                     |      | | |
+--+ child1 | <-----+ pipe_child_1 <----------+ | |
|  +--------+    |                     |        | |
|                |                     |        | |
|  +--------+    |                     |        | |
+--+ child2 | <-----+ pipe_child_2 <------------+ |
|  +--------+    |                     |          |
|                |                     |          |
|  +--------+    |                     |          |
+--+ child3 | <-----+ pipe_child_3 <--------------+
   +--------+    |                     |
                 +---------------------+
```

Once `(kv-listen)` is running, a TCP socket is opened on the configured port. An infinite loop begins and listens for incoming connections, giving each new TCP client its own forked child process for handling the request.

A named pipe called `pipe_sibling`, is created in a temporary directory of the top-level **parent** process. This pipe will be used to communicate with other **child** processes, leaving the parent process to continue serving new TCP requests.

The parent process then forks another process, which we'll call the **sibling** - an older sister if you prefer - and the sibling waits on the `pipe_sibling` named pipe, listening for _COMMANDS_ from the child processes.

The forked child processes will each create their own named pipe, called `pipe_child_<pid>`, also in a temporary directory of the top-level **parent** process. The child process will listen on its own named pipe for messages sent by its older sister, the **sibling**. Once a message is received by the child, the response is sent back to the **client** over the TCP connection.

The idea is to have the **sibling** be the holder of all the **keys**. Every _"Redis-like"_ command will have their data and statistics stored in the memory of the **sibling** process, and the **sibling** will handle receiving and sending its memory contents (keys/values) through named pipes to the respective **child** processes.

# Persistence

Similar to [Redis](https://redis.io/topics/persistence), this database implements "snapshotting" (full memory dump to disk) and "AOF" (append-only log file), however both features are tightly coupled, which makes for a much better experience.

  * Persistence is disabled by default, but can be enabled with the `--persist N` parameter, where `N` is the number of seconds between each `BGSAVE` (background save to disk).
  * The database is stored in plaintext by default, but can be stored in binary with the `--binary` parameter. Binary format (PLIO) loads and saves _much_ quicker than plaintext, but it becomes difficult to debug a corrupt entry.
  * The AOF follows the _WAL_ approach, where each write command is first written to the AOF on disk, and then processed in the key/value memory store.
  * The AOF only stores log entries since the previous `SAVE` or `BGSAVE`, so it technically shouldn't grow too large or unmanageable.
  * The database snapshot on disk is the most complete and important data, and should be backed up regularly.
  * _fsync_ is not managed by the database, so the server admin must ensure AOF log writes are actually persisted to disk.
  * The AOF on-disk format is **always plaintext**, to allow easy debugging and repair of a corrupt entry.
  * The `SAVE` and `BGSAVE` commands can still be sent even if persistence is disabled. This will dump the in-memory data to disk as if persistence was enabled.

## How persistence is implemented

Here we'll assume persistence was previously enabled and data has already been written and saved to disk.

  1. On server start, some memory is pre-allocated according to the DB's file size.
  2. The DB is then fully restored to memory
  3. If the AOF contains some entries, it is fully replayed to memory
  4. The DB is saved once more to disk and the AOF gets wiped
  5. A timer is started to perform periodic background DB saves
  6. Every new client connection sends the command to the AOF
  7. When a `BGSAVE` (non-blocking) command is received, a temporay copy of the AOF is made, the current AOF is wiped, and a background process is forked to save the DB to disk
  8. A backup of the DB file is always made before overwriting the current DB file.
  9. To help handle concurrency and persistence, temporary files are named `kv.db.lock`, `kv.db.tmp`, `kv.aof.lock`, and `kv.aof.tmp`. It's best not to modify or delete those files while the server is running. They can be safely removed while the server is stopped.

## AOF format

The AOF is stored by default in the `kv.aof` file as defined by `*KV_aof`.

Here are two separate entries in a typical AOF:

```
("1596099036.281142829" 54042 ("RPUSH" "mytestlist" ("four" "five" "six")))
("1596099059.683596840" 57240 ("RPUSH" "yourtestlist" ("seven" "eight" "nine")))
```

Each line is a PicoLisp list with only 3 items:

  * Item 1: `String` Unix timestamp with nanoseconds for when the entry was created
  * Item 2: `Integer` Non-cryptographically secure hash (CRC) of the command and its arguments
  * Item 3: `List` Command name, first argument, and subsequent arguments

When replaying the AOF, the server will ensure the hash of command and arguments match, to guarantee the data is intact. Replaying an AOF can be slow, depending on the number of keys/values.

> **Note:** Manually modifying the AOF will require recomputing and replacing the hash with the result from `(kv-hash)` or PicoLisp `(hash)`.

```
(hash '("RPUSH" "mytestlist" ("four" "five" "zero")))
-> 61453
```

## DB format

The DB is stored by default in the `kv.db` file as defined by `*KV_db`. When backed up, the new filename contains the suffix `.old`.

Here are two separate entries in a typical DB:

```
("smalldata" ("test1" "test2" "test3" "test4" "test5" "test6"))
("fooh_1000" "test data 1000")
```

Each line is a PicoLisp list with the key in the `(car)`, and values in the `(cadr)`. They are quickly replayed and stored in memory with a simple `(set)` command.

## Differences from Redis

  * Unlike _Redis_, persistence only allows specifying a time interval between each `BGSAVE`. Since the AOF is **always enabled**, it's not necessary to "save after N changes", so the config is much simpler.
  * Log rewriting is not something that "must be done", because chances are the AOF will never grow too large. Of course that depends on the number of changes occurring between each `BGSAVE`, but even then the AOF is wiped when a `BGSAVE` is initiated (and restored/rewritten if there was an error).
  * The DB snapshot is used to reconstruct the dataset in memory, not the AOF. The AOF is only used to replay the commands since the last DB save, which is much faster and more efficient, particularly when using `--binary`.
  * There is no danger of _losing data_ when switching from `RDB` to `AOF`, because such a concept doesn't even exist.

# Testing

This library comes with a large suite of [unit and integration tests](https://github.com/aw/picolisp-unit). To run the tests, type:

    make check

![Test results](https://user-images.githubusercontent.com/153401/84755116-cb694480-afb0-11ea-9dcf-9b49750df423.png)

# Contributing

  * If you find any bugs or issues, please [create an issue](https://github.com/aw/picolisp-kv/issues/new).
  * If you want to request support for **new features**, please consider adding them yourself (if possible) and submitting a pull-request.
  * For pull-request submissions, please follow a similar coding style as this library, and include full unit and integration tests for your new commands or features, as well as updated documentation in this [README.md](README.md).
  * Additions which require 64-bit functionality (ex: `(native)`) should conditionally check for OS support.
  * Please try to limit code lines to 120 columns and indent comments at column 64. Of course it's acceptable to go over.

# Changelog

[Changelog](CHANGELOG.md)

# Notice

* Redis is a trademark of Redis Labs Ltd. Any rights therein are reserved to Redis Labs Ltd. Any use by me is for referential purposes only and does not indicate any sponsorship, endorsement or affiliation between Redis and me.

# License

[MIT License](LICENSE)

Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>
