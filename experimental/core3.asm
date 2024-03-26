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

macro ENTER {
	lea	rbp, [rbp-8]
	pop	qword [rbp]
}

macro EXIT {
	push	qword [rbp]
	lea	rbp, [rbp+8]
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
compile: ; takes argument in rdx
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


;;;;;;;;		Arithmetic

link "+"
__add:
	call	_docol
_add:
	pop	rdx
	pop	rcx
	add	rax, rcx
	push	rdx
	ret

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


;;;;;;;;		I/O

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
	mov	dword [rdi], 0xb84850 ; push rax, movabs rax
	add	rdi, 3
	stosq
	pop	rax
	ret



;;;;;;;;		Dictionary

link "link"
__link:
_link:
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

getxt: ; leaves result in rdx
	push	rdi
	call	_nameput
	pop	rdi
	push	rax
	mov	rax, rdi
	call	_seek
;	test	rdx, rdx
;	jz	.q
	movzx	ecx, byte [rax+8]
	lea	rax, [rax+9+rcx]
	mov	rdx, rax
	pop	rax
	ret
;.q:
;	push	rax
;	mov	rax, 0x3f
;	call	_emit
;	jmp	getxt
	

link "{"
__lbrace:
_lbrace:
	call	getxt
	cmp	rdx, __rbrace
	je	.done
	call	compile
	jmp	_lbrace
.done:	ret

link "}"
__rbrace:
_rbrace:
	ret


start:
	lea	rbp, [space]
	lea	rdi, [space]
	mov	rsi, latest
.repl:	call	getxt
	call	rdx
	jmp	.repl

last = latest

	rb 1024*8
space:
	rb 64*4096


display 10, 'Words:', 10, wordlist, 10
