\ I'm using this file to define words that are useful
\ to start with, but not necessary to have as primitives

: POSTPONE  IMMEDIATE  WORD FIND COMPILE ;
: '  IMMEDIATE  WORD FIND LITERAL ;

: /  /MOD NIP ;
: MOD  /MOD DROP ;
: -  IMMEDIATE  POSTPONE NEG  POSTPONE + ;
: 1-  # 1 - ;
: 1+  # 1 + ;

: BL  # 32 ;
: CR  # 10 TX ;


\	Explanation of branching words
\ 
\ This implementation only provides IF, AHEAD, THEN, BEGIN, UNTIL, and AHEAD.
\ These form a foundation for further definitions of branching words,
\ and are (to me) more elegant than the typical branch/MARK/RESOLVE strategy.
\ 
\ In fact, this implementation's branching words are exactly analogous:
\ 
\ This implementation		eForth
\ -------------------------------------------------------
\ POSTPONE IF			COMPILE ?branch >MARK
\ POSTPONE AHEAD		COMPILE  branch >MARK
\ POSTPONE THEN					>RESOLVE
\ 
\ POSTPONE BEGIN				<MARK
\ POSTPONE UNTIL		COMPILE ?branch <RESOLVE
\ POSTPONE AGAIN		COMPILE  branch <RESOLVE
\ 

: ELSE  IMMEDIATE  POSTPONE AHEAD  SWAP POSTPONE THEN  ;

: WHILE  IMMEDIATE  POSTPONE IF  SWAP ;
: REPEAT  IMMEDIATE  POSTPONE AGAIN  POSTPONE THEN ;

: FOR  IMMEDIATE  POSTPONE >R  POSTPONE BEGIN ;
: AFT  IMMEDIATE  DROP  POSTPONE AHEAD  POSTPONE BEGIN  SWAP ;
: donext  R>> OVER 1- >R >R  0= ;  \ Slightly ugly. Refactor?
: NEXT  IMMEDIATE  POSTPONE donext POSTPONE UNTIL  POSTPONE RDROP ;
: I  IMMEDIATE  POSTPONE R@ ;
\ TODO : J  RSP@ # 2 CELLS + @ ;


: =  IMMEDIATE  POSTPONE XOR  POSTPONE 0= ;
: <> IMMEDIATE  POSTPONE =  POSTPONE NOT ;
: <  IMMEDIATE  POSTPONE -  POSTPONE 0< ;
: >  IMMEDIATE  POSTPONE SWAP  POSTPONE < ;
: >=  IMMEDIATE  POSTPONE <  POSTPONE NOT ;
: <=  IMMEDIATE  POSTPONE >  POSTPONE NOT ;

: %d  DUP 0< IF  # 45 TX  NEG  THEN %u ;
\ This implementation has the words %u and %d to make formatted output easier.
\ These are like U. and . but do not output the following space.
\ In standard Forth, you have to use a set of string formatting words to do this.
\ I do not wish to implement that here, so it's easier like this.
: U.  %u  BL TX ;
: .   %d  BL TX ;
\ TODO In the future, I'll need a $ word (like #) and an %x word to print it.


: S"  IMMEDIATE
	POSTPONE AHEAD >R
		# 34 PARSE DUP ALLOT
	R> POSTPONE THEN
	SWAP LITERAL LITERAL
;
: ."  IMMEDIATE  POSTPONE S"  POSTPONE TYPE ;
