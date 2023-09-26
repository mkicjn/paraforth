\ TODO  Unfinished
VARIABLE 'QUIT
: QUIT  'QUIT @ EXECUTE ;

: ?NOT-FOUND  DUP 0=  IF OVER COUNT TYPE CHAR ? EMIT CR QUIT THEN ;
: ?UNSTRUCTURED  DUP ' ; =  SP@ S0 $ 3 CELLS - <>  AND  IF ." UNSTRUCTURED" CR QUIT THEN ;
: ?UNDERFLOW  SP@ S0 >  IF ." UNDERFLOW" CR QUIT THEN ;

\ TODO  Safer redefinitions of all words that search the wordlist

:! (QUIT)  S0 SP! R0 RP!
	POSTPONE \
	BEGIN NAME DUP FIND
		( cstr xt )
		?NOT-FOUND
		?UNSTRUCTURED
		NIP EXECUTE
		( n*x )
		?UNDERFLOW
	AGAIN ;

[ ' (QUIT) 'QUIT !  QUIT ]

\ TODO  Move to other source code file, or include debug utilities in this file?
:! UNDO  LP@ BACK  LP@ @ LP! ;
:! MARKER  CREATE LP@ , DOES>  @ LP! POSTPONE UNDO ;
:! WORDS  LP@ BEGIN DUP 0<> WHILE  DUP >NAME COUNT TYPE SPACE  @ REPEAT  DROP  CR ;

\ TODO  FORGET (consider changing dictionary structure), HIDE, HOOK, DEFER/IS or DOER/MAKE, a DEBUG word, .S
\ Flawed definition : .S  BEGIN SP@ S0 < WHILE .# BL EMIT REPEAT ;
