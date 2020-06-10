BITS 64
  global _start

  section .data
    usage   db "Incorrect number of command line parameters",10,0

_start:

  mov r8d, dword [rsp]
  cmp r8d, 03h
  jb .argc_below_3

  xor r9, r9
  .args_loop:
    add r9, 08h
    mov rcx, qword [rsp+r9]
    call _strlen
    mov rdx, rax
    call _printf
    dec r8d
  jnz .args_loop

  jmp .exit

  .argc_below_3:
    mov rcx, usage
    call _strlen
    mov rdx, rax
    call _printf

  .exit:
  mov rcx, 0
  call _exit
  
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
