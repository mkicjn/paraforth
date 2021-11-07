; Assemble with FASM
format elf64 executable
entry start

;		Register Convention
;
; rax = cached top-of-stack
; rbx = scratch
; rcx = loop counter (preserved!)
; rdx = cached next-on-stack
; rbp = return stack
; rsp = data stack
; rsi = latest link (see "Dictionary Structure")
; rdi = compile area

; TODO: Consider rbx as cached next-on-stack

macro PUSHA [arg] {forward push arg}
macro POPA [arg] {reverse pop arg}


;		System Interface
;
; If this tool is ever ported to another OS, hopefully only this section needs rewritten.
; To work, the following subroutines should behave the same as on Linux: sys_halt, sys_rx, sys_tx
; (These subroutines are only allowed to clobber rax)

sys_exit:
	mov	edi, eax
	mov	eax, 60
	syscall

byte_buf:
	rb 1
sys_rx:
	PUSHA rcx, rdx, rsi, rdi, r11 ;{
	xor	eax, eax	; syscall no.	(sys_read)
	xor	edi, edi	; fd		(stdin)
	mov	edx, 1		; count		(1)
	lea	rsi, [byte_buf]	; buf		(byte_buf)
	syscall
	movzx	eax, byte [byte_buf]
	POPA rcx, rdx, rsi, rdi, r11 ;}
	ret
sys_tx:
	PUSHA rcx, rdx, rsi, rdi, r11 ;{
	lea	rsi, [byte_buf]	; buf		(same buffer as before)
	mov	[rsi], al
	mov	eax, 1		; syscall no.	(sys_write)
	mov	edi, 1		; fd		(stdout)
	mov	edx, 1		; count		(1)
	syscall
	POPA rcx, rdx, rsi, rdi, r11 ;}
	ret


;		Dictionary Structure
;
; The dictionary is a series of links placed before their corresponding code.
; Each link is just a pointer to the previous link and a counted string.

; TODO: Experiment with more dictionary types to reduce size

macro counted str {
local a, b
	db b - a
a:
	db str
b:
}

wordlist equ 10 ; Only used for compile-time output of wordlist

end_link:
	dw 0

latest = end_link

macro link str {
local next
next:
	if latest = 0
		dw 0
	else
		dw $ - latest
	end if
	latest = next
	counted str
	wordlist equ wordlist, '  ', str, 10
}


;		Stack Model

macro DPUSH reg {
	lea	rbp, [rbp-8]
	mov	[rbp], reg
}
macro DPOP reg {
	mov	reg, [rbp]
	lea	rbp, [rbp+8]
}

;		Stack Operations
;
; (Defined in terms of the above, and each other)

link 'DUP'
postpone_dup_:
	call	caller
dup_:
	DPUSH	rdx
	mov	rdx, rax
	ret

link 'DROP'
	call	caller
drop_:
	mov	rax, rdx
	DPOP	rdx
	ret

link 'SWAP'
	call	caller
swap_:
	xchg	rax, rdx
	; ^ There's a special encoding for xchg rax, r64
	ret

;		Arithmetic/Logic Operations
;
; These appear to be the minimal set necessary to implement an assembler in Forth.
; This was determined over the course of writing proto_asm.fth, which runs in Gforth.

link '+'
	call	caller
add_:
	add	rax, rdx
	DPOP	rdx
	ret
link '-'
	call	caller
sub_:
	sub	rdx, rax
	jmp	drop_

link 'LSHIFT'
	call	caller
lshift:
	mov	rbx, rcx
	mov	ecx, eax
	shl	rdx, cl
	mov	rcx, rbx
	jmp	drop_

link 'RSHIFT'
	call	caller
rshift:
	mov	rbx, rcx
	mov	ecx, eax
	shr	rdx, cl
	mov	rcx, rbx
	jmp	drop_


;		Memory Operations
;
; It turns out that `C,` is the only necessary memory operation to write an assembler.


link 'C,'
	call	caller
c_:
	stosb
	jmp	drop_


;		Program Entry
;
; TODO: Is there a better location for this section?

start:
	; See "Memory Map"
	lea	rsi, [dict]
	lea	rbp, [space]
	mov	rdi, rbp
.loop:	call	name
	call	find
	mov	rbx, rax
	call	drop_
	call	rbx
	jmp	.loop

;		Compilation Utilities
;
; This makes use of a technique I refer to as the "call before data" pattern.
; This saves some parameter passing by using the return address as an operand.

link 'DOCOL'
	call	caller
caller: ; call before data
	pop	rbx
	mov	byte [rdi], 0xe8
	lea	rdi, [rdi+5]
	sub	rbx, rdi
	mov	dword [rdi-4], ebx
	ret

link 'DOLIT'
	call	caller
dolit:	call	postpone_dup_
	mov	word [rdi], 0xb848
	lea	rdi, [rdi+2]
	ret

;link '['
;open:	push	rdi
;.loop:	call	name
;	call	find
;	mov	rbx, rax
;	call	drop_
;	call	rbx
;	jmp	.loop
;; ^ No error checking for now.
;; When the compiler gets redefined later, it will be more featureful.
;
;link ']'
;close:
;	call	exit_
;	pop	rbx
;	pop	rdi
;	jmp	rdi
;

; Completed TODO: Can the words `[` and `]` be defined in the language itself? A: Yes, easily.
; TODO (follow-up): Investigate using `[` to drive the terminal (i.e. as part of `QUIT`), allowing `]` to execute immediately.
; TODO (follow-up): Figure out a good way to print '[ ' as a prompt (hinting that `]` does something).
; TODO: Add more error handling to `[`, namely printing unknown names with a question mark, skipping the line, and `QUIT`ting.


;		Built-Ins
;
; This is the remaining critical infrastructure for the seed language.
; These are not inlined because their subroutine calls cannot easily be relocated.

link 'BYE'
	call	caller
bye:	jmp	sys_exit

link 'RX'
	call	caller
rx:	call	dup_
	jmp	sys_rx

link 'TX'
	call	caller
tx:	call	sys_tx
	jmp	drop_

link 'FIND'
	call	caller
find:	; rax: counted string
	; rsi: latest link
	; rax = xt or null
	; rbx clobbered
	mov	rbx, rax
	PUSHA rcx, rdi, rsi ;{
	; test offset
.loop:	movzx	eax, word [rsi]
	test	eax, eax
	jz	.fail
	; prepare next link
	mov	rdi, rsi
	sub	rdi, rax
	push	rdi ;{
	; compare strings
	mov	rdi, rbx
	lea	rsi, [rsi+2]
	movzx	ecx, byte [rsi]
	inc	ecx
	rep	cmpsb
	pop	rdi ;}
	je	.succ
	mov	rsi, rdi
	jmp	.loop
.succ:	mov	rax, rsi
.fail:	POPA rcx, rdi, rsi ;}
	ret

link 'NAME,'
	call	caller
name_:	; rdi: compilation area
	; rdi += length of counted name string
	; rbx clobbered
	push	rax ;{ prev val
	push	rdi ;{ len byte
	inc	rdi
.skip:	call	sys_rx
	cmp	al, 0x20
	jbe	.skip
.store:	stosb
	call	sys_rx
	cmp	al, 0x20
	ja	.store
	mov	[rdi], al ; store following space
	pop	rax ;} len byte
	mov	rbx, rdi
	dec	rbx
	sub	rbx, rax
	mov	[rax], bl
	pop	rax ;} prev val
	ret

link ':!'
	; immediate
def_:	push	rax ;{
	mov	rax, rdi
	sub	rax, rsi
	mov	rsi, rdi
	stosw
	pop	rax ;}
	jmp	name_

link ';'
	; immediate
exit_:	mov	byte [rdi], 0xc3
	inc	rdi
	ret

link 'NAME'
	call	caller
name:	call	dup_
	mov	rax, rdi
	call	name_
	mov	rdi, rax
	ret

link 'DIGIT'
	call	caller
digit:	; al: digit ASCII character [0-9A-Za-z]
	; rax = digit value (bases 2-36)
	cmp	al, 0x39 ; '9'
	ja	.gt9
	sub	al, 0x30 ; '0'
	jmp	.ret
.gt9:	dec	al
	and	al, 0xdf ; ~0x20; toupper
	sub	al, 0x36 ; 'A'-10-1
.ret:	movzx	eax, al
	ret ; invalid characters return >35

link '$'
	; immediate
hex:	call	dup_
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
	jmp	drop_


;			Memory Map
display 10, 'Words:', 10, wordlist, 10

dict = latest

	rb	1024 * 8
space: ; Return stack and code space grow in different directions from the same point
	rb	64 * 4096
