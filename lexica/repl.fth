[ RP@ ] CONSTANT R0
[ SP@ ] CONSTANT S0

: QUIT  S0 SP! R0 RP!
	BEGIN
		NAME DUP FIND
		DUP 0= IF
			DROP COUNT TYPE CHAR ? EMIT CR 
		ELSE
			NIP
			\ Unstructured code detection
			DUP ' :! = OVER ' : = OR IF
				SP@
			ELSE DUP ' ; = IF
				SP@ CELL + <> IF
					." unstructured"
					QUIT
				THEN
			THEN THEN
			EXECUTE
		THEN
	AGAIN ;

QUIT
