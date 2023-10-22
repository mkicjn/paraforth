format elf64 executable
entry start

; rax = TOS
; rbx = loop counter
; rcx = scratch
; rdx = scratch
;
; rdi = data space pointer
; rsi = link pointer
; rbp = parameter stack
; rsp = return stack

;;;;;;;			System Interface

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
	pop	rsi
	pop	rdi
	pop	rdx
	pop	rcx
.mov:	mov	al, 127 ; self-modifying
	ret


;;;;;;;;		Dictionary

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


;;;;;;;;		Compilation

link "docol"
__docol:
	call	_docol
_docol:
	pop	rdx
	mov	byte [rdi], 0xe8
	add	rdi, 5
	sub	rdx, rdi
	mov	[rdi-4], edx
	ret

link "dolit"
__dolit:
	call	_docol
_dolit:
	call	__dup
	mov	word [rdi], 0xb848
	add	rdi, 2
	ret

link "c,"
__cput:
	call	_docol
_cput:
	stosb
	jmp	_drop

link ";"
__exit:
_exit:
	mov	byte [rdi], 0xc3
	add	rdi, 1
	ret


;;;;;;;;		Stack operations

link "dup"
__dup:
	call	_docol
_dup:
	xchg	rsp, rbp
	push	rax
	xchg	rsp, rbp
	ret

link "drop"
__drop:
	call	_docol
_drop:
	xchg	rsp, rbp
	pop	rax
	xchg	rsp, rbp
	ret


;;;;;;;;		Arithmetic

link "+"
__add:
	call	_docol
_add:
	xchg	rsp, rbp
	pop	rdx
	add	rax, rdx
	xchg	rsp, rbp
	ret

link "lshift"
__lshift:
	call	_docol
_lshift:
	xchg	rsp, rbp
	mov	rcx, rax
	pop	rax
	shl	rax, cl
	xchg	rsp, rbp
	ret


;;;;;;;;		I/O

link "key"
__key:
	call	_docol
_key:
	xchg	rsp, rbp
	call	_dup
	call	sys_rx
	xchg	rsp, rbp
	ret

link "emit"
__emit:
	call	_docol
_emit:
	call	sys_tx
	jmp	_drop


;;;;;;;;		Parsing

next:
	call	sys_rx
	cmp	al, 0x20
	jle	next
	ret

link "name,"
__nameput:
	call	_docol
_nameput:
	push	rax
	inc	rdi
	push	rdi
	call	next
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

link "$"
__hex:
_hex:
	push	rax
	xor	rdx, rdx
	call	next
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
	call	_dolit
	stosq
	pop	rax
	ret


;;;;;;;;		Dictionary

link ":!"
__def:
_def:
	mov	[rdi], rsi
	mov	rsi, rdi
	add	rdi, 8
	jmp	_nameput

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


;;;;;;;;		REPL

link "\";"; ("\")
__comment:
_comment:
	push	rax
.skip:	call	sys_rx
	cmp	al, 0xa
	jne	.skip
	pop	rax
	ret

start:
	lea	rbp, [space]
	lea	rdi, [space]
	mov	rsi, latest
.repl:	push	rax
	push	rdi
	call	_nameput
	pop	rdi
	mov	rax, rdi
	call	_seek
	movzx	ecx, byte [rax+8]
	lea	rdx, [rax+9+rcx]
	pop	rax
	call	rdx
	jmp	.repl


last = latest

	rb 1024*8
space:
	rb 64*4096


display 10, 'Words:', 10, wordlist, 10
