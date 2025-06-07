\ Local variables

\ (Editorial note)
\ Local variables are generally discouraged in Forth for a variety of reasons.
\ On rare occasions, I find they can be useful for directly translating procedural (pseudo)code as a starting point for something challenging.
\ In general, however, locals are slower than the stack, and more importantly, promote poor code quality (i.e., long, complex definitions).

\ Basically, if you're avoiding stack juggling by using locals instead of refactoring, you're probably either:
\ A) using Forth for the wrong reasons and should switch to something more practical, or
\ B) still learning about how to write "good" Forth code and using local variables as a crutch.

\ That said, the code below is not meant to be particularly practical as-is - it's just an interesting approach that might be worth remembering later.
\ Note that the interface shown here creates locals that are VARIABLEs (X @ / X !), not VALUEs (X / to X).


\ Numerically-indexed locals

: +local  r> 2>r  later> rdrop ;
:! locals  for { +local } next ;
: >local  1+ 2* cells rp@ + ;
:! l@  { >local @ } ;
:! l!  { >local ! } ;

\ Example:
\ : dup    [ 1 ] locals  0 l@  0 l@ ;
\ : drop   [ 1 ] locals  ;
\ : swap   [ 2 ] locals  1 l@  0 l@ ;
\ : rot    [ 3 ] locals  1 l@  2 l@  0 l@ ;
\ : 2dup   [ 2 ] locals  0 l@  1 l@  0 l@  1 l@ ;
\ : 2drop  [ 2 ] locals  ;
\ : 2swap  [ 4 ] locals  2 l@  3 l@  0 l@  1 l@ ;
\ : 2rot   [ 6 ] locals  4 l@  5 l@  0 l@  1 l@  2 l@  3 l@ ;
\ ...


\ Name-indexed locals

: (local)  create  ,  does!>  @ literal { >local @ } ; \ could leave out the fetch or define setters similarly if useful
:! locals:  dup for dup i - 1- (local) next drop ;

\ Example:
\ [ 6 ] locals: a b c d e f
\ : dup    [ 1 ] locals  a a ;
\ : drop   [ 1 ] locals  ;
\ : swap   [ 2 ] locals  b a ;
\ : rot    [ 3 ] locals  b c a ;
\ : 2dup   [ 2 ] locals  a b a b ;
\ : 2drop  [ 2 ] locals  ;
\ : 2swap  [ 4 ] locals  c d a b ;
\ : 2rot   [ 6 ] locals  e f a b c d ;
\ ...
