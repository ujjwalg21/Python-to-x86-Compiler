	.data 
	integer_format: .asciz, "%ld\n"
	string_format: .asciz, "%s\n"
	.global main
	.text
 
	.str0 :
		.string "SLR name:"
	.str1 :
		.string "CLR name:"
	.str2 :
		.string "LALR name:"
	.str3 :
		.string "LALR"
	.str4 :
		.string "CLR"
	.str5 :
		.string "Shift-Reduce"
	.str6 :
		.string "__main__"
ShiftReduceParser.__init__:
	pushq %rbp
	movq %rsp, %rbp
	pushq %rbx
	pushq %rdi
	pushq %rsi
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	movq 24(%rbp), %rax
	movq 16(%rbp), %rdx
	movq %rax, 0(%rdx)
	add $0, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rsi
	popq %rdi
	popq %rbx
	popq %rbp
	ret 
LR0Parser.__init__:
	pushq %rbp
	movq %rsp, %rbp
	pushq %rbx
	pushq %rdi
	pushq %rsi
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	movq 32(%rbp), %rax
	movq 16(%rbp), %rdx
	movq %rax, 0(%rdx)
	movq 24(%rbp), %rax
	movq 16(%rbp), %rdx
	movq %rax, 16(%rdx)
	add $0, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rsi
	popq %rdi
	popq %rbx
	popq %rbp
	ret 
CLRParser.__init__:
	pushq %rbp
	movq %rsp, %rbp
	pushq %rbx
	pushq %rdi
	pushq %rsi
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	movq 32(%rbp), %rax
	movq 16(%rbp), %rdx
	movq %rax, 0(%rdx)
	movq 24(%rbp), %rax
	movq 16(%rbp), %rdx
	movq %rax, 16(%rdx)
	add $0, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rsi
	popq %rdi
	popq %rbx
	popq %rbp
	ret 
LALRParser.__init__:
	pushq %rbp
	movq %rsp, %rbp
	pushq %rbx
	pushq %rdi
	pushq %rsi
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	movq 40(%rbp), %rax
	movq 16(%rbp), %rdx
	movq %rax, 0(%rdx)
	movq 32(%rbp), %rax
	movq 16(%rbp), %rdx
	movq %rax, 16(%rdx)
	movq 24(%rbp), %rax
	movq 16(%rbp), %rdx
	movq %rax, 32(%rdx)
	add $0, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rsi
	popq %rdi
	popq %rbx
	popq %rbp
	ret 
LALRParser.print_name:
	pushq %rbp
	movq %rsp, %rbp
	pushq %rbx
	pushq %rdi
	pushq %rsi
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	sub $120, %rsp
	leaq .str0(%rip), %rdx
	movq %rdx, -72(%rbp)
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq -72(%rbp)
	call printstr
	add $8, %rsp
	mov %rax, -80(%rbp)
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdx
	popq %rcx
	popq %rax
	movq 16(%rbp), %rdx
	movq 0(%rdx), %rdx
	movq %rdx, -88(%rbp)
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq -88(%rbp)
	call printstr
	add $8, %rsp
	mov %rax, -96(%rbp)
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdx
	popq %rcx
	popq %rax
	leaq .str1(%rip), %rdx
	movq %rdx, -112(%rbp)
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq -112(%rbp)
	call printstr
	add $8, %rsp
	mov %rax, -120(%rbp)
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdx
	popq %rcx
	popq %rax
	movq 16(%rbp), %rdx
	movq 16(%rdx), %rdx
	movq %rdx, -128(%rbp)
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq -128(%rbp)
	call printstr
	add $8, %rsp
	mov %rax, -136(%rbp)
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdx
	popq %rcx
	popq %rax
	leaq .str2(%rip), %rdx
	movq %rdx, -152(%rbp)
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq -152(%rbp)
	call printstr
	add $8, %rsp
	mov %rax, -160(%rbp)
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdx
	popq %rcx
	popq %rax
	movq 16(%rbp), %rdx
	movq 32(%rdx), %rdx
	movq %rdx, -168(%rbp)
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq -168(%rbp)
	call printstr
	add $8, %rsp
	mov %rax, -176(%rbp)
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdx
	popq %rcx
	popq %rax
	add $120, %rsp
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rsi
	popq %rdi
	popq %rbx
	popq %rbp
	ret 
main:
	pushq %rbp
	movq %rsp, %rbp
	pushq %rbx
	pushq %rdi
	pushq %rsi
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	sub $80, %rsp
	leaq .str3(%rip), %rdx
	movq %rdx, -112(%rbp)
	leaq .str4(%rip), %rdx
	movq %rdx, -104(%rbp)
	leaq .str5(%rip), %rdx
	movq %rdx, -96(%rbp)
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq $40
	call allocmem
	add $8, %rsp
	mov %rax, -88(%rbp)
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdx
	popq %rcx
	popq %rax
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq -96(%rbp)
	pushq -104(%rbp)
	pushq -112(%rbp)
	pushq -88(%rbp)
	call LALRParser.__init__
	add $32, %rsp
	mov %rax, -120(%rbp)
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdx
	popq %rcx
	popq %rax
	movq -88(%rbp), %rdx
	movq %rdx, -128(%rbp)
	pushq %rax
	pushq %rcx
	pushq %rdx
	pushq %r8
	pushq %r9
	pushq %r10
	pushq %r11
	pushq -128(%rbp)
	call LALRParser.print_name
	add $8, %rsp
	mov %rax, -136(%rbp)
	popq %r11
	popq %r10
	popq %r9
	popq %r8
	popq %rdx
	popq %rcx
	popq %rax
	movq $60, %rax
	xor %rdi, %rdi
	syscall 

printint:
    pushq	%rbp
    mov	%rsp,	%rbp
    pushq	%rbx
    pushq	%rdi
    pushq	%rsi
    pushq	%r12
    pushq	%r13
    pushq	%r14
    pushq	%r15

    testq $15, %rsp
    jz is_printint_aligned

    pushq $0                 # align to 16 bytes

    lea  integer_format(%rip), %rdi
    movq  16(%rbp), %rsi      
    xor %rax, %rax          
    call printf

    add $8, %rsp
    jmp print_done


is_printint_aligned:

    lea  integer_format(%rip), %rdi
    movq  16(%rbp), %rsi          
    xor %rax, %rax         
    call printf
    jmp print_done
    
printstr:
    pushq	%rbp
    mov	%rsp,	%rbp
    pushq	%rbx
    pushq	%rdi
    pushq	%rsi
    pushq	%r12
    pushq	%r13
    pushq	%r14
    pushq	%r15
    
    testq $15, %rsp
    jz is_printstring_aligned
    
    pushq $0                 # align to 16 bytes
    
    lea  string_format(%rip), %rdi
    movq  16(%rbp), %rsi      
    xor %rax, %rax          
    call printf
    
    add $8, %rsp
    jmp print_done
    
is_printstring_aligned:

    lea  string_format(%rip), %rdi
    movq  16(%rbp), %rsi          
    xor %rax, %rax         
    call printf
    jmp print_done
    
print_done: 
    
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rsi
    popq %rdi
    popq %rbx
    popq %rbp

done:
ret



allocmem:
    pushq %rbp
    mov	%rsp, %rbp
    pushq %rbx
    pushq %rdi
    pushq	%rsi
    pushq	%r12
    pushq	%r13
    pushq	%r14
    pushq	%r15

    testq $15, %rsp
    jz is_mem_aligned

    pushq $0                 # align to 16 bytes
    
    movq 16(%rbp), %rdi
    call malloc

    add $8, %rsp             # remove padding

    jmp mem_done

is_mem_aligned:

    movq 16(%rbp), %rdi
    call malloc
   
mem_done: 

    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rsi
    popq %rdi
    popq %rbx
    popq %rbp

    ret

    

