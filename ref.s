format elf64 executable

test_label:
	nop
	nop
	nop
	nop
	nop
	nop

	mov	rax, rbx
	mov	[rax], rbx
	mov	rax, [rbx]

	mov	rsi, rdi

	mov	rax, rbx
	mov	rax, [rbx]
	mov	[rax], rbx

	mov	[rax], bl
	movzx	rax, byte [rbx]

	xchg	rax, rax
	xchg	rax, rcx
	xchg	rax, rdx
	xchg	rax, rbx
	xchg	rdi, rsi

	mov	rax, 0xdeadbeefdeadbeef

	sub	rcx, 0xdead
	add	rdx, 0xdead

	call	test_label
	call	rcx

	cmp	rdi, rax

	jmp	near test_label
	jz	near test_label

	add	rax, rbx
	sub	rax, rbx

	mul	rbx
	div	rbx

	repe cmpsb

	dec	rcx
	inc	rcx

	ret
