: collatz-step  dup $ 1 and  if  dup 2* + 1+  else  2/  then ;
: collatz-len   $ 0 swap begin  dup $ 1 > while  collatz-step  swap 1+ swap repeat drop ;
: max-collatz   $ 0 swap for  i collatz-len max  next ;

[ # 1000000 max-collatz .# cr bye ]
