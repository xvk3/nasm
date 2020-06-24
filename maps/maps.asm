%include "../library/std.asm"

buf_size EQU 2000h

BITS 64
  global _start

_start:

  ; allocate RWE memory
	mov	rdi, 00h        ; addr   - 0
	mov	rsi, buf_size   ; size_t
	mov	rdx, 07h		    ; prot   - PROT_READ(04h) | PROT_WRITE(02h) | PROT_EXEC(01h) = 07h
	mov	r10, 22h	      ; flags  - MAP_ANONYMOUS(20h) | MAP_PRIVATE(02h) = 22h
	mov	r8, -1		      ; fd     -  nonce value for an anonymous mapping
	mov	r9, 0		        ; offset - nonce value for an anonymous mapping
	mov	rax ,9		      ; mmap(2)
	syscall
 
  ; save the buffer address
  mov r15, rax

  ; open(pathname, flags, mode)
  mov rdi, proc_self_maps 
  mov rsi, 00h        ; flags | 0_RDONLY
  mov rdx, 00h        ; mode
  mov rax, 02h        ; open(2)
  syscall

  ; save file descriptor
  mov r14, rax

  ; read(int fd, void* buf, size_t count)
  mov rdi, rax        ; fd (File Descriptor)
  mov rsi, r15        ; buf
  mov rdx, buf_size   ; buf_size
  mov rax, 00h        ; read(2)
  syscall

  ; rax = bytes read
  cmp rax, buf_size
  ja .error

  ; print the full map
  mov rcx, r15
  mov rdx, rax
  call _printf

  ; parse map
  ; r8  = start address
  ; r9  = end address
  ; r10 = protection
  mov rbp, rsp
  mov rsi, r15
  xor rdx, rdx
  xor rax, rax
  .for_each_line:
    xor r10, r10
    xor r9, r9
    xor r8, r8
    .next_char:
    lodsb

    cmp al, "-"
    je .break_dash
    cmp al, " "
    je .break_space
    cmp al, 00h
    je .fin

    cmp al, 39h
    ja .alpha     ; alpha
    sub al, 30h
    jmp .do       ; numeric
    .alpha:
      sub al, 36h ; 54 in decimal (converts ABCDEF -> 10,11,12,13,14,15
      cmp al, 0Fh
      ja .lc_alpha
      jmp .do     ; uppercase alpha
      .lc_alpha:  ; if al > "F" still then it must be a lowercase alpha    
        sub al, 20h

    .do:
      nop
      or dl, al
      shl rdx, 02h
    jmp .next_char

    .break_space:
      xchg r8, r9
    .break_dash:
      mov r9, rdx
      xor rdx, rdx
      cmp al, " "
      je .parse_rwxp
    jmp .next_char

  .parse_rwxp:
    lodsb
    cmp al, "r"
    je .parse_rwxp.r
    cmp al, "w"
    je .parse_rwxp.w
    cmp al, "x"
    je .parse_rwxp.x 
    cmp al, "p"
    je .parse_rwxp.p
    cmp al, "-"
    je .parse_rwxp
    cmp al, " "
    je .seek_to_newline    

    .parse_rwxp.r: 
      or r10, 04h
      jmp .parse_rwxp
    .parse_rwxp.w: 
      or r10, 02h
      jmp .parse_rwxp
    .parse_rwxp.x:
      or r10, 01h
      jmp .parse_rwxp
    .parse_rwxp.p:
      or r10, 08h
      jmp .parse_rwxp
 
  .seek_to_newline:
    push r8
    push r9
    push r10
    .loop:
    lodsb
    cmp al, 0Ah
    je .for_each_line
    cmp al, 00h
    je .fin
    jmp .loop

  .fin:
    nop

  ; TODO parse the value stored on the stack (rbp) and determine the start
  ; and end address of the region containing the address provided in r15 (subject to change)
  ; return struct?
  ; convert maps.asm to a function in /library/mem.asm
 
  ; exit
  jmp .exit
  
  .error:
    mov rcx, error
    call _strlen
    mov rdx, rax
    call _printf

  .exit:
    mov rcx, rax
    call _exit

error: db "Error",10,0
