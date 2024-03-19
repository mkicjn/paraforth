link :m  enter  postpone link  postpone enter  exit

:m ;  postpone exit  exit
:m :  postpone link  postpone docol  postpone enter  ;

:m int3  $ cc c, ;
:m int3! int3 ;

:m rax  $ 0 ;
:m rcx  $ 1 ;
:m rdx  $ 2 ;
:m rbx  $ 3 ;
:m rsp  $ 4 ;
:m rbp  $ 5 ;
:m rsi  $ 6 ;
:m rdi  $ 7 ;
:  mem      $ 0 ;
:  mem+8    $ 1 ;
:  mem+32   $ 2 ;
:  reg      $ 3 ;
:  modr/m,  $ 3 << + $ 3 << + c, ;

:  rex.w,  $ 48 c, ;

:m movq   rex.w,  $ 89 c,  reg modr/m, ;

:m pushq  $ 50 + c, ;
:m popq   $ 58 + c, ;

:  dup   rax pushq ;
:  drop  rax popq ;
int3!
