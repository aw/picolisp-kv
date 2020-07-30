# Redis-inspired key/value store written in PicoLisp

This program mimics functionality of a [Redis](https://redis.io) in-memory database, but is designed specifically for [PicoLisp](https://picolisp.com) applications with optional on-disk persistence.

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
  10. [License](#license)

# Requirements

  * PicoLisp 32-bit/64-bit `v17.12` to `v20.6.29`
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

Example:                  ./client.l --pass foobared --port 6378 INFO server

Options:
--help                    Show this help message and exit

--name <name>             Easily identifiable client name (default: randomly generated)
--host  <host>            Hostname or IP of the key/value server (default: localhost)
--pass  <data>            Password used to access the server (required)
--poll  <seconds>         Number of seconds for polling the key/value server (default: don't poll)
--port  <port>            TCP port of the key/value server (default: 6378)

COMMAND LIST              Commands are case-insensitive and don't always require arguments.
                                  Examples:

BGSAVE                  		BGSAVE
CLIENT ID|KILL|LIST id [id ..]    	CLIENT LIST
CONVERT                 		CONVERT
DEL key [key ..]        		DEL key1 key2 key3
EXISTS key [key ..]     		EXISTS key1 key2 key3
GET key                 		GET key1
GETSET key value        		GETSET mykey hello
INFO [section]          		INFO memory
LINDEX key index        		LINDEX mylist 0
LLEN key                		LLEN mylist
LPOP key                		LPOP mylist
LPOPRPUSH source destination    	LPOPRPUSH mylist myotherlist
PING [message]          		PING hello
RPUSH key element [element ..]    	RPUSH mylist task1 task2 task3
SAVE                    		SAVE
SET key value           		SET mykey hello
```

Most `COMMANDS` take the exact same arguments as their respective [Redis commands](https://redis.io/commands).

### Examples

```
# Obtain information about the server
./client.l --pass yourpass INFO server
OK 37D13779

# Server
app_version:0.11.0
os:Linux 4.19.34-tinycore64 x86_64
arch_bits:64
process_id:38874
tcp_port:6378
uptime_in_seconds:1
uptime_in_days:0
executable:/usr/bin/picolisp

# Set a key
./client.l --pass yourpass SET mykey myvalue
OK 53E02FC6
OK

# Get a key
./client.l --pass yourpass GET mykey
OK 40E83305
myvalue

# Get a key, then set it
./client.l --pass yourpass GETSET mykey yourvalue
OK 69E88646
myvalue

# Check if a key exists
./client.l --pass yourpass EXISTS mykey
OK 43BFA2C
1

# Delete a key
./client.l --pass yourpass DEL mykey
OK 4C2B6088
1

./client.l --pass yourpass GET mykey
OK 11242B95
no data

./client.l --pass yourpass EXISTS mykey
OK 5F1E8D78
0

# Add multiple values to a key (a list)
./client.l --pass yourpass --name 11242B95 RPUSH mylist task1 task2 task3
OK 11242B95
3

./client.l --pass yourpass RPUSH mylist task4 task5
OK 4E7E0FC3
5

# Left pop a value from the head of a list
./client.l --pass yourpass LPOP mylist
OK 258514BF
task1

# Check how many values are in a key (a list)
./client.l --pass yourpass LLEN mylist
OK 107CF205
4

# Left pop a value from the head of a list, push it to the tail of another list
./client.l --pass yourpass LPOPRPUSH mylist mynewlist
OK 46028880
task2

# Get the value of a key (a list) using a zero-based index
./client.l --pass yourpass LINDEX mynewlist -1
OK 129AE0F8
task2

# Ping the server
./client.l --pass yourpass PING
OK 6DCE69EB
PONG

# Ping the server with a custom message
./client.l --pass yourpass PING "Hello"
OK 6F02D9DC
Hello

# Save the database in the foreground (blocking)
./client.l --pass yourpass SAVE
OK 1F60EABE
OK

# Save the database in the background (non-blocking)
./client.l --pass yourpass BGSAVE
OK 1270937D
Background saving started

# Convert the database from plaintext to binary, or binary to plaintext
./client.l --pass yourpass CONVERT
OK 25E3B970
OK

# Get the list of connected clients
./client.l --pass yourpass CLIENT LIST
OK 6FC82046
id=2 pid=26377 name=6FC82046 addr=::1 fd=7
id=1 pid=26370 name=783EABE1 addr=::1 fd=7

# Get the current client ID
./client.l --pass yourpass CLIENT ID
OK 105ECBFE

# Stop and kill a client connection
./client.l --pass yourpass CLIENT KILL ID 1
OK 32CA1C8A
1
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
  * The AOF is opened for writing when the server is started, and closed only when the server is stopped (similar to web server log files). This lowers overhead of appending to the log, but requires care to avoid altering it while the server is running.
  * The `SAVE` and `BGSAVE` commands can still be sent even if persistence is disabled. This will dump the in-memory data to disk as if persistence was enabled.

## How persistence is implemented

Here we'll assume persistence was previously enabled and data has already been written and saved to disk.

  1. On server start, some memory is pre-allocated according to the DB's file size.
  2. The DB is then fully restored to memory
  3. If the AOF contains some entries, it is fully replayed to memory
  4. The DB is saved once more to disk and the AOF gets wiped
  5. A timer is started to perform periodic background DB saves
  6. The AOF is opened for writes, and every new client connection sends the command to the AOF
  7. When a `BGSAVE` (non-blocking) command is received, a temporay copy of the AOF is made, the current AOF is wiped, and a background process is forked to save the DB to disk
  8. When a `SAVE` (blocking) command is received, the in-memory DB is saved to disk and the AOF is wiped.
  9. A backup of the DB file is always made before overwriting the current DB file.
  10. To help handle concurrency and persistence, temporary files are named `.kv.db.lock`, `.kv.db.tmp`, `.kv.aof.lock`, and `.kv.aof.tmp`. It's best not to modify or delete those files while the server is running. They can be safely removed while the server is stopped.

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

The DB is stored by default in the `kv.db` file as defined by `*KV_db`. When backed up, it is named `.kv.db.old`.

Here are two separate entries in a typical DB:

```
("smalldata" ("test1" "test2" "test3" "test4" "test5" "test6"))
("fooh_1000" "test data 1000")
```

Each line is a PicoLisp list with the key in the `(car)`, and values in the `(cadr)`. They are quickly replayed and stored in memory with a simple `(set)` command.

## Differences from Redis

  * Unlike _Redis_, persistence only allows specifying a time interval between each `BGSAVE`. Since the AOF is **always enabled**, it's not necessary to "save after N changes", so the config is much simpler.
  * Log rewriting is not something that "must be done", because chances are the AOF will never grow too large. Of course that depends on the number of changes occurring between each `BGSAVE`, but even then the AOF is wiped when a `BGSAVE` is initiated (and restored/rewritten if the DB happened to be locked).
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
  * Please try to limit code lines to 80 columns and indent comments at column 42. Of course it's acceptable to go over.

# Changelog

[Changelog](CHANGELOG.md)

# License

[MIT License](LICENSE)

Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>
