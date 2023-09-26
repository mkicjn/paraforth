; Assemble with FASM
format elf64 executable
entry start

;			Register Convention
;
; rax = cached top-of-stack value
; rbx = scratch register
; rcx = loop counter register (preserved!)
; rdx = cached next-on-stack value
; rbp = parameter stack pointer
; rsp = return stack pointer
; rsi = dictionary pointer
; rdi = data space pointer (i.e., compile area)

; TODO: Consider rbx as cached next-on-stack

macro PUSHA [arg] {forward push arg}
macro POPA [arg] {reverse pop arg}

macro DPUSH reg {
	lea	rbp, [rbp-8]
	mov	[rbp], reg
}

macro DPOP reg {
	mov	reg, [rbp]
	lea	rbp, [rbp+8]
}


;			System Interface
;
; If this code is ever ported to another OS, hopefully only this section needs to be rewritten.
; To work, the following subroutines should behave the same as on Linux: sys_halt, sys_rx, sys_tx
; (These subroutines are only allowed to clobber rax.)

sys_tx:
	mov	[sys_xcv.mov+1], al
	mov	eax, 1
	jmp	sys_xcv
sys_rx:
	xor	eax, eax
sys_xcv:
	PUSHA rdi, rsi, rdx, rcx, r11
	mov	edi, eax
	lea	rsi, [sys_xcv.mov+1]
	mov	edx, 1
	syscall
	POPA rdi, rsi, rdx, rcx, r11
.mov:	mov	al, 127 ; self-modifying
	ret


;			Program Entry
;
; This is the top level, a sort of read-eval-print loop (minus the print).
; It simply reads names from input, finds them in the dictionary, and executes them.
; No error handling or numerical parsing of any kind is performed here.
;
; This marks the first major deviation from a typical Forth: all words are executed immediately.
; Non-immediate words are implemented by a call to DOCOL, which makes a word postpone itself.

start:
	; See "Memory Map"
	lea	rsi, [dict]
	lea	rbp, [space]
	mov	rdi, rbp
.repl:	call	name
	call	seek
	movzx	rbx, byte [rax+8]
	lea	rbx, [rax+rbx+9]
	call	drop
	call	rbx
	jmp	.repl


;			Dictionary Structure
;
; The dictionary is a series of links placed before their corresponding code.
; Each link is just a pointer to the previous link and a counted string.

; TODO: Experiment with more dictionary types

macro counted str {
local a, b
	db b - a
a:
	db str
b:
}

wordlist equ 10 ; Only used to print list of words at assembly-time

latest = 0

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
; Additionally, there are two clever tricks at play here that underpin the whole system:
; 1. DOCOL compiles a call instruction targeting a subroutine that compiles new call instructions.
;    Notably, it does so by calling this subroutine on itself!
; 2. DOCOL relies on a technique I refer to as the "call before data" pattern.
;    This involves using the return address itself as an implicit subroutine argument!
;
; Combined, this has the effect of "postponing" the rest of the word following the call to DOCOL.

link "DOCOL"
	call	docol
docol: ; ^ Self-application
	pop	rbx
	mov	byte [rdi], 0xe8 ; call
	lea	rdi, [rdi+5]
	sub	rbx, rdi
	mov	dword [rdi-4], ebx ; rel32
	ret

; `DOLIT` is conceptually simpler but compiles much more code. It inlines `DUP` and compiles `movabs rax`, to be followed by a quadword.

link "DOLIT"
	call	docol
dolit:
	mov	dword [rdi],   0xf86d8d48 ; lea rbp, [rbp-8]
	mov	dword [rdi+4], 0x00558948 ; mov [rbp], rdx
	mov	dword [rdi+8], 0xc28948   ; mov rdx, rax
	mov	word [rdi+11], 0xb848     ; movabs rax
	lea	rdi, [rdi+13]
	ret

; Semicolon (`;`) is the simplest. All it does is immediately emit `ret`.

link ";"
	; immediate
semi:
	mov	byte [rdi], 0xc3 ; ret
	inc	rdi
	ret



;			Basic Primitives
;
; These appear to be the minimal set necessary to implement an assembler in Forth.
; This was determined by writing a prototype of the assembler in a different Forth.

; System interface primitives:

link "KEY"
	call	docol
key:
	call	dup_
	jmp	sys_rx

link "EMIT"
	call	docol
emit:
	call	sys_tx
	jmp	drop

; Stack primitives:

link "DUP"
	call	docol
dup_:
	DPUSH	rdx
	mov	rdx, rax
	ret

link "DROP"
	call	docol
drop:
	mov	rax, rdx
	DPOP	rdx
	ret

link "SWAP"
	call	docol
swap:
	xchg	rax, rdx
	; ^ NB. There's a special encoding for xchg rax, r64
	ret

; Arithmetic primitives:

link "+"
	call	docol
plus:
	add	rdx, rax
	jmp	drop

link "-"
	call	docol
minus:
	sub	rdx, rax
	jmp	drop

link "LSHIFT"
	call	docol
lshift:
	mov	rbx, rcx
	mov	ecx, eax
	shl	rdx, cl
	mov	rcx, rbx
	jmp	drop

link "RSHIFT"
	call	docol
rshift:
	mov	rbx, rcx
	mov	ecx, eax
	shr	rdx, cl
	mov	rcx, rbx
	jmp	drop

; Memory primitive:

link "C,"
	call	docol
c_:
	stosb
	jmp	drop


;			Input Parsing
;
; The system interface provides character-wise I/O, but Forth's grammar is more complex (albeit not by much).
; These words handle parsing words and numbers from serial input.

; `NAME,` parses a word from input and compiles its counted string literally.
; In case the trailing space character is significant, it is stored at the data space pointer (without increment).

link "NAME,"
	call	docol
name_:
	; rdi: compilation area
	; rdi += length of counted string for input
	; rbx clobbered
	push	rax ;{ prev val
	push	rdi ;{ len byte
	inc	rdi
.skip:	call	sys_rx
	cmp	al, 0x20 ; ' '
	jbe	.skip
.store:	stosb
	call	sys_rx
	cmp	al, 0x20 ; ' '
	ja	.store
	mov	[rdi], al ; store following space
	pop	rax ;} len byte
	mov	rbx, rdi
	dec	rbx
	sub	rbx, rax
	mov	[rax], bl
	pop	rax ;} prev val
	ret

; `NAME` calls `NAME,` but resets the data pointer so that the string is overwritten later.
; It also places a pointer to the counted string on the parameter stack.
;
; This represents another deviation from a typical Forth in that we avoid using a word buffer.

link "NAME"
	call	docol
name:
	call	dup_
	mov	rax, rdi
	call	name_
	mov	rdi, rax
	ret

; `DIGIT` converts a single digit character into its numeric value.
; All invalid characters ([^0-9a-zA-Z]) result in a digit value >35.

link "DIGIT"
	call	docol
digit:
	; al: digit ASCII character [0-9A-Za-z]
	; rax = digit value (bases 2-36)
	cmp	al, 0x39 ; '9'
	ja	.gt9
	sub	al, 0x30 ; '0'
	jmp	.ret
.gt9:	dec	al
	and	al, 0xdf ; ~0x20; toupper
	sub	al, 0x36 ; 'A'-10-1
.ret:	movzx	eax, al
	ret

; `$` calls `NAME` and parses the string as a hexadecimal number (without error handling).
; Once the number is parsed, it uses DOLIT to compile code that pushes it onto the stack.
;
; This represents yet another deviation from a typical Forth is that numbers aren't parsed automatically.
; This solution is far simpler and avoids the need for BASE by forcing it to be explicit.
;
; Only hexadecimal input is provided, since it's far more useful than decimal for an assembler.

link "$"
	; immediate
hex:
	call	name
	PUSHA rcx, rdx, rsi ;{
	mov	rsi, rax
	lodsb
	movzx	ecx, al
	xor	edx, edx
.loop:	lodsb
	call	digit
	sal	rdx, 4
	or	dl, al
	loop	.loop
	mov	rax, rdx
	POPA rcx, rdx, rsi ;}
	call	dolit
	stosq
	jmp	drop


;			Dictionary Manipulation
;
; These words facilitate dictionary lookups and the creation of new definitions.

link "SEEK"
	call	docol
seek:
	; rax: counted string
	; rsi: latest link
	; rax = xt or null
	; rbx clobbered
	PUSHA	rcx, rdi, rsi
	; load search string length
	movzx	ecx, byte [rax]
	inc	ecx
.loop:	mov	rbx, rsi
	test	rbx, rbx
	jz	.done
	; compare strings
	mov	rdi, rax
	lea	rsi, [rsi+8]
	push	rcx ; {
	repe cmpsb
	pop	rcx ; }
	je	.done
	mov	rsi, [rbx]
	jmp	.loop
.done:	mov	rax, rbx
	POPA	rcx, rdi, rsi
	ret

; Only an immediate defining word is provided.
; Invoking DOCOL manually is good enough until a proper `:` is defined.

link ":!"
	; immediate
def_:
	push	rax ;{
	; store pointer to latest link
	mov	rax, rsi
	mov	rsi, rdi ; update latest link to new location
	stosq
	pop	rax ;}
	; store next name from input
	jmp	name_


;			Memory Map
;
; This is the memory layout of the core, and is mainly relevant during initialization.
; If this isn't enough memory, these numbers can be freely incremented.

	rb	8 * 1024
space: ; Return stack and code space grow in opposite directions from the same point
	rb	4096 * 1024

dict = latest ; Set the initialized dictionary pointer to the latest link


; Show the core wordlist at assembly-time
display 10, 'Words:', 10, wordlist, 10
