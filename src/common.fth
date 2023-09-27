\ TODO  Split into different files?

\ Parenthesis comments
:! char  name 1+ c@ literal ;
:! (  begin key char ) = until ;

\ Word manipulation
: count  1+ dup 1- c@ ;
: type  for dup c@ emit 1+ next drop ;

\ Character constants
: cr  $ a emit ;
:! bl  $ 20 literal ;
: space  bl emit ;

\ Unsigned decimal integer i/o
:! #  $ 0 name count  for  >r  $ a *  r@ c@ digit +  r> 1+  next drop literal ;
: .#  $ 0  begin >r  # 10 /mod  r> 1+  over 0= until  nip  for  char 0 + emit  next ;
\ TODO  Add signed decimal i/o and hexadecimal output

\ Words for embedding data into code
: embed  postpone ahead  here swap ;
: with-length  here swap  postpone then  over - 2literal ;
: alone  postpone then literal ;

\ Strings
: parse, ( delim -- ) key begin 2dup <> while c, key repeat 2drop ; \ Read keys into memory until delimiter
: parse  ( delim -- str cnt ) here swap parse,  dup there over - ;  \ parse, but temporary (reset data pointer)
:! s"  embed  char " parse,  with-length ;
:! ."  postpone s"  postpone type ;

\ Data structures
: docreate  r> literal ;
: create  postpone :! postpone docreate ;
: dodoes>  lp@ >xt  there r> compile back ;
:! does>  postpone dodoes> postpone r>  ;
\ Since this is a compile-only Forth, create and does> work a little differently.
\ create is not immediate, which means e.g. `create _ 8 cells allot` won't work.
\ TODO  Does it really need to be immediate?
\ Instead, the following definition can be used, e.g. `[ 8 cells ] array _ `
:! array  create allot ;
\ does> redefines the CREATEd word as immediate, giving the opportunity for some code generation.
\ TODO  Find workarounds for these differences. For does>, can probably place docol after does>. What about create?

:! constant  create , does> @ literal ;
[ $ 0 ] constant false
[ $ 1 ] constant true
[ sp@ ] constant s0
[ rp@ ] constant r0

:! variable  create cell allot ;

\ On/Off and conditional exit
: on   true swap ! ;
: off  false swap ! ;
: on?   @ 0<> ;
: off?  @ 0= ;
: ?exit  if rdrop then ;

\ TODO  Find a good conditional compilation mechanism for supporting optimized versions of e.g. below

\ Dual string operations
: cstep  swap 1+ swap 1+ ;
: ccopy  swap c@ swap c! ;
: 2c@    swap c@ swap c@ ;
\ Memory copying
: cmove  for  2dup ccopy cstep  next 2drop ;
\ Counted string comparisons
: ?c=  2c@ = ?exit  rdrop unloop ;
: -match  for  2dup ?c= cstep  next ; \ Find mismatch
: cstr=  dup c@  -match  2c@ = ;

\ TODO  Implement compare (reusing -match)
: sign  dup 0<> if  0> 2* 1-  then ;

\ Address alignment
: aligned  1- tuck + swap invert and ; \ Aligns for powers of 2 only
