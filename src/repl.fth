\ This file is meant to provide a friendlier interactive environment to work in.


\ Base variable and automatic number parsing

variable base  [ # 10 base ! ]
: valid#  ( str cnt -- flag )
	true -rot  c-for  c-i digit base @ < and  c-next ;
: ?parse#  ( str cnt -- n? flag )
	2dup valid# if  base @ -rot >number true  else  2drop false  then ;

: ?literal ( cstr xt -- cstr xt' )
	dup 0<> ?exit
	over count ?parse# if  literal  drop ' nop then ; \ replace 0 xt with nop

: u.  base @ .base ;
: .  .sign u. ;
: ?  @ . cr ;


\ Safety checks

defer quit

: ?not-found
	dup 0<> ?exit
	drop count type  char ? emit  cr  quit ;

: ?unstructured
	dup ' ; <> ?exit
	sp@ s0 $ 2 cells - = ?exit
	." Unstructured" cr  quit ;

: ?underflow
	sp@ s0 <= ?exit
	." Underflow" cr  quit ;


\ TODO  Safer redefinitions of all words that search the wordlist
: find  seek  dup if  >xt  then ;


\ Redefined REPL with safety checks introduced above

:! (quit)
	s0 sp!  r0 rp!
	postpone \
	begin
		name  dup find
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
:! marker  create  lp@ ,  does!>  @ (forget) ;
:! words  lp@ traverse-list>  >name count type space ;

: <.>  ." <" dup .# ." > " ;
:! ?for  { dup 0> if  for } ;
:! ?next { next  else drop then } ;
: #s  s0 sp@ -  $ 3 rshift  1- ;
: .s  $ 0  #s 1-  <.>  ?for  sp@ i cells + @ .  space  ?next  cr  drop ;
\ ^ This definition is really tricky because the operations directly interfere with the stack...
\ I've tried to refactor this to make it clearer, but it's a miracle that it works at all.

\ TODO  `hide`, and some kind of debug word if possible
