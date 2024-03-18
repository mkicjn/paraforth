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

macro ENTRY {
	sub	rbp, 8
	pop	qword [rbp]
}

macro EXIT {
	push	qword [rbp]
	add	rbp, 8
	ret
}

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
	mov	rbx, 0xc308c583480075ff ; EXIT
	mov	[rdi], rbx
	add	rdi, 8
	ret


;;;;;;;;		Stack operations

link "dup"
__dup:
	call	_docol
_dup:
	ENTRY
	push	rax
	EXIT

link "drop"
__drop:
	call	_docol
_drop:
	ENTRY
	pop	rax
	EXIT


;;;;;;;;		Arithmetic

link "+"
__add:
	call	_docol
_add:
	ENTRY
	pop	rdx
	add	rax, rdx
	EXIT

link "lshift"
__lshift:
	call	_docol
_lshift:
	ENTRY
	mov	rcx, rax
	pop	rax
	shl	rax, cl
	EXIT


;;;;;;;;		I/O

link "key"
__key:
	call	_docol
_key:
	ENTRY
	call	_dup
	call	sys_rx
	EXIT

link "emit"
__emit:
	call	_docol
_emit:
	call	sys_tx
	jmp	_drop


;;;;;;;;		Parsing

nextw:
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
	call	_nameput
	mov	rbx, 0x00458f08ed8348 ; ENTRY
	mov	[rdi], rbx
	add	rdi, 7
	ret

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
	cmp	rax, 0
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
