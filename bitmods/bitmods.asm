BITS 64
  global _start

  section .data
    message: db "Xello World!", 10

  section .bss
    buffer: resb 64

  section .text

_start:

  mov rcx, message
  call _strlen
  mov rdx, rax
  call _printf

  mov rcx, message
  mov rdx, 04h
  call _fastBitClear

  mov rcx, message
  call _strlen
  mov rdx, rax
  call _printf

  mov rcx, buffer
  mov rdx, 64
  call _read

  mov rcx, buffer
  call _strlen
  mov rdx, rax
  call _printf

  mov rcx, 0
  call _exit


; expects a pointer in rcx
; expects a bit number in rdx
_fastBitClear:
  
  mov al, byte [lut+rdx]
  and byte [rcx], al
  ret
  lut:
  db 0xFE, 0xFD, 0xFB, 0xF7, 0xEF, 0xDF, 0xBF, 0x7F
  
_printf:
; expect a string in rcx and length in rdx
  mov rax, 01h          ; sys_write
  mov rdi, 01h          ; stdout
  mov rsi, rcx
  syscall
  ret

_read:
; expect a buffer in rcx and length in rdx
  mov rax, 00h          ; sys_read    
  mov rdi, 01h          ; stdin
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
