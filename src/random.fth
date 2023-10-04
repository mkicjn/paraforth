\ Random number generation

\ This is a counter-based random number generator I developed based on a few existing ideas.
: xorshift+  dup # 13 lshift xor  dup # 7 rshift xor  dup # 31 rshift + ;
: cbrng  $ ba2c2cab  tuck * tuck xor *  xorshift+ ;
\ ^ The xorshift+ is sort of optional but improves entropy, especially on the lower 32 bits.

:! rng  create here cbrng , does>  # 1 over +!  @ cbrng ;
alias seed  to

rng random
[ time cbrng  seed random ]


\ For entropy testing

\ The below code is horribly bottlenecked due to a syscall happening on each emit,
\ but it's surprisingly fast elsewhere and performs very well in statistical tests.

\ : emits  for  dup emit  # 8 rshift  next drop ;
\ [ begin  random  # 8 emits  again ]
