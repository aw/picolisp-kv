
# List of commands

Most `COMMANDS` take the exact same arguments, and return the same type of value, as their respective [Redis™ commands](https://redis.io/commands).

| Command | Description |
| ---- | ---- |
| [APPEND](#append) key value | Append a value to a key |
| [BGSAVE](#bgsave) | Asynchronously save the dataset to disk |
| [CLIENT ID](#client-id) | Returns the client ID for the current connection |
| [CLIENT KILL ID](#client-kill-id) id [id ..] | Kill the connection of a client |
| [CLIENT LIST](#client-list) | Get the list of client connections |
| [CONVERT](#convert) | Convert a plaintext database to binary or vice-versa |
| [DEL](#del) key [key ..] | Delete one or more keys |
| [EXISTS](#exists) key [key ..] | Determine if a key exists |
| [GET](#get) key | Get the value of a key |
| [GETSET](#getset) key value | Set the string value of a key and return its old value |
| [HDEL](#hdel) key field [field ..] | Delete one or more hash fields |
| [HEXISTS](#hexists) key field | Determine if a hash field exists |
| [HGET](#hget) key field | Get the value of a hash field |
| [HGETALL](#hgetall) key | Get all the fields and values in a hash |
| [HKEYS](#hkeys) key | Get all the fields in a hash |
| [HLEN](#hlen) key | Get the number of fields in a hash |
| [HMGET](#hmget) key field [field ..] | Get the values of all the given hash fields |
| [HSET](#hset) key field value [field value ..] | Set the string value of a hash field |
| [HSTRLEN](#hstrlen) key field | Get the length of the value of a hash field |
| [HVALS](#hvals) key | Get all the values in a hash |
| [INFO](#info) [section] | Get information and statistics about the server |
| [LINDEX](#lindex) key index | Get an element from a list by its index |
| [LLEN](#llen) key | Get the length of a list |
| [LPOP](#lpop) key | Remove and get the first element in a list |
| [LPOPRPUSH](#lpoprpush) source destination | Remove the first element in a list, append it to another list and return it |
| [LPUSH](#lpush) key element [element ..] | Prepend one or multiple elements to a list |
| [LRANGE](#lrange) key start stop | Get a range of elements from a list |
| [LREM](#lrem) key count element | Remove elements from a list |
| [LSET](#lset) key index element | Set the value of an element in a list by its index |
| [LTRIM](#ltrim) key start stop | Trim a list to the specified range |
| [MGET](#mget) key [key ..] | Get the values of all the given keys |
| [MSET](#mset) key value [key value ..] | Set multiple keys to multiple values |
| [PING](#ping) [message] | Ping the server |
| [RPOP](#rpop) key | Remove and get the last element in a list |
| [RPOLRPUSH](#rpolrpush) source destination | Remove the last element in a list, prepend it to another list and return it |
| [RPUSH](#rpush) key element [element ..] | Append one or multiple elements to a list |
| [SAVE](#save) | Synchronously save the dataset to disk |
| [SET](#set) key value | Set the string value of a key |
| [STRLEN](#strlen) key | Get the length of the value stored in a key |


## APPEND

#### APPEND key value

If key already exists and is a string, this command appends the value at the end of the string.

#### Return values

  * **Integer**: the length of the string after the append operation
  * **NIL**: if key is not a string or does not exist

#### CLI example

```bash
./client.l --pass yourpass EXISTS mykey
0
./client.l --pass yourpass SET mykey "Hello"
OK
./client.l --pass yourpass APPEND mykey " World"
11
./client.l --pass yourpass GET mykey
Hello World
```

#### PicoLisp example

```picolisp
: (kv-send-data '("EXISTS" "mykey"))
-> 0
: (kv-send-data '("SET" "mykey" "Hello"))
-> "OK"
: (kv-send-data '("APPEND" "mykey" " World"))
-> 11
: (kv-send-data '("GET" "mykey"))
-> "Hello World"
: (kv-send-data '("APPEND" "doesntexist" "test"))
-> NIL
```

## BGSAVE

#### BGSAVE

Save the DB in background.

The KV server forks, the parent continues to serve the clients, the child saves the DB
on disk then exits.

An error is returned if there is already a background save running or if there is another non-background-save process running.

#### Return values

  * **String**: `Background saving started` if the `BGSAVE` started correctly or `Error: DB is locked for writing` if the DB is locked.

#### CLI example

```bash
./client.l --pass yourpass BGSAVE
Background saving started
```

#### PicoLisp example

```picolisp
: (kv-send-data '("BGSAVE"))
-> "Background saving started"
```
## CLIENT ID

#### CLIENT ID

The command just returns the ID of the current connection. Every connection ID has certain guarantees:

  1. It is never repeated, so if `CLIENT ID` returns the same number, the caller can be sure that the underlying client did not disconnect and reconnect the connection, but it is still the same connection.
  2. The ID is monotonically incremental. If the ID of a connection is greater than the ID of another connection, it is guaranteed that the second connection was established with the server at a later time.

#### Return values

  * **Integer**: The id of the client.

#### CLI example

```bash
./client.l --pass yourpass CLIENT ID
1
./client.l --pass yourpass CLIENT ID
2
```

#### PicoLisp example

```picolisp
: (kv-send-data '("CLIENT" "ID"))
-> 3
```

## CLIENT KILL ID

#### CLIENT ID id [id ..]

The command allows to end one or more client connections by their unique `ID` field.

#### Return values

  * **String**: the number of clients connections ended.

#### CLI example

```bash
./client.l --pass yourpass CLIENT KILL ID 2
1
```

#### PicoLisp example

```picolisp
: (kv-send-data '("CLIENT" "KILL" "ID" "2"))
-> 0
```

## CLIENT LIST

#### CLIENT LIST

Returns information and statistics about the client connections server in a mostly human readable format.

The KV server forks, the parent continues to serve the clients, the child saves the DB
on disk then exits.

An error is returned if there is already a background save running or if there is another non-background-save process running.

#### Return values

  * **Multi-line String**: a unique string, formatted as follows:
    * One client connection per line (separated by `\n` newline/linefeed)
    * Each line is composed of a succession of `property=value` fields separated by a space character.

Here is the meaning of the fields:

* `id`: an unique auto-incrementing 64-bit client ID
* `pid`: process ID of the forked child handling the request
* `name`: name set by the client, with `--name` or autogenerated
* `addr`: address of the client
* `port`: source port of the client
* `fd`: file descriptor corresponding to the socket

#### CLI example

```bash
./client.l --pass yourpass CLIENT LIST
id=1 pid=16929 name=4AF35825 addr=::1 port=49774 fd=7
```

#### PicoLisp example

```picolisp
: (kv-send-data '("CLIENT" "LIST"))
-> "id=2 pid=10019 name=79738D13 addr=::1 port=50956 fd=7"
```

## CONVERT

#### CONVERT

Convert a plaintext database to binary or vice-versa.

The KV server by default saves data on disk in plaintext format, which can be modified by hand by anyone with practically no PicoLisp knowledge. The disadvantage with plaintext is its on-disk footprint is quite large compared to binary. For small datasets the difference is negligible, but it could also affect performance when first loading the database.

While the server is running, it is possible to dump the database to disk using a different format, for example: if it's currently saving in plaintext, `CONVERT` will dump it to disk in binary. All future saves will also be in binary until the server is restarted, or until another `CONVERT` command is sent (which would convert it back to plaintext).

Using the CLI tool:

  * The default filename for binary format is `kv.bin`.
  * The default filename for plaintext format is `kv.db`.

Using the PicoLisp library:

The database filename can be changed through the `*KV_db` variable, example `(setq *KV_db "/path/to/db.bin")`

  * To enable `binary` saving in PicoLisp, use `(on *KV_binary)`
  * To disable `binary` saving in PicoLisp, use `(off *KV_binary)`

#### Return values

  * **String**: `OK` if the database was converted successfully.

#### CLI example

```bash
./client.l --pass yourpass CONVERT
OK
```

#### PicoLisp example

```picolisp
: (kv-send-data '("CONVERT"))
-> "OK"
```

## DEL

#### DEL key [key ..]

Removes the specified keys. All given keys are removed whether they exist or not.

#### Return values

  * **Integer**: The number of keys that were removed.

#### CLI example

```bash
./client.l --pass yourpass SET key1 "Hello"
OK
./client.l --pass yourpass SET key2 "World"
OK
./client.l --pass yourpass DEL key1 key2 key3
3
```

#### PicoLisp example

```picolisp
: (kv-send-data '("SET" "key1" "Hello"))
-> "OK"
: (kv-send-data '("SET" "key2" "World"))
-> "OK"
: (kv-send-data '("DEL" "key1" "key2" "key3"))
-> 3
```

# License

This documentation copies in part the [Redis documentation](https://github.com/redis/redis-io), distributed under the [Creative Commons Attribution-ShareAlike 4.0 International license](https://creativecommons.org/licenses/by-sa/4.0/) license, and is modified to match the [PicoLisp KV](https://github.com/aw/picolisp-kv) library code.

This documentation is licensed under [Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/).

Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>
