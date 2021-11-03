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
	call	drop
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

;	Option 2
;
; No prologue/epilogue required, but must manipulate data stack manually
; - Poor memory usage when inlining stack operations (and, 5 bytes for each call)
; + Good memory usage for highly-factored code (low-cost subroutines)
; + Better call performance? Lower overhead for subroutine calls.
;
; I'm leaning towards this option, but want to do some benchmarks.
; Overall, I think this is more in the spirit of Forth:
; * Simple operation
; * Cheap abstractions (encourages refactoring)
; * Less memory usage
;
macro DPUSH reg {
	lea	rbp, [rbp-8]
	mov	[rbp], reg
}
macro DPOP reg {
	mov	reg, [rbp]
	lea	rbp, [rbp+8]
}
macro RPUSH reg {
	push	reg
}
macro RPOP reg {
	pop	reg
}
; TODO: Make stack operations function calls when using this option.

; TODO: Benchmark for a real comparison between the two options.
;       Probably hand-compile programs for both options.
;       Needs realistic level of stack juggling and subroutine calls.
;       Collatz conjecture? Prime number generation? Others?


;		Stack Operations
;
; (Defined in terms of the above, and each other)

dup_:
	DPUSH	rdx
	mov	rdx, rax
	ret
drop:
	mov	rax, rdx
	DPOP	rdx
	ret
swap:
	xchg	rax, rdx
	ret
nip:
	DPOP	rdx
	ret
tuck:
	DPUSH	rax
	ret
over:
	call	swap
	call	tuck
	ret
rot:
	mov	rbx, rdx
	mov	rdx, rax
	DPOP	rax
	DPUSH	rbx
	ret


;		Built-Ins


;  : 3*  DUP 1 LSHIFT + ;
;  : 2/  1 RSHIFT ;
;  : COLLATZ  DUP 1 AND IF 3* 1+ ELSE 2/ THEN ;
;  : BENCHMARK  0 3711 BEGIN DUP 1 > WHILE COLLATZ SWAP 1+ SWAP REPEAT DROP ;

macro LIT val {
	call	dup_
	mov	rax, val
}

lshift:
	push	rcx ;{
	mov	rcx, rax
	sal	rdx, cl
	pop	rcx ;}
	call	drop
	ret

rshift:
	push	rcx ;{
	mov	rcx, rax
	sar	rdx, cl
	pop	rcx ;}
	call	drop
	ret

link '+'
add_:
	add	rax, rdx
	call	nip
	ret

link '3*'
mul3:
	call	dup_
	LIT 1
	call	lshift
	call	add_
	ret

link '2/'
div2:
	LIT 1
	call	rshift
	ret

link '1+'
add1:
	inc	rax
	ret

link 'AND'
and_:
	and	rax, rdx
	call	nip
	ret

cond:
	mov	rbx, rax
	call	drop
	test	rbx, rbx
	ret

link 'COLLATZ'
collatz:
	call	dup_
	LIT 1
	call	and_
	call	cond
	jz	.else
	call	mul3
	call	add1
	jmp	.then
.else:	call	div2
.then:	ret

link '>'
gt_:
	cmp	rdx, rax
	setng	al
	dec	al
	movsx	rax, al
	call	nip
	ret

link 'BENCHMARK'
benchmark:
	LIT 0
	LIT 1412987847
.begin:
	call	dup_
	LIT 1
	call	gt_

	call	cond
	jz	.repeat
.while:
	call	collatz
	call	swap
	call	add1
	call	swap
	jmp	.begin
.repeat:
	call	drop
	ret
	


;		Memory Map

dict = latest

	rb	1 * 4096
dstack:
	rb	1 * 4096
rstack:

space:
	rb	64 * 4096
