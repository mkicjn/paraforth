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

:m pushq  $ 50 + c, ;
:m popq   $ 58 + c, ;
:m movq   rex.w,  $ 89 c,  reg modr/m, ;
:m addq   rex.w,  $ 01 c,  reg modr/m, ;
:m subq   rex.w,  $ 29 c,  reg modr/m, ;

:  dup   rax pushq ;
:  drop  rax popq ;
:  swap  rdx popq  rax pushq  rax rdx movq ;
:  -     rdx rax movq  rax popq  rax rdx subq ;

:m stosd            $ ab c, ;
:m stosw   $ 66 c,  $ ab c, ;
:  d,      stosd drop ;
:  w,      stosw drop ;
:  rel32,  rax rdi subq  $ 4 - d, ;

:m testq    rex.w,  $ 85 c,  reg modr/m, ;
:m cmpq     rex.w,  $ 39 c,  swap reg modr/m, ;
:m jz$      $ 840f w,  rel32, ;
:m seteb    $ 940f w,  $ 0 reg modr/m, ;
:m movzxbl  $ b60f w,      reg modr/m, ;

:m begin  dup  rax rdi movq ;
:  cond   rdx rax movq  rax popq  rdx rdx testq ;
:m until  postpone cond postpone jz$ ;

:  =  rdx popq  rax rdx cmpq  rax seteb  rax rax movzxbl ;

:m  \  begin key $ a = until ;
\ testing, testing, 1, 2, 3

int3!

\ Untested - TODO - could having find/compile/execute in the core replace some others?
: compile  $ e8 c, rel32, ;
:! '  name find literal ;
:! }  ;
:! {  begin  name find dup compile  ' } =  until ;
