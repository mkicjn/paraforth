\ Working but not as much faster as it could be

\ I want to optimize this further as an experiment.
\ Later, when I create profiling tools, it would be interesting to try them on this example.

:! ?mark>  $ 0 { jzl$ }   here $ 4 - ;
:!  mark>  $ 0 { jmpl$ }  here $ 4 - ;
:!  >resolve  there dup rel32, back ;
\ :!  mark<  here ;
\ :!  <resolve  { jmpl$ } ;
\ :! ?<resolve  { jzl$ } ;

:! leaq@+8  rex.w,  swap $ 8d   c,  mem+8 modr/m, ;
: collatz-step
	rax [ $ 1 ] testq$
	?mark>
	rax (sib) leaq@+8  rax rax r*2 sib, [ $ 1 c, ] \ lea rax, [3*rax+1]
	mark>
	[ swap ] >resolve
	rax 1shrq
	>resolve
	;

:! align  here $ 4 aligned  here - for { nop } next ;
: collatz-len   $ 0 swap align begin  dup $ 1 > while  collatz-step  rdx incq  repeat drop ;
: max-collatz   $ 0 swap for  i collatz-len max  next ;

[ # 1000000 max-collatz .# cr bye ]
