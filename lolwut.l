# picolisp-kv - https://github.com/aw/picolisp-kv
#
# LOLWUT, inspired by Redis - https://redis.io/commands/lolwut
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

(seed (in "/dev/urandom" (rd 20)))

(setq
  *KV/%lolwut%/max_columns 80
  *KV/%lolwut%/max_lines   10 )

# LOLWUT command helpers
# sparkLine function borrowed from: https://rosettacode.org/wiki/Sparkline_in_unicode#PicoLisp
[de kv-lolwut-sparkline (Lst)
  (let (Min (apply min Lst)
        Max (apply max Lst)
        Rng (- Max Min) )

    (pack (mapcar '((N) (char (+ 9601 (*/ (- N Min) 7 Rng)))) Lst) ]

# COMMANDS
[de kv-cmd-lolwut (Num)
  (default Num *KV/%lolwut%/max_lines)

  (glue "^J"
    (make
      (do (cond
            ((le0 Num)      1)
            ((> Num 20)    10)
            (T            Num) )
        (link (kv-lolwut-sparkline (make (do *KV/%lolwut%/max_columns (link (rand 1 100) ]
