\ This is a fairly old demo that needs to be rewritten eventually.
\ For instance, the inlining system implemented here is inferior to the new one offered with the primitives.
\ It was originally part of a bootstrapping effort at an earlier stage, and was never completed.
\ The generated binary does next to nothing, but the code is still useful as a sort of regression test.
\ It might become more useful once bootstrapping is back on the radar (hoping to address usability first).

: inline  here swap cmove ;
:! {  postpone ahead  here ;
:! }  here over -  rot postpone then  2literal ;

:! pusha  for postpone pushq next ;
:! popa  for postpone popq next ;

[ $ 400000 ] constant load-addr
[ $ 42000 ] constant extra-mem

variable elf-header
: target  elf-header @ ;
: paddr  - ;
: vaddr  paddr load-addr + ;
: filesz  $ 60 + ;
: memsz  $ 68 + ;
: entry  $ 18 + ;

:! set-entry  name find target vaddr target entry ! ;

: update-size  here target paddr dup target filesz !  extra-mem + target memsz ! ;
:! dump-binary  update-size  target  target filesz @  type  bye ;

\ variable target-dict   [ $ 0 target-dict ! ]
\ : target-link  target-dict @ ,  here over c@ 1+ cmove ;

[ here elf-header ! ]

[
	\ elf Header
	$ 464c457f d, \ ei_mag ("\x7fELF")
	$ 2 c, \ ei_class (64-bit format)
	$ 1 c, \ ei_data (little endian)
	$ 1 c, \ ei_version (1)
	$ 0 c, \ ei_osabi (System v)
	$ 0 , \ ei_abiversion, ei_pad
	$ 2 w, \ e_type (et_exec)
	$ 3e w, \ e_machine (x86-64)
	$ 1 d, \ e_version (1)
	load-addr , \ e_entry (tbd)
	$ 40 , \ e_phoff
	$ 0 , \ e_shoff
	$ 0 d, \ e_flags
	$ 40 w, \ e_ehsize
	$ 38 w, \ e_phentsize
	$ 1 w, \ e_phnum
	$ 40 w, \ e_shentsize
	$ 0 w, \ e_shnum
	$ 0 w, \ e_shstrndx

	\ Program Header
	$ 1 d, \ p_type
	$ 7 d, \ p_flags
	$ 0 , \ p_offset
	load-addr , \ p_vaddr
	load-addr , \ p_paddr
	$ 78 , \ p_filesz
	$ 78 , \ p_memsz
	$ 1000 , \ p_align
]

\ TODO  Since the calling convention will be different in the target, it will be challenging to bootstrap without wordlists.
\ I think it should be fine as long as the host never executes the target's code, and vice versa.
\ It would be preferable to keep things simple and avoid implementing wordlists if possible.

\ Core words: dup drop swap + - lshift rshift c, docol dolit bye rx tx find name, :! ; name digit $

\ TODO  Redefine :! to fit the slightly different dictionary structure of the target
\ TODO  Define {, }, and inline inside the target (which means redefining cmove, etc.)
:! dup  { rdx pushq  rdx rax movq } inline ;
:! drop  { rax rdx movq  rdx popq } inline ;
:! 2drop  { rax popq  rdx popq } inline ;
:! swap  { rdx raxxchgq } inline ;
:! over  { rdx pushq  swap } inline ;
:! nip  { rdx popq } inline ;
:! tuck  { rax pushq } inline ;
:! +  { rax rdx addq  drop } inline ;
:! -  { rax rdx subq  drop } inline ;
:! lshift  { rcx pushq  rcx rax movq  rdx clshlq  rcx popq  drop } inline ;
:! rshift  { rcx pushq  rcx rax movq  rdx clshrq  rcx popq  drop } inline ;
:! c,  { stosb  drop } inline ;
:!  ,  { stosq  drop } inline ;
:! !  { rax rdx movq!  2drop } inline ;
:! @  { rax rax movq@ } inline ;
:! c@  { rax rax movzxb@ } inline ;
:! c!  { rax rdx movb!  2drop } inline ;

\ TODO  Fix: These definitions rely on references to words in the host (docol, rax, movq$)
: docol  r> postpone call ;
: dolit  postpone dup postpone rax swap postpone movq$ ;

\ TODO  Another problem: At some point, defer may be needed to handle forward references.
\ It may be worth carefully selecting which words to defer for maximum utility later.

:! start
	rax [ $ 3c ] movq$
	rdi [ $ 4d ] movq$
	syscall

set-entry start
dump-binary
