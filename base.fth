: CHAR  IMMEDIATE  RX LITERAL ;
: BL  CHAR   ;
: CR  CHAR


TX ;

: POSTPONE  IMMEDIATE  WORD FIND COMPILE ;
: '  IMMEDIATE  WORD FIND LITERAL ;

: =  IMMEDIATE  POSTPONE XOR  POSTPONE 0= ;
: <> IMMEDIATE  POSTPONE =  POSTPONE NOT ;
: <  IMMEDIATE  POSTPONE -  POSTPONE 0< ;
: >  IMMEDIATE  POSTPONE SWAP  POSTPONE < ;
: >=  IMMEDIATE  POSTPONE <  POSTPONE NOT ;
: <=  IMMEDIATE  POSTPONE >  POSTPONE NOT ;

: \  IMMEDIATE  BEGIN  RX  # 10 = UNTIL ;
: (  IMMEDIATE  BEGIN  RX  CHAR ) = UNTIL ;

\ Now that comments are defined, I can start explaining a few things.
\ I'm using this file to define words that are useful
\ to start with, but not necessary to have as primitives

\ TODO Start looking for things that can be defined here instead of in asm

\ TODO Find a way to define the # word in Forth
\ e.g. : #  IMMEDIATE  WORD COUNT FOR .. 10 * .. + THEN ;
\ TODO In the future, I'll need a $ word (like #) and some way to print it.

: U.  # 1 NEGATE SWAP  \ Place a sentinel value
      BEGIN # 10 /MOD DUP 0= UNTIL DROP   \ Extract digits
      BEGIN CHAR 0 + TX DUP 0< UNTIL DROP \ Print digits
      BL TX
;
: .  DUP 0< IF  CHAR - TX  NEGATE  THEN U. ;

: /  /MOD NIP ;
: MOD  /MOD DROP ;

\	Explanation of branching words
\ 
\ This implementation only provides IF, AHEAD, THEN, BEGIN, UNTIL, and AGAIN.
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
: donext  R>> OVER 1- >R >R  0= ;  ( Slightly ugly. Refactor? )
: NEXT  IMMEDIATE  POSTPONE donext POSTPONE UNTIL  POSTPONE RDROP ;
: I  IMMEDIATE  POSTPONE R@ ;
\ TODO : J  RSP@ # 2 CELLS + @ ;

: S"  IMMEDIATE
	POSTPONE AHEAD >R
		CHAR " PARSE  DUP ALLOT \ "
	R> POSTPONE THEN
	SWAP LITERAL LITERAL
;
\ TODO Add a way to insert literal quotation marks in strings
: ."  IMMEDIATE  POSTPONE S"  POSTPONE TYPE ;
