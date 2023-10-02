\ TODO  Unfinished
variable 'quit
: quit  'quit @ execute ;

: ?not-found  dup 0=  if over count type char ? emit cr quit then ;
: ?unstructured  dup ' ; =  sp@ s0 $ 3 cells - <>  and  if ." Unstructured" cr quit then ;
: ?underflow  sp@ s0 >  if ." Underflow" cr quit then ;

: find  seek dup if >xt then ;
\ TODO  Safer redefinitions of all words that search the wordlist

:! (quit)  s0 sp! r0 rp!
	postpone \
	begin name dup find
		( cstr xt )
		?not-found
		?unstructured
		nip execute
		( n*x )
		?underflow
	again ;

[ ' (quit) 'quit !  quit ]

\ TODO  Move to other source code file, or include debug utilities in this file?
:! undo  lp@ back  lp@ @ lp! ;
:! marker  create lp@ , does!>  @ lp! postpone undo ;
:! words  lp@ begin dup 0<> while  dup >name count type space  @ repeat  drop  cr ;

\ TODO  forget (consider changing dictionary structure), hide, hook, defer/is or doer/make, a debug word, and .s
\ Flawed definition : .s  begin sp@ s0 < while .# bl emit repeat ;
