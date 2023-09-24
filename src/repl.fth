\ TODO  Unfinished
VARIABLE 'QUIT
: QUIT  'QUIT @ EXECUTE ;

: ?NOT-FOUND  DUP 0=  IF OVER COUNT TYPE CHAR ? EMIT CR QUIT THEN ;
: ?UNSTRUCTURED  DUP ' ; =  SP@ S0 $ 3 CELLS - <>  AND  IF ." UNSTRUCTURED" CR QUIT THEN ;
: ?UNDERFLOW  SP@ S0 >  IF ." UNDERFLOW" CR QUIT THEN ;

:! (QUIT)  S0 SP! R0 RP!
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
:! UNDO  DP@ BACK  DP@ @ DP! ;
\ ^ Forgets the latest defined word

\ TODO  FORGET (consider changing dictionary structure), HOOK, DEFER/IS or DOER/MAKE, and a DEBUG word, .S
\ Flawed definition : .S  BEGIN SP@ S0 < WHILE .# BL EMIT REPEAT ;
