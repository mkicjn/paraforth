\ Linked list operations and list-related constructs

: take  ( addr list -- )  dup @ dup @ rot ! ;
: give  ( list -- addr )  2dup @ swap ! ! ;

: +link  ( list size -- )  here -rot  allot  give ;
: +links  ( list size count -- )  for  2dup +link  next 2drop ;

: traverse-list>  ( R:  xt -- )  ( xt: n*x addr -- m*x )
	begin  dup 0<> while  r@  over >r  execute  r> @ repeat drop rdrop ;

: length  ( list -- n )  $ 0 swap traverse-list>  drop 1+ ;


\  Object pools

:! pool  ( count size -- )  cell max  create  here -rot  $ 0 ,  2dup * ,  +links ;
: instance?  ( addr pool -- flag )  dup  cell+ @ over +  within ;
\ ^ Only works reliably if no extra links are added to the pool later
alias available  length
