\ TODO : Unfinished
[ RP@ ] CONSTANT R0
[ SP@ ] CONSTANT S0

: NOT-FOUND?  DUP 0=  IF OVER COUNT TYPE CHAR ? EMIT CR TRUE ELSE FALSE THEN ;
: UNSTRUCTURED?  DUP ' ; =  SP@ S0 $ 3 CELLS - <> AND  IF ." unstructured" CR TRUE ELSE FALSE THEN ;
: UNDERFLOW?  SP@ S0 >  IF ." underflow" CR TRUE ELSE FALSE THEN ;
\ TODO : reduce repetition in above definitions

: QUIT  S0 SP! R0 RP!
	BEGIN NAME DUP FIND
		NOT-FOUND? IF QUIT THEN
		UNSTRUCTURED? IF QUIT THEN
		NIP EXECUTE
		UNDERFLOW? IF QUIT THEN
	AGAIN ;

:! RETRY  DP@ THERE DROP  DP@ @ DP! ;
\ ^ Forgets the latest defined word

[ QUIT ]

\ TODO - FORGET (consider changing dictionary structure), HOOK, DEFER/IS or DOER/MAKE, and a DEBUG word, .S
\ Flawed definition : .S  BEGIN SP@ S0 < WHILE .# BL EMIT REPEAT ;
\ ??? : HOOK  CREATE 0 , DOES> @ >R BEGIN R> 0<> WHILE DUP CELL + @ EXECUTE REPEAT ;
