; Assemble with FASM
format elf64 executable

;		System Interface
;
; The start subroutine is the entry point of this executable:
entry start
; Its only responsibility is to handle entry to and exit from a host OS.
start:
	; Entry from the Linux operating system.
	;
	;	Preconditions:
	; rsp = stack supplied by operating system
	;
	;	Postconditions:
	; sys_exit invoked with main subroutine's eax return value
	call	setup
	call	main
bye:	mov	edi, eax
	mov	eax, 60
	syscall
; The `setup` subroutine later handles runtime initialization,
; and `main` is responsible for the execution of the Forth core.
;
; In this implementation, the only host OS supported is Linux, since
; a Windows version would require changes beyond the simple system I/O.
; Namely, executable generation would be far more complicated.
; Furthermore, as a freestanding OS should be produced at some point,
; supporting more than one surrogate platform would be wasteful.
;
;	Input/Output
;
; Under Linux, all input and output is done by serial I/O, i.e. through a tty.
; In particular, stdin and stdout are used for input and output respectively.
; For other platforms, this paradigm may differ significantly.
; However, a more-or-less "serial" I/O should still exist in some form.
; In general, this should result in init, poll, rx, and tx subroutines.
;
; The Linux definitions follow:
;
macro PUSHA [arg] {forward push arg}
macro POPA [arg] {reverse pop arg}
;
init_io:
	; (LINUX) Initialize I/O interfaces
	;
	;	Preconditions:
	; (none)
	;
	;	Postconditions:
	; I/O interfaces (stdin, stdout) initialized
	ret	; Unimplemented
;
;	
;
stdin_pollfd:
	dd 0	; fd		= STDIN_FILENO
	dw 1	; events	= POLLIN
	dw 0	; revents	(set by kernel)
poll_rx:
	; (LINUX) Poll stdin to see if a character is available
	;
	;	Preconditions:
	; (none)
	;
	;	Postconditions:
	; Value of rax is true if stdin ready; false otherwise
	PUSHA rdx, rdi, rsi, rcx, r11	 ;{
	mov	eax, 7			; syscall no.
	lea	rdi, [stdin_pollfd]	; ufds
	mov	esi, 1			; nfds
	xor	edx, edx		; timeout_msecs
	syscall
	POPA rdx, rdi, rsi, rcx, r11	 ;}
	ret
;
;
; (Linux needs a buffer for read/write syscalls)
byte_buf:
	rb 1
rx_byte:
	; (LINUX) Receive a character from stdin
	;
	;	Preconditions:
	; (none)
	;
	;	Postconditions:
	; Equivalent to eax = getchar()
	PUSHA rdx, rdi, rsi, rcx, r11	 ;{
	xor	eax, eax	; syscall no.	(sys_read)
	xor	edi, edi	; fd		(stdin)
	mov	edx, 1		; count		(1)
	lea	rsi, [byte_buf]	; buf		(byte_buf)
	syscall
	movzx	eax, byte [byte_buf]
	POPA rdx, rdi, rsi, rcx, r11	 ;}
	ret
tx_byte:
	; (LINUX) Transmit a character to stdout
	;
	;	Preconditions:
	; al = character to print
	;
	;	Postconditions:
	; Equivalent to putchar(al)
	; rax clobbered
	PUSHA rdx, rdi, rsi, rcx, r11	 ;}
	lea	rsi, [byte_buf]	; buf		(same buffer as before)
	mov	[rsi], al
	mov	eax, 1		; syscall no.	(sys_write)
	mov	edi, 1		; fd		(stdout)
	mov	edx, 1		; count		(1)
	syscall
	POPA rdx, rdi, rsi, rcx, r11	 ;}
	ret
;
; The remaining I/O subroutines should rely entirely on these primitives.
;



;		Parser
;
; In my opinion, Forth has the simplest grammar of any high-level language.
; In fact, I like to say it has one rule: "Words are delimited by whitespace."
; That's one of the main reasons I chose this language as the core.
;
; Naturally, this grammar is implemented by a single parsing subroutine:
;
parse_name:
	; Skip space, then read a space-delimited word from input into memory
	; ("Space" is defined as ASCII characters less than or equal to ' ')
	;
	;	Preconditions:
	; rdi = address to store word
	;
	;	Postconditions:
	; rax = length of word
.skip:	call	rx_byte
	cmp	eax, 0x20 ; 0x20 = ' '
	jle	.skip
	push	rdi		;{
.loop:	stosb
	call	rx_byte
	cmp	eax, 0x20 ; 0x20 = ' '
	jg	.loop
.done:	mov	rax, rdi
	pop	rdi		;}
	sub	rax, rdi
	ret



;		Forbidden Assembly Techniques
;
; Fair warning: Two advanced assembly techniques will be used in this code.
; These two ideas hinge on manipulation of the return stack,
; which is disallowed by almost every single high level language.
; However, these tricks can be quite useful to keep things "simple."
; Understanding this "black magic" is key to understanding the design.
;
;  1. Call before data
; In this technique, a call instruction is placed before a data region.
; The data region's address will be left on the return stack, and is then
; simply popped off the stack and used as a pointer.
; This is a useful technique for combining code and data, minimizing size.
;
;  2. Return stack as a queue
; This is more like a category of techniques hinging on one observation:
; The return stack is analogous to a queue (of pending operations).
; By this analogy, the queue is traversed by the return instruction.
; Atypical manipulations of this queue have many interesting use cases:
; * Advanced control flow constructs
; * Coroutine implementations
; * Live debugging (stepping word-by-word)
; * etc.
;
; In EXTREMELY rare cases, minor instances of self-modifying code may occur.
; All occurrences of this will be justified and explained where they appear.



;		Dictionary Structure
;
; In this language, all definitions are executed immediately when invoked.
; The difference lies in how these definitions are constructed.
; Each definition is, in essence, a string and a pointer.
; To invoke the definition, simply jmp to the pointer.
; In principle, this leads to two types of definitions:
;
;   * Immediates
; These are sort of the "default", i.e. the general case.
; Immediate words point directly to meaningful program code.
; (I want to run my game, so I type `GAME` and it runs)
;
;   * DOES words
; These are a simple application of the "call before data" technique,
; operating on the same principle as CREATE ... DOES> in a typical Forth.
; In many cases, the "data" will simply be more machine code.
; This is the mechanism for compiling code, resulting in two subcategories:
;     * Callers (compile a call instruction to following code)
;     * Inliners (compile the following code inline)
; Naturally, the call before data technique is extremely flexible.
; By allowing arbitrary calls before data, more variations can be created:
;     * Variables (compile push of return address)
;     * Constants (compile push of literal data)
;     * etc. (same as CREATE ... DOES>)
; For information on how this mechanism looks in code, see "Dispatch Method".
;
;	TODO: Shouldn't the following paragraph be somewhere else?
; Bear in mind that this project's core does not have to be a Forth, per se.
; In principle, the main idea of this project is to create an environment for
; binary code generation that is both convenient and potentially interactive.
; For its power and extreme simplicity, Forth is an excellent starting point.
; In theory, however, the Forth core could be easily replaced by other systems.
;
; For simplicity, the dictionary structure was chosen to be an array.
; The array will grow upwards to minimize executable size (eliminate padding).
; This forces the dictionary lookup to be a backwards linear search.
;
; Each element in the dictionary is structured as follows:
; Byte:		0        1        N         N+8
; Contents:	| Length | String | Pointer |
;
; A fixed max length was chosen as a compromise between several values:
;  * Simplicity: Good. No pointers and simple linear search (but backwards).
;  * Speed: Fair. O(n), but more cache friendly than a linked list.
;     * Does searching latest entries down mean better temporal locality?
;  * Size: Fair. Padding is undesirable, but no "next" pointers.
;  * Compatibility: Good. Alignment always passes; no penalties/exceptions.
; The length bit cuts the string down a byte, but it may be useful later
; if the user wants compiler introspection (i.e. to get the name of an xt).
;
; 32 bytes was chosen as a reasonable size for each definition; thus:
defn_size equ 32		; Feel free to edit this. Keep divisible by 8!
; Thus, every 32KiB = 1024 definitions. Not too bad on size, despite padding.
; To be generous (?) let's allow up to twice as many definitions:
max_defns equ 2048		; Feel free to edit this.
; Ideally it would grow as needed, but simplicity is king in this project.
; With an entry size of 32, this limits distinct names to 23 characters.
; Then again, if you need names to differ beyond "REALLY_REALLY_LONG_NAME"
; then I suppose you have a bigger problem than the compiler's limitations.
; If it's that desparate, then modifying defn_len should work.
;
; The dictionary implementation follows:
;
macro DICTIONARY { dq 0 }
macro DICT_DEFINE str*, lbl*
{
	macro DICTIONARY
	\{
		DICTIONARY
	display	str, 10
	local start, end
		db end-start
	start:
		db str
	end:
		rb defn_size-8-(end-start+1)
		dq lbl
	\}
}

dict_define:
	; Creates a dictionary entry.
	;
	;	Preconditions:
	; rax = name (ptr to counted string)
	; rdx = definition (ptr to code)
	; rsi = top of dictionary
	;
	;	Postconditions:
	; b[rsi..rsi+defn_size-9] = b[rax..rax+b[rax]+1],0...
	; rax = rax+b[rax]+1
	; rsi = rsi+defn_size
	push	rcx			;{
	push	rdi			;{
	; Shuffle values into appropriate regs
	mov	rdi, rsi		;{
	mov	rsi, rax		;{
	xor	rax, rax
	; Zero out dictionary space (may be unnecessary)
	mov	ecx, defn_size/8
	rep stosq
	; Copy name into memory
	push	rdi			;{
	sub	rdi, defn_size
	movzx	ecx, byte [rsi]
	inc	ecx
	rep movsb
	; Copy definition into memory
	pop	rdi			;}
	mov	[rdi-8], rdx
	; Restore register values and return
	mov	rax, rsi		;}
	mov	rsi, rdi		;}
	pop	rdi			;}
	pop	rcx			;}
	ret

dict_search:
	; Searches for a dictionary entry.
	;
	;	Preconditions:
	; rax = name (ptr to counted string)
	; rsi = top of dictionary
	;
	;	Postconditions:
	; rax = definition (ptr to code) or 0 if undefined
	; rbx clobbered
	push	rdi 			;{
	push	rsi			;{
	push	rcx			;{
	; Copy search string ptr into rdi and its length to rbx
	movzx	ebx, byte [rax]
	inc	ebx
	mov	rdi, rax
	; Copy next definition and test for end of dictionary
.loop:	mov	rax, [rsi-8]
	cmp	rax, 0
	jz	.exit
	; Compare names and return if equal
	sub	rsi, defn_size
	mov	ecx, ebx
	repe cmpsb
	je	.exit
	; Else reset string positions and loop
	sub	rcx, rbx
	add	rsi, rcx
	add	rdi, rcx
	jmp	.loop
	; (exit)
.exit:	pop	rcx			;}
	pop	rsi			;}
	pop	rdi			;}
	ret



;		Notes on Code Generation
;
;	Register Convention
;
; Since this software is designed for generating code in general,
; these notes and guidelines are for the included Forth implementation.
;
; The following register convention is used across words in the Forth core:
;	rax: cached top-of-stack
;	rbx: volatile scratch register
;	rdx: cached next-on-stack
;	rcx: non-volatile scratch register (loop counter)
;	rdi: code destination
;	rsi: top of dictionary
;	rsp: data stack (push / pop)
;	rbp: return stack (sub+mov / mov+add)
; The volatility of other registers is undefined.
;
; This information leads to the setup subroutine:
;
setup:
	; Setup subroutine
	;
	;	Preconditions:
	; (none)
	;
	;	Postconditions:
	; Registers set according to convention above
	; rax = 0
	pop	rax			;{ (1)
	lea	rsp, [dstack_start]
	push	rax			;} (1)
	lea	rbp, [rstack_start]
	lea	rdi, [code_start]
	lea	rsi, [dict_start]
	xor	eax, eax
	ret
	;	Notes:
	; (1) Allows for one return after change to rsp.
	;     Thus, this subroutine shouldn't be called outside program entry.
;
; The rdi, rsi, and rcx registers can be used for string instructions,
; but their previous values must be preserved across subroutine calls.
; Compilation subroutines will necessarily modify rdi and rsi.
;
;	Stack Convention
;
; Forth requires at least two stacks, but x86 only supports one.
; Also, we want to use push/pop instructions for data stack.
; Solution: Manually place return addresses on a second stack.
;
; ENTER and EXIT are a subroutine prologue/epilogue pair responsible for this.
; Note that not every subroutine needs to use ENTER and EXIT.
; Rule of thumb:
; * If you need to modify the data stack, use ENTER first.
; * If you use ENTER, then you should use EXIT to return.
macro ENTER {
	; Push return address to stack at rbp
	lea	rbp, [rbp-8]
	pop	qword [rbp]
}
macro EXIT {
	; Pop return address from stack at rbp
	push	qword [rbp]
	lea	rbp, [rbp+8]
	ret
}
;
; Macros for common stack operations are defined here to aid in programming:
;
macro DUP {
	push	rdx
	mov	rdx, rax
}
macro DROP {
	mov	rax, rdx
	pop	rdx
}
macro SWAP {
	xchg	rax, rdx
}
macro OVER {
	push	rdx
	xchg	rax, rdx
}
macro NIP {
	pop	rdx
}
macro TUCK {
	push	rax
}
macro DDUP {
	push	rdx
	push	rax
}
macro DDROP {
	pop	rax
	pop	rdx
}
;
;	Return Stack Manipulation
;
; Ideally, the return stack will only be manipulated sparingly.
; So, it isn't worth swapping the stack registers and using push/pop.
; (This is part of the reason for ENTER and EXIT, defined above.)
; This also simplifies the compiler; there's no question which stack is in rsp.
; The alternative is, of course, sub+mov and mov+add (see Register Convention).
; But, I want to avoid using the ALU, since it might be busy.
; So, I use x86's lea instruction to avoid add and sub:
;
macro TO_R {
	lea	rbp, [rbp-8]
	mov	[rbp], rax
	DROP
}
macro R_FETCH {
	DUP
	mov	rax, [rbp]
}
macro R_DROP {
	lea	rbp, [rbp+8]
}
macro R_FROM {
	R_FETCH
	R_DROP
}
macro TO_TO_R {
	lea	rbp, [rbp-16]
	mov	[rbp], rax
	mov	[rbp+8], rdx
	DDROP
}
macro R_FROM_FROM {
	DDUP
	mov	rax, [rbp]
	mov	rdx, [rbp+8]
	lea	rbp, [rbp+16]
}
;
;	Word Dispatch
;
; As described in the dictionary notes, definitions are a string and pointer.
; That pointer gets jmp'd to when the name is invoked.
; These definitions can compile machine code, which gets executed directly.
;
; This mechanism is simple, and may seem limited compared to traditional Forth.
; In a traditional Forth, definitions have an "immediate" flag, and usually
; a couple other flags (such as "compile-only", etc.)
; Furthermore, a STATE variable decides whether to interpret/compile input.
;
; This Forth is purposefully designed to have none of those.
; But, with a certain assembly trick ("call before data"), there is still
; flexibility to handle complicated situations, such as compiler extensions.
; For more information on these tricks, see "Forbidden Assembly Techniques".
;
; In short, here's how it looks:
;
; Traditional Forth:
;    : WORD  ... ;
;    : WORD-IMM  ... ; IMMEDIATE
;    : WORDX2  ['] WORD1 COMPILE, ['] WORD2 COMPILE, ; IMMEDIATE
;    : WORD-INLINE  ( how? ) ;
; Nuances are handled internally by the interpreter, increasing complexity.
;
; This implementation: (subject to change)
;    : WORD  (CALL) ... ;
;    : WORD-IMM  ... ;
;    : WORDX2  (INLINE) WORD1 WORD2 ;
;    : WORD-INLINE  (INLINE) ... ;
; All words have consistent calling semantics to the interpreter.
; Simpler interpreter, shorter definitions, and WAY more control.
;
; Meanwhile, the words `(CALL)` and `(INLINE)` can be defined simply:
; : (CALL)  R> CALL ;	: (INLINE)  R> INLINE ;
; ...applying the "call before data" technique from before.
; The words `CALL` and `INLINE` are provided by the implementation at first,
; but can be defined in Forth later for bootstrapping purposes.
;
;	Control Flow
;
; Jumps from one section of compiled code to another should be relative.
; This relocatability aids in turnkey application generation.
;
; TODO



;		Numeric Literals
;
; Number conversion subroutines operate on counted strings.
; This is because user input is read as a series of counted strings,
; which is in turn because counted strings are used in the dictionary.
;
; To simplify the interpreter and environment, numeric literals do not exist
; at the language level, and are instead implemented by parsing words.
;
; In a traditional Forth, `10` puts 10 on the stack or compiles DOLIT 10
; (depending on whether STATE indicates interpretation or compilation).
; Here, `# 10` always compiles a push 10 instruction.
; The interpreter can then be far simpler than a traditional Forth, because
; the work is offloaded from the interpreter to the definition of `#`.
;
; TODO: What should happen if the input is invalid? i.e. `# 1A2B3C`
;
cstr_to_r:
	; Convert a counted string to a register-sized integer
	; Conversion occurs in base 10.
	;
	;	Preconditions
	; rax = pointer to counted string
	;
	;	Postconditions
	; rax = true if the conversion was successful, false otherwise
	; rdx = integer value of string
	; rcx clobbered
	;
	;	Notes
	; (1) The reason I keep doing `movzx eax, al` repeatedly is because
	;     I use rax for some arithmetic on each iteration.
	;     If I tried to do `xor eax, eax` at the start to avoid it,
	;     the high bits wouldn't stay cleared; the result would be wrong.
	push	rsi			;{
	mov	rsi, rax
	; Load string length
	lodsb
	movzx	ecx, al
	xor	edx, edx
.loop:	lodsb
	; Convert char to integer
	cmp	al, 0x30 ; '0'
	jl	.done
	cmp	al, 0x39 ; '9'
	jg	.done
	movzx	eax, al			; (1)
	sub	eax, 0x30 ; '0'
	; rdx = rdx * 10 + rax
	sal	rdx, 1
	add	rax, rdx
	sal	rdx, 2
	add	rdx, rax
	loop	.loop
.done:	xor	eax, eax
	test	cl, cl
	setz	al
	pop	rsi			;}
	ret


;		Callers
;
; This is the core compilation mechanism.
; The call-before-data technique is used HEAVILY here.
; 
create_caller:
	; Compile a call to `caller` at rdi.
	;
	;	Preconditions
	; (none)
	;
	;	Postconditions
	; rdi = rdi + 5
	; Memory between old and new values of rdi modified.
	call	caller		; (Beautiful!)
	; NB: Call-before-data applied
caller:
	; Compiles at rdi a call to a subroutine.
	; Best used with the call-before-data technique.
	;
	;	Preconditions
	; Address on stack (to subroutine to call)
	;
	;	Postconditions
	; Address on stack consumed
	; rdi = rdi + 5
	; Memory between old and new values of rdi modified
	; rbx clobbered
	pop	rbx
	mov	byte [rdi], 0xE8
	inc	rdi
	; NB: Intentional fallthrough
put_offset:
	; Compiles a 4-byte offset at rdi
	;
	;	Preconditions
	; Pointer in rbx
	;
	;	Postconditions
	; rdi = rdi + 4
	; rbx = rbx - rdi
	; dword [rdi-4] = ebx
	add	rdi, 4
	sub	rbx, rdi
	mov	dword [rdi-4], ebx
	ret
;
; Note the interesting result above: create_caller calls caller on itself!
;



;		Inliners
;
; This is the foundation of the primitives of this Forth implementation,
; which should be inlined into the code as an optimization.
;
; The same call-before-data technique is used here.
; The first four bytes after the call represent the length of the subroutine.
;
inliner:
	; Inlines a subroutine at rdi
	; Best used with call-before-data technique
	;
	;	Preconditions
	; Address on stack (to doubleword length followed by code)
	; 
	;	Postconditions
	; Address on stack consumed
	; rdi = rdi + dword [[rsp]]
	; Memory between old and new values of rdi modified
	; rbx clobbered
	pop	rbx
	push	rsi			;{
	mov	rsi, rbx
	push	rax			;{
	lodsd
	push	rcx			;{
	mov	ecx, eax
	rep	movsb
	pop	rcx			;}
	pop	rax			;}
	pop	rsi			;}
	ret
; 
; This macro creates a subroutine for inlining the body of a 0-argument macro.
; Basically, a pre-compiled macro for runtime compilation of code.
;
macro INLINE mac {
	call	inliner
	local .start
	local .end
	dd .end - .start
.start:
	mac
.end:
}
;
; Now we can create inliners for all the stack operations from earlier.
; The macro definitions for these are in the section marked "Stack Convention".
;
inline_dup:
	INLINE DUP
DICT_DEFINE 'DUP', inline_dup
;
inline_drop:
	INLINE DROP
DICT_DEFINE 'DROP', inline_drop
;
inline_swap:
	INLINE SWAP
DICT_DEFINE 'SWAP', inline_swap
;
inline_over:
	INLINE OVER
DICT_DEFINE 'OVER', inline_over
;
inline_nip:
	INLINE NIP
DICT_DEFINE 'NIP', inline_nip
;
inline_tuck:
	INLINE TUCK
DICT_DEFINE 'TUCK', inline_tuck
;
inline_ddup:
	INLINE DDUP
DICT_DEFINE 'DDUP', inline_ddup
;
inline_ddrop:
	INLINE DDROP
DICT_DEFINE 'DDROP', inline_ddrop
;
; We can do the same for return stack manipulation words:
;
inline_to_r:
	INLINE TO_R
DICT_DEFINE '>R', inline_to_r
;
inline_r_fetch:
	INLINE R_FETCH
DICT_DEFINE 'R@', inline_r_fetch
;
inline_r_drop:
	INLINE R_DROP
DICT_DEFINE 'RDROP', inline_r_drop
;
inline_r_from:
	INLINE R_FROM
DICT_DEFINE 'R>', inline_r_from
;
inline_to_to_r:
	INLINE TO_TO_R
DICT_DEFINE '>>R', inline_to_to_r
;
inline_r_from_from:
	INLINE R_FROM_FROM
DICT_DEFINE 'R>>', inline_r_from_from
;



;		Forth Core
;
; NB. Execution begins with the `main` subroutine defined in this section.
;
; Subroutines using the Forth calling convention are named with a fth_ prefix
;
; There are, in general, three types of words. Here's how to define them:
; * Callers (regular words)
;   * Start the subroutine with `call caller`.
;   * Write the rest of the subroutine as normal.
; * Inliners (copy into code)
;   * Write a macro containing the code.
;   * Do not use ENTER or EXIT, since it will get copied into the code.
;   * Create a subroutine using the INLINER macro.
; * Immediates (execute instead of compile)
;   * Do none of the above.
; After these steps, use DICT_DEFINE to expose it to the compiler.
;

fth_bye:
	call	caller
	jmp	bye
DICT_DEFINE 'BYE', fth_bye

fth_word: ; ( "word" -- c-addr )
	call	caller
fth_word_imm:
	ENTER
	DUP
	inc	rdi
	call	parse_name
	dec	rdi
	mov	[rdi], al
	mov	rax, rdi
	EXIT
DICT_DEFINE 'WORD', fth_word

fth_find: ; ( c-addr -- xt|0 )
	call	caller
	jmp	dict_search
DICT_DEFINE 'FIND', fth_find

fth_define: ; ( xt c-addr -- )
	call	caller
fth_define_imm:
	ENTER
	call	dict_define
	DDROP
	EXIT
DICT_DEFINE 'DEFINE', fth_define

fth_execute: ; ( i*x xt -- j*x )
	call	caller
fth_execute_imm:
	; ENTER and EXIT not used despite altering the stack.
	; They are worked around instead for optimization purposes.
	mov	rbx, rax
	mov	rax, rdx
	mov	rdx, [rsp+8]
	pop	qword [rsp] ; equivalent to 2>R NIP 2R>
	jmp	rbx ; NB: Tail call to xt
DICT_DEFINE 'EXECUTE', fth_execute

fth_push: ; ( n -- )
	ENTER
	call	inline_dup
	mov	byte [rdi], 0xb8 ; mov eax
	inc	rdi
	stosd ; imm32
	DROP
	EXIT
DICT_DEFINE 'PUSH', fth_push

fth_decimal: ; ( "[0-9]+" -- n )
	ENTER
	call	fth_word_imm
	push 	rdx
	call	cstr_to_r
	DROP ; ignore error
	call	fth_push
	EXIT
DICT_DEFINE '#', fth_decimal

fth_add: ; ( a b -- a+b )
	call	caller
	ENTER
	add	rax, rdx
	NIP
	EXIT
DICT_DEFINE '+', fth_add

macro HERE {
	DUP
	mov	rax, rdi
}
fth_here: ; ( -- addr )
	INLINE HERE
DICT_DEFINE 'HERE', fth_here

fth_int3:
	INLINE int3
DICT_DEFINE 'int3', fth_int3
fth_int3_imm:
	int3
DICT_DEFINE 'int3!', fth_int3_imm

fth_enter:
	INLINE ENTER
DICT_DEFINE 'ENTER', fth_enter

fth_exit:
	INLINE EXIT
DICT_DEFINE 'EXIT', fth_exit

; TODO: Add a mechanism for NOT running the most recently compiled code
;       Probably invoke with `;`

fth_semicolon:
	lea	rsp, [rsp+8] ; drop return address (to reader)
	EXIT
DICT_DEFINE ';', fth_semicolon

fth_colon:
	ENTER
	HERE
	call	fth_word_imm
	call	fth_define_imm
	call 	compiler
	EXIT
DICT_DEFINE ':', fth_colon

main:
	; Call the interpreter over and over forever
	call	interpreter
	jmp	main

interpreter:
	; Compile code, then run it when the user types `;` and loop
	;
	; HERE >R
	ENTER
	lea	rbp, [rbp-8]
	mov	[rbp], rdi
	; ENTER INTERP EXIT
	call	fth_enter
	call	reader ; returns when user types `;`
	call	fth_exit
	; R> DSP!
	mov	rdi, [rbp]
	lea	rbp, [rbp+8]
	; HERE EXECUTE
	call	rdi
	EXIT

compiler:
	; Replace "interpreter" with "compiler", compile code, then return when user types `;`
	;
	ENTER
	lea	rbp, [rbp+32] ; Drop return addresses associated with interpreter
	call	create_caller
	call	fth_enter
	call	reader
	call	fth_exit
	EXIT

reader:
	; Execute words from input in an "infinite" loop
	; (Returns when an immediate word like `;` drops its return address)
	ENTER
.loop:
	call	fth_word_imm
	call	dict_search
	test	rax, rax
	jz	.fail
	call	fth_execute_imm
	jmp	.loop
.fail:
	; TODO: Print offending word, drop remaining input, clear stack
	mov	eax, 0x3F ; '?'
	call	tx_byte
	DROP
	jmp	.loop



;		Memory Map
;
; For simplicity, regions are all fixed sizes adjustable via constants:
code_size equ 64*1024		; Feel free to edit this.
dstack_size equ 64*1024		; Feel free to edit this.
rstack_size equ 64*1024		; Feel free to edit this.
; Dictionary size is adjustable via the constants in that section.
;
; The order of segments is irrelevant, but may impact executable size.
; To avoid padding, the dictionary's initial entries should come first.
;

align 8
dict_bottom:
DICTIONARY
dict_start:
rb (max_defns*defn_size) - (dict_start-dict_bottom)

code_start:
rb code_size

rb dstack_size
dstack_start:

rb rstack_size
rstack_start:
