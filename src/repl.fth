\ This file is meant to provide a friendlier interactive environment to work in.

defer quit

: ?not-found  dup 0=  if  over  count type  char ? emit  cr  quit  then ;
: ?unstructured  dup ' ; =  sp@ s0 $ 3 cells - <> and  if  ." Unstructured" cr  quit  then ;
: ?underflow  sp@ s0 >  if  ." Underflow" cr  quit  then ;

: find  seek  dup if  >xt  then ;
\ TODO  Safer redefinitions of all words that search the wordlist

:! (quit)
	s0 sp!  r0 rp!
	postpone \
	begin
		name  dup find
		( cstr xt )
		?not-found
		?unstructured
		nip execute
		( n*x )
		?underflow
	again ;

[ ' (quit) is quit ]
[ quit ]

:! undo  lp@ back  lp@ @ lp! ;
:! marker  create  lp@ ,  does!>  @ lp! ;
:! words  lp@ traverse-list>  >name count type space ;

marker reset

\ TODO  forget (consider changing dictionary structure), hide, hook, some kind of debug word, and .s
\ Flawed definition : .s  begin sp@ s0 < while .# bl emit repeat ;
