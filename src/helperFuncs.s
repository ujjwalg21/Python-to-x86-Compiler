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

    

