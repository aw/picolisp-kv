# Perform some tasks when the child exits
[de kv-child-exit ()
  (kv-output "[child]=" *Pid " exiting")
  (kv-out-sibling "done")
  (when (info *Pipe_child) (call 'rm "-f" *Pipe_child)) ]

# Receive a message from a sibling over a named pipe and send it to the client
[de kv-listen-child ()
  (in *Pipe_child
    (when (rd) (kv-out-client "message" (cdr @) ]

# Send a message to the sibling over a named pipe
[de kv-out-sibling (Type . @)
  (wait 1)                                                     # required or messages get lost
  (out *Pipe_sibling
    (pr (list Type *Pid (car (rest) ]

# Receive a message from the client over the TCP socket
[de kv-listen-sock ()
  (in *Sock
    (while (rd)
      (let Msg @
        (kv-output "[msg] from client: (pid: " *Pid ") " *Adr " " (sym Msg))
        (kv-out-sibling "message" Msg)
        (kv-listen-child) ]

# Send a message to the client over a TCP socket
[de kv-out-client (Type Msg)
  (out *Sock (pr (cons Type Msg) ]

# non cryptographically secure hash, can be changed in the future
[de kv-hash (String)
  (hash String) ]

# Authenticate the client via handshake, and authorizate with a hashed password
[de kv-auth (Auth)
  (and
    (lst? Auth)
    (= "AUTH" (car Auth))
    (= (kv-hash *KV_pass) (caddr Auth))
    (kv-out-client "AUTH" (kv-hash (pack (cadr Auth) *KV_uuid)))
    (kv-out-sibling "message" (list "IDENT" (cons "name" (cadr Auth)) (cons "addr" *Adr) (cons "fd" *Sock)))
    (kv-listen-child) ]

# Receive the initial auth in a child process from the client over a TCP socket
[de kv-child ()
  (kv-output "[child]=" *Pid " [parent]=" *PPid)
  (kv-mkfifo "child")

  (in *Sock
    (if (kv-auth (rd))
        (kv-listen-sock)
        (kv-out-sibling "error" "NOAUTH")                      # auth NOT OK, tell the sibling
        (kv-out-client "error" "NOAUTH") ]                     # auth NOT OK, tell the client
