\ This file is meant to provide a friendlier interactive environment to work in.

\ Base variable and automatic number parsing

variable base  [ # 10 base ! ]
: valid#  ( str cnt -- flag )
	true -rot  c-for  c-i digit base @ < and  c-next ;
: ?parse#  ( str cnt -- n? flag )
	2dup valid# if  base @ -rot >number true  else  2drop false  then ;

: ?literal ( cstr xt -- cstr xt' )
	dup 0<> ?exit
	over count ?parse# if  literal  drop ' nothing then ; \ replace 0 xt with nop

: u.  base @ .base ;
: .  .sign u. ;
: ?  @ . cr ;


\ Safety checks

defer quit

: ?not-found
	dup 0<> ?exit
	drop not-found  quit ;

: ?unstructured
	dup ' ; <> ?exit
	sp@ s0 $ 2 cells - = ?exit
	." Unstructured" cr  quit ;

: ?underflow
	sp@ s0 <= ?exit
	." Underflow" cr  quit ;


\ Redefined REPL with safety checks introduced above

:! (quit)
	s0 sp!  r0 rp!
	postpone \
	begin
		name  dup seek  dup if >xt then
		( cstr xt )
		?literal
		?not-found
		?unstructured
		nip execute
		( n*x )
		?underflow
	again ;
\ TODO  Print "[" as a prompt and allow execution with just a "]"

[ ' (quit) is quit ]
[ quit ]

\ Development utilities

: (forget)  back  here @ lp! ;
:! forget  name  dup seek  ?not-found  nip (forget) ;
:! undo  lp@ (forget) ;
:! marker  create  lp@ ,
           does!>  @ (forget) ;

:! words  lp@ traverse-list>
          >name count type space ;

: <.>  ." <" dup .# ." > " ;
:! ?for  { dup 0> if  for } ;
:! ?next { next  else drop then } ;
: #s  s0 sp@ -  $ 3 >>  1- ;
: .s  $ 0  #s 1-  <.>  ?for  sp@ i 1+ cells + @ .  space  ?next  cr  drop ;
\ ^ This definition is really tricky because the operations directly interfere with the stack...
\ I've tried to refactor this to make it clearer, but it's a miracle that it works at all.

: later0  later> $ 0 ;
: rseek  ( addr -- addr 0 | link 1 )
  later0  lp@ traverse-list>
  2dup >= if  nip $ 1  2rdrop 2rdrop  else  drop then ( later 0 ) ;
  
\ TODO  `hide`, and some kind of debug word if possible
