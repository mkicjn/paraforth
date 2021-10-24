format elf64 executable
entry start

start:
	call	main
stop:
	mov	edi, eax
	mov	eax, 60
	syscall


;		Serial I/O

macro PUSHA [arg] {forward push arg}
macro POPA [arg] {reverse pop arg}

byte_buf:
	rb 1
rx_byte:
	PUSHA rdx, rdi, rsi, rcx, r11 ;{
	xor	eax, eax	; syscall no.	(sys_read)
	xor	edi, edi	; fd		(stdin)
	mov	edx, 1		; count		(1)
	lea	rsi, [byte_buf]	; buf		(byte_buf)
	syscall
	movzx	eax, byte [byte_buf]
	POPA rdx, rdi, rsi, rcx, r11 ;}
	ret
tx_byte:
	PUSHA rdx, rdi, rsi, rcx, r11 ;{
	lea	rsi, [byte_buf]	; buf		(same buffer as before)
	mov	[rsi], al
	mov	eax, 1		; syscall no.	(sys_write)
	mov	edi, 1		; fd		(stdout)
	mov	edx, 1		; count		(1)
	syscall
	POPA rdx, rdi, rsi, rcx, r11 ;}
	ret


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


;		Dictionary Structure
;
; The dictionary is a series of links placed before their corresponding code.
; Each link is just a pointer to the previous link and a counted string.

macro counted str {
local start, end
	db end-start
start:
	db str
end:
}

latest = 0
macro link str {
	dq latest
	latest = $-8
	counted str
}


;		Stack Model

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

;		Main Subroutine

main:
	xor	eax, eax
	xor	ecx, ecx
	xor	edx, edx
	xor	ebx, ebx
	; See "Memory Map"
	lea	rsp, [dstack]
	lea	rbp, [rstack]
	lea	rsi, [dict]
	lea	rdi, [space]

	mov	rcx, rdi ; See link '.'
.loop:	call	name
	call	find
	mov	rbx, rax
	DROP
	call	rbx
	jmp	.loop


;		Temporary Words
;
; These words may not exist in the same form in the future.

link '.' ; Runs anonymously compiled code
	; immediate
dot:	call	exit_
	mov	rdi, rcx
	jmp	rcx

link 'int3'
	; immediate
imm_int3:
	int3
	ret


;		Compilation Utilities

link 'CALLER'
	call	caller
caller:
	pop	rbx
	lea	rdi, [rdi+5]
	sub	rbx, rdi
	mov	byte [rdi-5], 0xe8
	mov	dword [rdi-4], ebx
	ret

inliner:
	pop	rbx
	PUSHA	rcx, rsi ;{
	movzx	ecx, byte [rbx]
	lea	rsi, [rbx-5]
	sub	rsi, rcx
	rep movsb
	POPA	rcx, rsi ;}
	ret

macro INLINE mac {
	local .again, .then
	jmp	.then
.again:	mac
.then:	call	inliner ; doesn't return
	db .then - .again
}
; ^ Later, I will want it to work like this:
;   : CALLER  R> CALL$ ;
;   : INLINE  CALLER OVER - HERE MOVE ; IMMEDIATE
;   : INLINE{  POSTPONE AHEAD HERE SWAP ; IMMEDIATE
;   : }INLINE  HERE SWAP POSTPONE THEN 2LITERAL INLINE ; IMMEDIATE


;		Primitives
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


;		Built-Ins
;

link 'BYE'
	call	caller
bye:	jmp	stop

link 'RX'
	call	caller
rx:	ENTER
	DUP
	call	rx_byte
	EXIT

link 'TX'
	call	caller
tx:	ENTER
	call	tx_byte
	DROP
	EXIT

link 'FIND'
	call	caller
find:	; rax: counted string
	; rsi: latest link
	; rax = xt or null
	PUSHA rcx, rdi, rsi ;{
	; TODO: Try caching string length for resetting search strings, as in fth.asm. Might save instructions?
.loop:	test	rsi, rsi	; null check
	jz	.done
	push	rsi		; push link from rsi
	add	rsi, 8		; get counted str ptr
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
.skip:	call	rx_byte
	cmp	al, 0x20
	jle	.skip
.store:	stosb
	call	rx_byte
	cmp	al, 0x20
	jg	.store
	mov	[rdi], al ; store following space
	pop	rax ;} len byte
	lea	rbx, [rdi-1]
	sub	rbx, rax
	mov	[rax], bl
	pop	rax ;} prev val
	ret

link ':'
	; immediate
col_:	mov	[rdi], rsi
	mov	rsi, rdi
	lea	rdi, [rdi+8]
	call	name_
	call	enter_
	ret

link ';'
	; immediate
scol_:	call	exit_
	mov	rcx, rdi ; See link '.'
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
	jg	.gt9
	sub	al, 0x30 ; '0'
	jmp	.ret
.gt9:	dec	al
	and	al, 0xdf ; ~0x20; toupper
	sub	al, 0x36 ; 'A'-10-1
.ret:	movsx	rax, al
	ret ; invalid characters return <0 or >35

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

link 'C,'
	call	caller
c_:	ENTER
	stosb
	DROP
	EXIT


;			Memory Map

dict = latest

	rb	1 * 4096
dstack:
	rb	1 * 4096
rstack:

space:
	rb	64 * 4096
