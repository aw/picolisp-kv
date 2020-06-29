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
  *KV_uuid      "7672FDB2-4D29-4F10-BA7C-8EAD0E29626E" ) # for server handshake

(off *KV_poll)                           # disable polling by default

# LOAD
(load "module.l")

# HELPERS
# Send error message to STDERR
[de kv-throw (Error)
  (msg Error)
  (setq *Msg Error)
  (throw 'kv-error Error) ]

# Send output to STDOUT
[de kv-print (Result)
  (cond
    ((lst? Result)  (prinl (glue "," Result)))
    (T              (prinl Result) ]

[de kv-hash (String)
  (hash String) ]                        # non cryptographically secure hash

# IPC
# Send commands to the server on the TCP socket
[de kv-send-commands (Cmdargs)
  (case (uppc (pop 'Cmdargs))
    ["BGSAVE"     (out *Sock (pr (list "BGSAVE") ]
    ["DEL"        (out *Sock (pr (list "DEL" (pop 'Cmdargs) Cmdargs) ]
    ["GET"        (out *Sock (pr (list "GET" (pop 'Cmdargs) ]
    ["IDENT"      (out *Sock (pr (append (list "IDENT") Cmdargs) ]
    ["INFO"       (out *Sock (pr (list "INFO" (pop 'Cmdargs) ]
    ["LINDEX"     (out *Sock (pr (list "LINDEX" (pop 'Cmdargs) (format (pop 'Cmdargs) ]
    ["LLEN"       (out *Sock (pr (list "LLEN" (pop 'Cmdargs) ]
    ["LOLWUT"     (out *Sock (pr (list "LOLWUT" (format (pop 'Cmdargs) ]
    ["LPOP"       (out *Sock (pr (list "LPOP" (pop 'Cmdargs) ]
    ["LPOPRPUSH"  (out *Sock (pr (list "LPOPRPUSH" (pop 'Cmdargs) (pop 'Cmdargs) ]
    ["RPUSH"      (out *Sock (pr (list "RPUSH" (pop 'Cmdargs) Cmdargs) ]
    ["SAVE"       (out *Sock (pr (list "SAVE") ]
    ["SET"        (out *Sock (pr (list "SET" (pop 'Cmdargs) (pop 'Cmdargs) ]
    [T            (setq *Bye '((msg "ERROR: unknown command"))) (bye 1) ] ) ]

# Send commands to the server and receive a response
[de kv-send-data (Cmdargs)
  (when (kv-send-commands Cmdargs)
        (kv-receive-data) ]              # receive data from the server

# Receive data from the server on the TCP socket, return the result or NIL
[de kv-receive ()
  (in *Sock
    (when (rd) @ ] # response from the server, good or bad

# Receive data from the server on the TCP socket, return the parsed result
[de kv-receive-data ()
  (in *Sock
    (when (rd)
      (let Result @
        (if (cdr Result)
            (case (car Result)
              ("message" (cdr Result))   # good response from the server
              (T         "unknown data"))# bad response from the server
            "no data" ) ]                # NIL response from the server

# Send client identity command to the server with a variable number of arguments
[de kv-identify @
  (kv-send-data
    (append
      (list "IDENT"
        (cons "id" *KV_clientid)
        (cons "hostname" (in '(hostname) (line T))) )
      (make (while (rest) (link (cons (next) (next) ]

# Authenticate to the server by hashing the password and validating the response
[de kv-authenticate ()
  (out *Sock (pr (list "AUTH" *KV_clientid (kv-hash *KV_pass))))
  (in *Sock
    (if (and (rd) (= (cdr @) (kv-hash (pack *KV_clientid *KV_uuid))))
            T
            (kv-throw "ERROR: bad auth") ]

# Open a TCP socket and connect to the server
[de kv-start-client ()
  (setq *Sock (connect *KV_host *KV_port))
  (if *Sock
      (kv-authenticate)                  # perform initial handshake and auth
      (kv-throw "ERROR: could not connect to server") ]
