BITS 64

_printf:
; expects a string in rcx and length in rdx
  mov rax, 01h          ; sys_write
  mov rdi, 01h          ; stdout
  mov rsi, rcx          ;
  syscall
  ret

_read:
; expects a buffer in rcx and length in rdx
  mov rax, 00h          ; sys_read
  mov rdi, 01h          ; stdin
  mov rsi, rcx          ; buffer
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
; expects the return code in rcx
  mov rax, 60
  mov rdi, rcx
  syscall
