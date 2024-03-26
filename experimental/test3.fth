link :!  enter  postpone link  postpone enter  exit

:! ;  postpone exit  exit
:! :  postpone link  postpone docol  postpone enter  ;

:! int3  $ cc c, ;
:! int3! int3 ;

:! rax  $ 0 ;
:! rcx  $ 1 ;
:! rdx  $ 2 ;
:! rbx  $ 3 ;
:! rsp  $ 4 ;
:! rbp  $ 5 ;
:! rsi  $ 6 ;
:! rdi  $ 7 ;

:  mem      $ 0 ;
:  mem+8    $ 1 ;
:  mem+32   $ 2 ;
:  reg      $ 3 ;
:  modr/m,  $ 3 << + $ 3 << + c, ;

:  rex.w,  $ 48 c, ;

:! pushq  $ 50 + c, ;
:! popq   $ 58 + c, ;
:! movq   rex.w,  $ 89 c,  reg modr/m, ;
:! addq   rex.w,  $ 01 c,  reg modr/m, ;
:! subq   rex.w,  $ 29 c,  reg modr/m, ;

:  dup   rax pushq ;
:  drop  rax popq ;
:  swap  rdx popq  rax pushq  rax rdx movq ;
:  -     rdx rax movq  rax popq  rax rdx subq ;

:! stosd            $ ab c, ;
:! stosw   $ 66 c,  $ ab c, ;
:  d,      stosd drop ;
:  w,      stosw drop ;
:  rel32,  rax rdi subq  $ 4 - d, ;

:! testq    rex.w,  $ 85 c,  reg modr/m, ;
:! cmpq     rex.w,  $ 39 c,  swap reg modr/m, ;
:! jz$      $ 840f w,  rel32, ;
:! seteb    $ 940f w,  $ 0 reg modr/m, ;
:! movzxbl  $ b60f w,      reg modr/m, ;

:! begin  dup  rax rdi movq ;
:  cond   rdx rax movq  rax popq  rdx rdx testq ;
:! until  postpone cond postpone jz$ ;

:  =  rdx popq  rax rdx cmpq  rax seteb  rax rax movzxbl ;

:!  \  begin key $ a = until ;
\ Comments enabled

:! movzxb@  rex.w, $ b60f w, swap mem modr/m, ;
:! incq   rex.w, $ ff c, $ 0 reg modr/m, ;
:! decq   rex.w, $ ff c, $ 1 reg modr/m, ;

:  find  seek  $ 8 +  rcx rax movzxb@  rax rcx addq  rax incq ;
:  compile  $ e8 c, rel32, ;
:  here  rax pushq  rax rdi movq ;
:  back  rdi rax movq  rax popq ;
:  name  here name, back  here ;
:! '  name find literal ;
:! }  ;
:! {  begin  name find dup compile  ' } =  until ;
\ ^ Ideally we speedrun to this point to reduce rework

:! +  { rdx popq  rax rdx addq } ;
:  test  $ 1  $ 2  + ;
int3!
