format elf64 executable
entry start

;			Register Convention
;
; The current implementation uses 1 cached TOS item and a prologue/epilogue pair + push/pop for the data stack.
; The decision to use this approach was extremely difficult.
; Previous implementations used 2 cached TOS items and operations on rbp as the data stack.
;
; The main reason to use this approach is that it makes the code we generate later shorter and easier to read.
; Plus, a simple benchmark demonstrates better performance with this approach, albeit *barely* outside margin of error.
; This might be due to the smaller code size.

; rax = TOS
; rbx = loop counter
; rcx = scratch
; rdx = scratch
;
; rdi = data space pointer
; rsi = link pointer
; rbp = return stack
; rsp = parameter stack
;
; rbx is used as the loop counter instead of rcx for two reasons:
; * Although the `loop` instruction is nice, it only permits an 8-bit offset, limiting the size of loop bodies.
; * This leaves cl free for shl/shr/sar instructions, which would require stack shuffling otherwise.


;			Subroutine Prologue/Epilogue
;
; These are compiled at runtime to transfer return addresses to and from the return stack.
; This source code doesn't actually need these macros, but they're left here for reference.
;
; The use of lea over add/sub is intentional to avoid altering flags, in case it matters.
; It also makes it easier to spot word boundaries when disassembling code in GDB.

macro ENTER {
	lea	rbp, [rbp-8]
	pop	qword [rbp]
}

macro EXIT {
	push	qword [rbp]
	lea	rbp, [rbp+8]
	ret
}


;			System Interface
;
; If this code is ever ported to another OS, hopefully only this section needs to be rewritten.
; To work, the following subroutines should behave the same as on Linux.
; Among the registers listed in the convention above, these subroutines are only allowed to clobber rax.

sys_tx:
	mov	[sys_xcv.mov+1], al
	mov	eax, 1
	jmp	sys_xcv
sys_rx:
	xor	eax, eax
sys_xcv:
	push	rcx
	push	rdx
	push	rdi
	push	rsi
	mov	edi, eax
	lea	rsi, [sys_xcv.mov+1]
	mov	edx, 1
	syscall
	; Exit on EOF optional but convenient (marked by double semicolons)
	test	eax, eax ;;
	jz	sys_exit ;;
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rcx
.mov:	mov	al, 127 ; self-modifying
	ret
sys_exit: ;;
	mov	eax, 60 ;;
	syscall ;;


;			Dictionary Structure
;
; The dictionary is a series of links placed before their corresponding code.
; Each link is just a pointer to the previous link and a counted string.

macro counted str {
local a, b
	db b - a
a:
	db str
b:
}

latest = 0

wordlist equ 10 ; Only used to print list of words at assembly-time

macro link str {
local next
next:
	dq latest
	latest = next
	counted str
	wordlist equ wordlist, '  ', str, 10
}


;			Compilation Primitives
;
; DOCOL works differently here than in a normal Forth implementation.
; Here, it is used to compile subroutine threaded code (i.e., generate call instructions).
;
; There are two clever tricks at play here that underpin the implementation of DOCOL:
; 1. DOCOL compiles a call instruction targeting a subroutine that compiles new call instructions.
;    Notably, it does so by calling this subroutine on itself.
; 2. DOCOL relies on a technique I refer to as the "call before data" pattern.
;    This involves using the return address itself as an implicit subroutine argument.
;
; Combined, this has the effect of "postponing" the rest of the word following the call to DOCOL.
;
; Note that DOCOL expects to be before the subroutine prologue ENTER, so it can't be called in the middle of a word.
; If it is, it will pull an item off the data stack when it returns, most likely resulting in a segfault.
; We'll have to use `r> compile` to achieve the same effect later and treat DOCOL like ENTER/EXIT.

link "docol"
__docol:
	call	_docol
_docol:
	pop	rdx
compile: ; compile a call instruction to rdx
	mov	byte [rdi], 0xe8 ; call
	add	rdi, 5
	sub	rdx, rdi
	mov	[rdi-4], edx
	ret

link "c,"
__cput:
	call	_docol
_cput:
	pop	rdx
	stosb
	pop	rax
	push	rdx
	ret

link "enter"
__enter:
_enter:
	mov	rdx, 0x00458ff86d8d48 ; ENTER
	mov	[rdi], rdx
	add	rdi, 7
	ret

link "exit"
__exit:
_exit:
exit:
	mov	rdx, 0xc3086d8d480075ff ; EXIT
	mov	[rdi], rdx
	add	rdi, 8
	ret


;			Basic Primitives
;
; These appear to be the minimal set necessary to implement an assembler in Forth.
; This was determined by writing a prototype of the assembler in a different Forth.

; Arithmetic - addition and left shift are necessary to construct the RM/Mod byte and certain opcodes.

link "+"
__add:
	call	_docol
_add:
	pop	rdx
	pop	rcx
	add	rax, rcx
	push	rdx
	ret

; << is normally called LSHIFT, which is fine, but the corresponding RSHIFT is ambiguous about signedness.
; The Verilog-like >> and >>> will be used to distinguish the two later, so this renaming is for consistency.

link "<<"
__lshift:
	call	_docol
_lshift:
	pop	rdx
	mov	rcx, rax
	pop	rax
	shl	rax, cl
	push	rdx
	ret


; I/O - only KEY and EMIT are truly necessary. System calls can be implemented in high-level code later.

link "key"
__key:
	call	_docol
_key:
	pop	rdx
	push	rax
	call	sys_rx
	push	rdx
	ret

link "emit"
__emit:
	call	_docol
_emit:
	pop	rdx
	call	sys_tx
	pop	rax
	push	rdx
	ret


;			Input Parsing
;
; The system interface provides character-wise I/O, but Forth's grammar is more complex (albeit not by much).
; These words handle parsing words and numbers from serial input.

; `NAME,` parses a word from input and compiles its counted string literally.

nextw: ; get the next word character, skipping any whitespace
	call	sys_rx
	cmp	al, 0x20
	jle	nextw
	ret

link "name,"
__nameput:
	call	_docol
_nameput:
	push	rax
	inc	rdi
	push	rdi
	call	nextw
.put:	stosb
	call	sys_rx
	cmp	al, 0x20
	jg	.put
	mov	rcx, rdi
	pop	rdx
	sub	rcx, rdx
	mov	byte [rdx-1], cl
	pop	rax
	ret

; `$` parses the next word as a hexadecimal number (without error handling).
; Once the number is parsed, it compiles code that pushes it onto the stack.
;
; This represents yet another deviation from a typical Forth is that numbers aren't parsed implicitly.
; This solution is far simpler and avoids the need for BASE by forcing it to be explicit.
;
; Only hexadecimal input is provided, since it's far more useful than decimal for an assembler.

link "$"
__hex:
_hex:
	push	rax
	xor	rdx, rdx
	call	nextw
.loop:	cmp	al, 0x39
	ja	.gt9
	sub	al, 0x30
	jmp	.add
.gt9:	dec	al
	and	al, 0xdf
	sub	al, 0x36
.add:	movzx	eax, al
	sal	rdx, 4
	or	rdx, rax
	call	sys_rx
	cmp	al, 0x20
	jg	.loop
	mov	rax, rdx
	mov	dword [rdi], 0xb84850 ; push rax, movabs rax
	add	rdi, 3
	stosq
	pop	rax
	ret


;			Dictionary Manipulation
;
; These words facilitate dictionary lookups and the creation of new definitions.

link "seek"
__seek:
	call	_docol
_seek:
	push	rdi
	push	rsi
.cmp:	mov	rdx, rsi
	test	rdx, rdx
	jz	.done
	add	rsi, 8
	mov	rdi, rax
	movzx	ecx, byte [rdi]
	inc	ecx
	repe cmpsb
	je	.done
	mov	rsi, [rdx]
	jmp	.cmp
.done:	mov	rax, rdx
	pop	rsi
	pop	rdi
	ret

link "link"
__link:
_link:
	mov	[rdi], rsi
	mov	rsi, rdi
	add	rdi, 8
	jmp	_nameput


;			REPL
;
; This is the top level, a sort of read-eval-print loop (minus the print).
; It simply reads names from input, finds them in the dictionary, and executes them.
; No error handling or numerical parsing of any kind is performed here.
;
; This marks the first major deviation from a typical Forth: all words are executed immediately.
; Non-immediate words are implemented by a call to DOCOL, which makes a word postpone itself.

getxt: ; get the next word's XT and leave it in rdx
	push	rdi
	call	_nameput
	pop	rdi
	push	rax
	mov	rax, rdi
	call	_seek
	; The error printing code here (marked by double semicolons) is not strictly necessary but included for ergonomics.
	test	rax, rax ;;
	jz	.notfound ;;
	movzx	ecx, byte [rax+8]
	lea	rax, [rax+9+rcx]
	mov	rdx, rax
	pop	rax
	ret
.notfound: ;;
	xor	ecx, ecx ;;
.type:	cmp	cl, byte [rdi] ;;
	jge	.q ;;
	movzx	eax, byte [rdi+1+rcx] ;;
	call	sys_tx ;;
	inc	ecx ;;
	jmp	.type ;;
.q:	mov	rax, 0x3f ;;
	call	sys_tx ;;
	pop	rax ;;
	call	_comment ;; (skip rest of line)
	jmp	getxt ;;
	
; Like the error printing above, line comments are included just for convenience
link '\' ;;
__comment: ;;
_comment: ;;
	push	rax ;;
.loop:	call	sys_rx ;;
	cmp	al, 0xa ;;
	jne	.loop ;;
	pop	rax ;;
	ret ;;

; Brace syntax `{ ... }` for postponement is another significant non-standard piece of this implementation.
; This just allows the user to postpone several words in a row, but the real significance is what that enables in context of this project.
; By postponing assembler words, we can implement primitive inlining **from the start**, instead of needing more work to get there.
;
; Previous versions of this project had some fairly convoluted Forth code that aimed to implement POSTPONE, and later { and }, ASAP.
; While that was an interesting approach, it became clear after some experimentation this doesn't make the core smaller, just harder to use.
; Including these in the core saves a great deal of arcane boilerplate, and makes the core much more practical to build off of.

link "{"
__lbrace:
_lbrace:
	call	getxt
	cmp	rdx, __rbrace
	je	.done
	call	compile
	jmp	_lbrace
.done:	ret

link "}" ; dummy word for `{` to locate
__rbrace:
_rbrace:
	ret


;			Program Entry
;
; The reason braces don't make the core much bigger is because the REPL already needs all the same pieces already!
; All this does is initialize the registers, then forever invoke getxt and call the result repeatedly.

start:
	lea	rbp, [space]
	lea	rdi, [space]
	mov	rsi, latest
.repl:	call	getxt
	call	rdx
	jmp	.repl


;			Memory Map
;
; This is the location of the return stack and data space, and is only relevant during initialization.
; If this isn't enough memory, these numbers can be freely incremented.
; At least, that's the the easiest way, but a syscall to sbrk can be implemented later if needed.

	rb 8*1024 ; 8KiB return stack
space:
	rb 1*1024*1024 ; 1MiB data space

; Show the core wordlist at assembly-time
display 10, 'Words:', 10, wordlist, 10
