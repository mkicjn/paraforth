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


;		Dictionary

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


find:
	; rax => counted string
	; rsi => latest link
	; rax <= xt or null
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

;		Main Subroutine

main:
	pop	rax
	mov	rsi, dict
	mov	rdi, space
	mov	rsp, dstack
	mov	rbp, rstack
	push	rax
	mov	rcx, 99999
.loop:	call	benchmark
	add	rsp, 8
	loop	.loop
	ret


;		Stack Convention

; rax = cached top-of-stack
; rbx = scratch
; rcx = loop counter (preserved!)
; rdx = cached next-on-stack
; rbp = return stack
; rsp = data stack
; rsi = latest link
; rdi = compile area


;		Stack Model
;
; This is separate in case it makes more sense later to change

;	Option 1
;
; Require subroutine prologue and epilogue, but use hardware push/pop for data stack
; + Good memory usage for inlined stack operations (2 bytes for each push/pop)
; - Poor memory usage for highly-factored code (many copies of prologue/epilogue)
; + Better execution performance? No subroutine calls for basic operations.
;
macro ENTER {
	lea	rbp, [rbp-8]
	pop	qword [rbp]
}
macro EXIT {
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

;		Built-Ins


;  : 3*  DUP 1 LSHIFT + ;
;  : 2/  1 RSHIFT ;
;  : COLLATZ  DUP 1 AND IF 3* 1+ ELSE 2/ THEN ;
;  : BENCHMARK  0 3711 BEGIN DUP 1 > WHILE COLLATZ SWAP 1+ SWAP REPEAT DROP ;

macro LIT val {
	DUP
	mov	rax, val
}

lshift:
	ENTER
	push	rcx ;{
	mov	rcx, rax
	sal	rdx, cl
	pop	rcx ;}
	DROP
	EXIT

rshift:
	ENTER
	push	rcx ;{
	mov	rcx, rax
	sar	rdx, cl
	pop	rcx ;}
	DROP
	EXIT

macro ADD_ {
	add	rax, rdx
	pop	rdx
}

link '3*'
mul3:
;	ENTER
;	DUP
;	LIT 1
;	call	lshift
;	ADD_
;	EXIT
	lea	rax, [rax*2+rax]
	ret

link '2/'
div2:
;	ENTER
;	LIT 1
;	call	rshift
;	EXIT
	sar	rax, 1
	ret

macro AND_ {
	and	rax, rdx
	NIP
}

macro COND {
	test	rax, rax
	mov	rax, rdx
	pop	rdx
}

link 'COLLATZ'
collatz:
	ENTER
	DUP
	LIT 1
	AND_
	COND
	jz	.else
	call	mul3
	inc	rax
	jmp	.then
.else:	call	div2
.then:	EXIT

link '>'
gt_:
	ENTER
	cmp	rdx, rax
	setng	al
	dec	al
	movsx	rax, al
	NIP
	EXIT

link 'BENCHMARK'
benchmark:
	ENTER
	LIT 0
	LIT 1412987847
.begin:
	DUP
	LIT 1
	call	gt_

	COND
	jz	.repeat
.while:
	call	collatz
	SWAP
	inc	rax
	SWAP
	jmp	.begin
.repeat:
	DROP
	EXIT
	


;		Memory Map

dict = latest

	rb	1 * 4096
dstack:
	rb	1 * 4096
rstack:

space:
	rb	64 * 4096
