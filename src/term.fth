\ ANSI control sequence mnemonics

:! .char  { char emit } ;
: csi  $ 1b emit  .char [ ;
: sc  .char ; ;

\ Cursor position:
: cuu  csi . .char A ; \ Up
: cud  csi . .char B ; \ Down
: cuf  csi . .char C ; \ Forward
: cub  csi . .char D ; \ Backward
: cnl  csi . .char E ; \ Next line
: cpl  csi . .char F ; \ Previous line
: cha  csi . .char G ; \ Horizontal absolute
: cup  csi . sc . .char H ; \ Position
: cus  csi ." ?25h" ; \ Show
: cuh  csi ." ?25l" ; \ Hide
: scp  csi .char s ; \ Save
: rcp  csi .char u ; \ Restore
: dsr  csi ." 6n" ; \ Status report

\ Erase:
: ed  csi . .char J ; \ Display
: el  csi . .char K ; \ Line
: cls  $ 2 ed ; \ Whole display

\ Scroll:
: su  csi . .char K ; \ Up
: sd  csi . .char K ; \ Down

\ Graphics Rendition:
: sgr  csi . .char m ; \ Set
: rgr  $ 0 sgr ; \ Reset
: fg  # 30 + sgr ; \ Foreground
: bg  # 40 + sgr ; \ Background
: fgb  # 90 + sgr ; \ Foreground (bright)
: bgb  # 100 + sgr ; \ Background (bright)

: 8bit  csi .char 5 sc . .char m ;
: rgb   swap -rot  csi .char 2 sc . sc . sc . .char m ;

[ $ 0 ] constant black
[ $ 1 ] constant red
[ $ 2 ] constant green
[ $ 3 ] constant yellow
[ $ 4 ] constant blue
[ $ 5 ] constant magenta
[ $ 6 ] constant cyan
[ $ 7 ] constant white
[ $ 9 ] constant default

\ TODO : 8-bit and RGB color palettes - probably refactor fg/bg words
\ custom           8 sc
\ colr_rgb(R,G,B)  2 sc R sc G sc B
\ colr_8bit(N)     5 sc N

\ TODO : Worth reducing the repetition here?
: reset        # 0 sgr ;
: bold         # 1 sgr ;
: faint        # 2 sgr ;
: italic       # 3 sgr ;
: underline    # 4 sgr ;
: slowblink    # 5 sgr ;
: fastblink    # 6 sgr ;
: invert       # 7 sgr ;
: conceal      # 8 sgr ;
: strike       # 9 sgr ;
: nofaint      # 22 sgr ;
: noitalic     # 23 sgr ;
: nounderline  # 24 sgr ;
: noblink      # 25 sgr ;
: noinvert     # 27 sgr ;
: reveal       # 28 sgr ;
: nostrike     # 29 sgr ;
alias nobold nofaint
