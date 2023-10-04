\ Three examples of different approaches to the same classic problem

\ Naive approach (simple, but incomplete and repetitive)

: thousands     begin dup # 1000 >= while  # 1000 -  ." M" repeat ;
: ?fivehundred  begin dup # 500  >= while  # 500 -  ." D" repeat ;
: hundreds      begin dup # 100  >= while  # 100 -  ." C" repeat ;
: ?fifty        begin dup # 50   >= while  # 50 -  ." L" repeat ;
: tens          begin dup # 10   >= while  # 10 -  ." X" repeat ;
: ?five         begin dup # 5    >= while  # 5 -  ." V" repeat ;
: ones          begin dup # 1    >= while  # 1 -  ." I" repeat ;

: .roman  thousands ?fivehundred hundreds ?fifty tens ?five ones drop ;

\ [ # 4000 for  i . space  i .roman cr  next  bye ]


\ A far superior approach (complete, concise, and easily modifiable)

:! ?for  { dup 0> if  for } ;
:! ?next  { next  else drop then } ;

: .units  2>r  /mod ?for  r>  2r@ type  >r  ?next  2rdrop ;

: .roman
	# 1000 s" M" .units
	# 900 s" CM" .units
	# 500 s" D" .units
	# 400 s" CD" .units
	# 100 s" C" .units
	# 90 s" XC" .units
	# 50 s" L" .units
	# 40 s" XL" .units
	# 10 s" X" .units
	# 9 s" IX" .units
	# 5 s" V" .units
	# 4 s" IV" .units
	# 1 s" I" .units
	drop ;

\ [ # 4000 for  i . space  i .roman cr  next  bye ]


\ An interesting alternative involving postponed parsing

:! units."  ( " )  { /mod ?for  ."  ?next } ;

: .roman
	# 1000 units." M"
	# 900 units." CM"
	# 500 units." D"
	# 400 units." CD"
	# 100 units." C"
	# 90 units." XC"
	# 50 units." L"
	# 40 units." XL"
	# 10 units." X"
	# 9 units." IX"
	# 5 units." V"
	# 4 units." IV"
	# 1 units." I"
	drop ;

[ # 4000 for  i . space  i .roman cr  next  bye ]
