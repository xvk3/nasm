; ----------------------------------------------------------------------------------------
; Writes "Hello, World" to the console using only system calls. Runs on 64-bit Linux only.
; To assemble and run:
;
;     nasm -felf64 hello.asm && ld hello.o && ./a.out
; ----------------------------------------------------------------------------------------
BITS 64
          global    _start
          section   .text

_start:
          mov rcx, message
          call _strlen
          mov rdx, rax
          call _printf

          mov rcx, 0
          call _exit
  
          section   .data
message:  db        "Hello, World! This is a longer string", 10      ; note the newline at the end


_printf:
; expect a string in rcx and length in rdx
  mov rax, 01h
  mov rdi, 01h
  mov rsi, rcx
  syscall
  ret

_strlen:
; expects a NULL terminated string in rcx
; returns length in rax
  push rcx
  xor rax, rax
  _strlen_loop:
    cmp byte [rcx], 00h
    je _strlen_null
    inc rcx
    inc rax
    jmp _strlen_loop
  _strlen_null:
  pop rcx
  ret

_exit:
; expects return code in rcx
  mov rax, 60
  mov rdi, rcx
  syscall
  ret
