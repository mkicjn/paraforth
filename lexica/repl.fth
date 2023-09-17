\ TODO - Unfinished
[ SP@ ] CONSTANT S0
[ RP@ ] CONSTANT R0

VARIABLE 'QUIT
: QUIT  'QUIT @ EXECUTE ;

: CHECK-NOT-FOUND  DUP 0=  IF OVER COUNT TYPE CHAR ? EMIT CR QUIT THEN ;
: CHECK-UNSTRUCTURED  DUP ' ; =  SP@ S0 $ 3 CELLS - <> AND  IF ." unstructured" CR QUIT THEN ;
: CHECK-UNDERFLOW  SP@ S0 >  IF ." underflow" CR QUIT THEN ;

: (QUIT)  S0 SP! R0 RP!
	BEGIN NAME DUP FIND
		( cstr xt )
		CHECK-NOT-FOUND
		CHECK-UNSTRUCTURED
		NIP EXECUTE
		( n*x )
		CHECK-UNDERFLOW
	AGAIN ;

[ ' (QUIT) 'QUIT !  QUIT ]

\ TODO - Move to other source code file?
:! RETRY  DP@ THERE DROP  DP@ @ DP! ;
\ ^ Forgets the latest defined word

\ TODO - FORGET (consider changing dictionary structure), HOOK, DEFER/IS or DOER/MAKE, and a DEBUG word, .S
\ Flawed definition : .S  BEGIN SP@ S0 < WHILE .# BL EMIT REPEAT ;
\ ??? : HOOK  CREATE 0 , DOES> @ >R BEGIN R> 0<> WHILE DUP CELL + @ EXECUTE REPEAT ;
