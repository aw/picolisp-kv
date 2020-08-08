
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
| [DEL](#del) key [key ..] | Delete a key |
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

  * **String**: `Background saving started` if the `BGSAVE` started correctly or `Error: DB is locked for writing` is the DB is locked.

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
# License

This documentation copies in part the [Redis documentation](https://github.com/redis/redis-io), distributed under the [Creative Commons Attribution-ShareAlike 4.0 International license](https://creativecommons.org/licenses/by-sa/4.0/) license, and is modified to match the [PicoLisp KV](https://github.com/aw/picolisp-kv) library code.

This documentation is licensed under [Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/).

Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>
