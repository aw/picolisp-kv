# picolisp-kv - https://github.com/aw/picolisp-kv
#
# Client library to be included in other PicoLisp tools
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

(seed (in "/dev/urandom" (rd 20)))

# CONSTANTS
(setq
  *KV_host      "localhost"
  *KV_clientid  (hex (abs (rand)))
  *KV_port      6378
  *KV_pass      NIL
  *KV_abort     60                                       # max time (in seconds) to wait for a message
  *KV_uuid      "7672FDB2-4D29-4F10-BA7C-8EAD0E29626E"   # for server handshake, do not change
  *KV_gpgid     "secrets/gpg-id" )                       # key name containing the GPG ID used to encrypt data

(off *KV_poll)

# HELPERS
# Send error message to STDERR
[de kv-throw (Error)
  (out 2 (prinl Error))
  (setq *Msg Error)
  (throw 'kv-error Error) ]

# Send output to STDOUT
[de kv-print (Result)
  (cond
    ((lst? Result)  (prinl (glue "," Result)))
    (T              (prinl Result) ]

# Non cryptographically secure hash, can be changed in the future
[de kv-hash (String)
  (hash String) ]

# Encrypt a string from STDIN using GPG, with one recipient
[de kv-encrypt-gpg (String Id)
  (pipe
    (out (list 'gpg "-v" "--output" "-" "--yes" "-a" "--encrypt" "-r" Id)
      (prin String) )
    (till NIL T) ]

# Decrypt a string using GPG
[de kv-decrypt-gpg (String)
  (pipe
    (out (list 'gpg "-q" "--decrypt" "--yes")
      (prin String) )
    (till NIL T) ]

[de kv-encrypt-getid (Args)
  (case (length Args)
    (3    (member (car Args) '("APPEND" "GETSET" "LPUSH" "MSET" "RPUSH" "SET")))
    (4    (member (car Args) '("HSET" "LSET"))) )
  (and
    @
    (kv-send-commands (list "GET" (list *KV_gpgid)))
    (kv-receive) ]

[de kv-encrypt (Args)
  (if (and
        (cdr (kv-encrypt-getid Args))
        (kv-send-commands (place (length Args) Args (kv-encrypt-gpg (last Args) @))) )
      (kv-receive-data)
      "unable to send encrypted data" ]

# IPC
# Send commands to the server on the TCP socket
[de kv-send-commands (Cmdargs)
  (out *Sock (pr (list (uppc (pop 'Cmdargs)) Cmdargs) ]

# Send commands to the server and receive a response
[de kv-send-data (Cmdargs)
  (if *KV_encrypt
      (kv-encrypt Cmdargs)
      (if (kv-send-commands Cmdargs)
          (if *KV_decrypt
              (kv-decrypt-gpg (kv-receive-data))
              (kv-receive-data) )
          "unable to send data" ]

# Receive data from the server on the TCP socket, return the result or NIL
[de kv-receive ()
  (abort *KV_abort (in *Sock (when (rd) @) ]

# Receive data from the server on the TCP socket, return the parsed result
[de kv-receive-data ()
  (abort *KV_abort
    (in *Sock
      (when (rd)
        (let Result @
          (if (cdr Result)
              (case (car Result)
                ("message" (cdr Result))                         # good response from the server
                (T         "unknown data"))                      # bad response from the server
              "no data" ) ]                                      # NIL response from the server

# Authenticate to the server by hashing the password and validating the response
[de kv-authenticate ()
  (out *Sock (pr (list "AUTH" *KV_clientid (kv-hash *KV_pass))))
  (let Auth (kv-receive)
    (case (car Auth)
      ("auth"     (if (= (cdr Auth) (kv-hash (pack *KV_clientid *KV_uuid)))
                        (kv-receive-data)
                        (kv-throw "ERROR: bad auth") ) )
      ("error"    (kv-throw (pack "ERROR: " (cdr Auth))))
      (T          (kv-throw "ERROR: unknown response from server") ]

# Open a TCP socket and connect to the server
[de kv-start-client ()
  (setq *Sock (connect *KV_host *KV_port))
  (if *Sock
      (kv-authenticate)
      (kv-throw "ERROR: could not connect to server") ]
