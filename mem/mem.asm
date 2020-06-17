%include "std.asm"

BITS 64
  global _start

_start:

  ; allocate 4096 bytes of RWE memory
	mov	rdi,00h         ; addr   - 0
	mov	rsi,1000h       ; size_t - 4096 / 1000h
	mov	rdx,07h		      ; prot   - PROT_READ(04h) | PROT_WRITE(02h) | PROT_EXEC(01h) = 07h
	mov	r10,22h	        ; flags  - MAP_ANONYMOUS(20h) | MAP_PRIVATE(02h) = 22h
	mov	r8,-1		        ; fd     -  nonce value for an anonymous mapping
	mov	r9,0		        ; offset - nonce value for an anonymous mapping
	mov	rax,9		        ; mmap(2)
	syscall

  ; write "Hello\n\x00" 
  mov byte [rax+00h], 48h
  mov byte [rax+01h], 65h
  mov byte [rax+02h], 6Ch 
  mov byte [rax+03h], 6Ch 
  mov byte [rax+04h], 6Fh 
  mov byte [rax+05h], 0Ah
  mov byte [rax+06h], 00h

  ; write "mov rax, 05; ret"
  mov byte [rax+07h], 48h
  mov byte [rax+08h], 0C7h
  mov byte [rax+09h], 0C0h
  mov byte [rax+0Ah], 05h
  mov byte [rax+0Bh], 00h
  mov byte [rax+0Ch], 00h
  mov byte [rax+0Dh], 00h
  mov byte [rax+0Eh], 0C3h
 
  ; calculate the address of the opcodes written to the buffer 
  lea r15, [rax+07h]

  mov rcx, rax        ; buffer
  call _strlen
  mov rdx, rax        ; move returned length to rdx for printf
  call _printf

  ; call the calculated address
  call r15 

  .exit:
    mov rcx, rax
    call _exit
