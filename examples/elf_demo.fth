\ This is a fairly old demo that needs to be rewritten eventually.
\ For instance, the inlining system implemented here is inferior to the new one offered with the primitives.
\ It was originally part of a bootstrapping effort at an earlier stage, and was never completed.
\ The generated binary does next to nothing, but the code is still useful as a sort of regression test.
\ It might become more useful once bootstrapping is back on the radar (hoping to address usability first).

: INLINE  HERE SWAP MOVE ;
:! {  POSTPONE AHEAD  HERE ;
:! }  HERE OVER -  ROT POSTPONE THEN  2LITERAL ;

:! PUSHA  FOR AFT POSTPONE PUSHQ THEN NEXT ;
:! POPA  FOR AFT POSTPONE POPQ THEN NEXT ;

[ $ 400000 ] CONSTANT LOAD-ADDR
[ $ 42000 ] CONSTANT EXTRA-MEM

VARIABLE ELF-HEADER
: TARGET  ELF-HEADER @ ;
: PADDR  - ;
: VADDR  PADDR LOAD-ADDR + ;
: FILESZ  $ 60 + ;
: MEMSZ  $ 68 + ;
: ENTRY  $ 18 + ;

:! SET-ENTRY  NAME FIND TARGET VADDR TARGET ENTRY ! ;

: UPDATE-SIZE  HERE TARGET PADDR DUP TARGET FILESZ !  EXTRA-MEM + TARGET MEMSZ ! ;
:! DUMP-BINARY  UPDATE-SIZE  TARGET  TARGET FILESZ @  TYPE  BYE ;

\ VARIABLE TARGET-DICT   [ $ 0 TARGET-DICT ! ]
\ : TARGET-LINK  TARGET-DICT @ ,  HERE OVER C@ 1+ MOVE ;

[ HERE ELF-HEADER ! ]

[
	\ ELF Header
	$ 464C457F D, \ EI_MAG ("\x7fELF")
	$ 2 C, \ EI_CLASS (64-bit format)
	$ 1 C, \ EI_DATA (little endian)
	$ 1 C, \ EI_VERSION (1)
	$ 0 C, \ EI_OSABI (System V)
	$ 0 , \ EI_ABIVERSION, EI_PAD
	$ 2 W, \ e_type (ET_EXEC)
	$ 3E W, \ e_machine (x86-64)
	$ 1 D, \ e_version (1)
	LOAD-ADDR , \ e_entry (TBD)
	$ 40 , \ e_phoff
	$ 0 , \ e_shoff
	$ 0 D, \ e_flags
	$ 40 W, \ e_ehsize
	$ 38 W, \ e_phentsize
	$ 1 W, \ e_phnum
	$ 40 W, \ e_shentsize
	$ 0 W, \ e_shnum
	$ 0 W, \ e_shstrndx

	\ Program Header
	$ 1 D, \ p_type
	$ 7 D, \ p_flags
	$ 0 , \ p_offset
	LOAD-ADDR , \ p_vaddr
	LOAD-ADDR , \ p_paddr
	$ 78 , \ p_filesz
	$ 78 , \ p_memsz
	$ 1000 , \ p_align
]

\ TODO Since the calling convention will be different in the target, it will be challenging to bootstrap without wordlists.
\ I think it should be fine as long as the host never executes the target's code, and vice versa.
\ It would be preferable to keep things simple and avoid implementing wordlists if possible.

\ Core words: DUP DROP SWAP + - LSHIFT RSHIFT C, DOCOL DOLIT BYE RX TX FIND NAME, :! ; NAME DIGIT $

\ TODO Redefine :! to fit the slightly different dictionary structure of the target
\ TODO Define {, }, and INLINE inside the target (which means redefining MOVE, etc.)
:! DUP  { RDX PUSHQ  RDX RAX MOVQ } INLINE ;
:! DROP  { RAX RDX MOVQ  RDX POPQ } INLINE ;
:! 2DROP  { RAX POPQ  RDX POPQ } INLINE ;
:! SWAP  { RDX RAXXCHGQ } INLINE ;
:! OVER  { RDX PUSHQ  SWAP } INLINE ;
:! NIP  { RDX POPQ } INLINE ;
:! TUCK  { RAX PUSHQ } INLINE ;
:! +  { RAX RDX ADDQ  DROP } INLINE ;
:! -  { RAX RDX SUBQ  DROP } INLINE ;
:! LSHIFT  { RCX PUSHQ  RCX RAX MOVQ  RDX CLSHLQ  RCX POPQ  DROP } INLINE ;
:! RSHIFT  { RCX PUSHQ  RCX RAX MOVQ  RDX CLSHRQ  RCX POPQ  DROP } INLINE ;
:! C,  { STOSB  DROP } INLINE ;
:!  ,  { STOSQ  DROP } INLINE ;
:! !  { RAX RDX MOVQ!  2DROP } INLINE ;
:! @  { RAX RAX MOVQ@ } INLINE ;
:! C@  { RAX RAX MOVZXB@ } INLINE ;
:! C!  { RAX RDX MOVB!  2DROP } INLINE ;

\ TODO fix: These definitions rely on references to words in the host (DOCOL, RAX, MOVQ$)
: DOCOL  R> POSTPONE CALLQ ;
: DOLIT  POSTPONE DUP POSTPONE RAX SWAP POSTPONE MOVQ$ ;

\ TODO Another problem: At some point, DEFER may be needed to handle forward references.
\ It may be worth carefully selecting which words to DEFER for maximum utility later.

:! START
	RAX [ $ 3C ] MOVQ$
	RDI [ $ 4D ] MOVQ$
	SYSCALL

SET-ENTRY START
DUMP-BINARY
