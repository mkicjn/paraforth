\ Random number generation

\ SplitMix64, adapted (translated and modified) from Sebastiano Vigna's PRNG shootout implementation [1].
\ The only modification here is to use key/counter inputs (naming inspired by Squares [2]) in lieu of state,
\ based on the observation that `x` is merely some initial value plus a multiple of that first constant
\ (which, fun fact, represents the fractional part of the golden ratio times 2^64).
\
\ [1] https://prng.di.unimi.it/splitmix64.c
\ [2] https://doi.org/10.48550/arXiv.2004.06278
\
\ This statelessness provides re-entrancy, plus unlimited O(1) jump forward/back, without sacrificing RNG quality.

: splitmix64_ctr ( key ctr -- rn )
  $ 9e3779b97f4a7c15 * +
  dup $ 1e >> xor
  $ bf58476d1ce4e5b9 *
  dup $ 1b >> xor
  $ 94d049bb133111eb *
  dup $ 1f >> xor ;

alias cbrng  splitmix64_ctr


\ For convenience, stateful RNGs can be created using `rng`, keyed with their address by default or seeded with `seed`.

:! rng  create  $ 0 , here ,  does>  $ 1 over +!  2@ cbrng ;
:! seed  $ 0 literal { swap  at  2! } ;  \ Updates key field and resets counter


\ A default RNG called `rand` is also provided which is seeded by UNIX time, a la srand(time(NULL)).

rng rand
[ time  seed rand ]


\ For entropy testing

\ The below code is horribly I/O bottlenecked due to a syscall on each emit,
\ but the RNG itself is of course quite fast otherwise and passes the usual tests.

\ Commenting this out will make this file spit out random bytes forever when loaded.

\ : emits  for  dup emit  # 8 >>  next drop ;
\ [ begin  rand  # 8 emits  again ]
