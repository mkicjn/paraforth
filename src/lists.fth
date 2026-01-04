\ Linked list operations and list-related constructs

\ Here, "list" refers to a variable containing a pointer to the head of a list,
\ where each node starts with a pointer to the next node in the list.
\ (The core's dictionary is structured this way, so this is convenient - see repl.fth)

: take  ( list -- addr )  dup @ dup @ rot ! ;
: give  ( addr list -- )  2dup @ swap ! ! ;

: +link  ( list size -- )  here -rot  allot  give ;
: +links  ( list size count -- )  for  2dup +link  next 2drop ;

: go  jump ; \ Shim for using `execute` on an address inside another word
\ ^ Explanation: We can't use `execute` if its argument is not at the *beginning* of a subroutine,
\ because this would make us skip the prologue that moves the return address to the correct stack.
\ The role `go` has is to provide this prologue, which allows us to call the *inside* of a word.

: traverse-list>
	( ? link -- ? ) ( R:  "xt" -- )   ( "xt": ? link -- ? )
	begin  dup 0<> while  r@  over >r  go  r> @  repeat drop rdrop ;
\ ^ Explanation: `traverse-list>` consumes its return address (from whence it is called),
\ but returns to it repeatedly, expecting the remainder of the word to consume each link pointer.
\ (Thus, what the stack diagram calls "xt" is not actually an xt, and you do not put it there)
\ A word can return early from `traverse-list>` by `rdrop`ing three times.

\ Example invocation:

: length  ( list -- n )  $ 0 swap  @ traverse-list>  drop 1+ ;


\ Object pools

:! pool  ( count size -- )  cell max  create  here -rot  $ 0 ,  2dup * ,  swap +links ;
: instance?  ( addr pool -- flag )  dup  cell+ @ over +  within ;
\ ^ Only works reliably if no extra links are added to the pool later
alias available  length


\ Hooks

doer (hook)
:! hook  ( -- )  create $ 0 , does>  (hook) ;
: trigger  make (hook)  ( ? -- ? )  @ traverse-list>  cell+ @execute ;
: upon     make (hook)  ( xt -- )  here swap  $ 0 ,  rot ,  give ;
