# picolisp-kv - https://github.com/aw/picolisp-kv
#
# Command-line tool helpers
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

### HELPERS
[de kv-options (N)
  (tab  (2 -22 5) " " (car N) (cdr N) ]

[de kv-show-commands ()
  (kv-show-header)
  (prinl
    (mapcar kv-options (cdr (assoc "commands" APP_HELP) ]

[de kv-show-header ()
  (prinl
    (cdr (assoc "name" APP_INFO)) " v" (cdr (assoc "version" APP_INFO)) "^J"
    "Copyright " (cdr (assoc "copyright" APP_INFO)) "^J"
    (cdr (assoc "source" APP_INFO)) "^J"
    "License " (cdr (assoc "license" APP_INFO)) "^J^J"
    (cdr (assoc "summary" APP_INFO)) "^J" ]

[de kv-show-help ()
  (kv-show-header)
  (prinl
    (kv-options (list "Usage:" (cdr (assoc "usage" APP_HELP)))) "^J"
    (kv-options (list "Example:" (cdr (assoc "example" APP_HELP))))
    (kv-options (list "Options:"))
    (mapcar kv-options (cdr (assoc "options" APP_HELP))) ]
