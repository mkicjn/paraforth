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

macro PUSHA [arg] {forward push arg}
macro POPA [arg] {reverse pop arg}


;		System Interface
;
; If this tool is ever ported to another OS, hopefully only this section needs rewritten.
; To work, the following subroutines should behave the same as on Linux: sys_halt, sys_rx, sys_tx
; (Both subroutines are only allowed to clobber rax)

sys_halt:
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

macro counted str {
local a, b
	db b - a
a:
	db str
b:
}

latest = 0
macro link str {
	dq latest
	latest = $-8
	counted str
}


;		Stack Model
;
; This implementation has a prologue and epilogue to handle the second stack.
; That way, the hardware push/pop instructions can be used for the data stack.

macro ENTER {
	; Subroutine prologue (use at each entry)
	lea	rbp, [rbp-8]
	pop	qword [rbp]
}
macro EXIT {
	; Subroutine epilogue (use instead of ret)
	push	qword [rbp]
	lea	rbp, [rbp+8]
	ret
}
macro DPUSH reg {
	push	reg
}
macro DPOP reg {
	pop	reg
}
macro RPUSH reg {
	lea	rbp, [rbp-8]
	mov	[rbp], reg
}
macro RPOP reg {
	mov	reg, [rbp]
	lea	rbp, [rbp+8]
}

;		Stack Operations
;
; (Defined in terms of the above, and each other)

macro DUP {
	DPUSH	rdx
	mov	rdx, rax
}
macro DROP {
	mov	rax, rdx
	DPOP	rdx
}
macro SWAP {
	xchg	rax, rdx
	; ^ There's a special encoding for xchg rax, r64
}
macro NIP {
	DPOP	rdx
}
macro TUCK {
	DPUSH	rax
}
macro OVER {
	SWAP
	TUCK
}
macro ROT {
	mov	rbx, rdx
	mov	rdx, rax
	DPOP	rax
	DPUSH	rbx
}


;		Arithmetic/Logic Operations
;
; These appear to be the minimal set necessary to implement an assembler in Forth.
; This was determined over the course of writing proto_asm.fth, which runs in Gforth.

macro ADD {
	add	rax, rdx
	NIP
}
macro SUB {
	sub	rdx, rax
	DROP
}
; Shifts are pretty long. Should they be subroutines?
macro LSHIFT {
	mov	rbx, rcx
	mov	ecx, eax
	shl	rdx, cl
	mov	rcx, rbx
	DROP
}
macro RSHIFT {
	mov	rbx, rcx
	mov	ecx, eax
	shr	rdx, cl
	mov	rcx, rbx
	DROP
}


;		Memory Operations
;
; It turns out that `C,` is the only necessary memory operation to write an assembler.

macro C_ {
	stosb
	DROP
}


;		Program Entry
;
; TODO: Is there a better location for this section?

start:
	; See "Memory Map"
	lea	rsp, [dstack] ; TODO: Consider deletion (relying on system stack)
	lea	rbp, [rstack]
	lea	rsi, [dict]
	lea	rdi, [space] ; TODO: Consider mov rdi, rbp

.loop:	call	name
	call	find
	mov	rbx, rax
	DROP
	call	rbx
	jmp	.loop
; ^ No error checking for now.
; When the compiler gets redefined later, it will be more featureful.


;		Compilation Utilities
;
; These make use of a technique I refer to as the "call before data" pattern.
; This saves some parameter passing by using the return address as an operand.

link '(CALL)'
	call	caller
caller: ; call before data
	pop	rbx
	mov	byte [rdi], 0xe8
	lea	rdi, [rdi+5]
	sub	rbx, rdi
	mov	dword [rdi-4], ebx
	ret

inliner: ; call before data
	pop	rbx
	PUSHA	rcx, rsi ;{
	movzx	ecx, byte [rbx]
	lea	rsi, [rbx+1]
	rep movsb
	POPA	rcx, rsi ;}
	ret

macro INLINE mac {
	local a, b
	call	inliner
	db b - a
a:	mac
b:
}


;		Primitives
;
; These are the fundamental building blocks of the langauge.
; They are inlined automatically for efficiency.
;
; An underscore following the name indicates that the subroutine compiles code.
; This convention is much like much like `,` in Forth.

link 'ENTER'
enter_:	INLINE ENTER
link 'EXIT'
exit_:	INLINE EXIT

link 'DUP'
dup_:	INLINE DUP
link 'DROP'
drop_:	INLINE DROP
link 'SWAP'
swap_:	INLINE SWAP

link '+'
add_:	INLINE ADD
link '-'
sub_:	INLINE SUB
link 'LSHIFT'
lsh_:	INLINE LSHIFT
link 'RSHIFT'
rsh_:	INLINE RSHIFT

link 'C,'
c_:	INLINE C_


;		Built-Ins
;
; This is the remaining critical infrastructure for the seed language.
; These are not inlined because their subroutine calls cannot easily be relocated.

link 'BYE'
	call	caller
bye:	jmp	sys_halt

link 'RX'
	call	caller
rx:	ENTER
	DUP
	call	sys_rx
	EXIT

link 'TX'
	call	caller
tx:	ENTER
	call	sys_tx
	DROP
	EXIT

link 'FIND'
	call	caller
find:	; rax: counted string
	; rsi: latest link
	; rax = xt or null
	PUSHA rcx, rdi, rsi ;{
.loop:	test	rsi, rsi	; null check
	jz	.done
	push	rsi		; push link from rsi
	lea	rsi, [rsi+8]	; get counted str ptr
	movzx	ecx, byte [rsi]	; load count
	inc	ecx		; (include length byte)
	mov	rdi, rax	; load search term
	repe cmpsb
	pop	rdi		; early pop; keep rsi and even the stack
	je	.done
	mov	rsi, [rdi]	; load next link
	jmp	.loop
.done:	mov	rax, rsi	; ret address past string
	POPA rcx, rdi, rsi ;}
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
	lea	rbx, [rdi-1]
	sub	rbx, rax
	mov	[rax], bl
	pop	rax ;} prev val
	ret

link 'DEF'
	; immediate
def_:	mov	[rdi], rsi
	mov	rsi, rdi
	lea	rdi, [rdi+8]
	call	name_
	ret

link 'NAME'
	call	caller
name:	ENTER
	DUP
	mov	rax, rdi
	call	name_
	mov	rdi, rax
	EXIT

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

link 'LITERAL'
	call	caller
lit_:	ENTER
	call	dup_
	mov	word [rdi], 0xb848
	lea	rdi, [rdi+2]
	stosq
	DROP
	EXIT

link '$'
	; immediate
hex_:	ENTER
	DUP
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
	call	lit_
	EXIT


;			Memory Map

dict = latest

	rb	1 * 4096
dstack:
	rb	1 * 4096
rstack:

space:
	rb	64 * 4096
