%include "std.asm"
%include "../library/mem.asm"

BITS 64
  global _start

_start:

  mov rcx, 1000h
  ;4 = exec
  ;2 = write
  ;1 = read
  mov rdx, 07h
  mov r8, 22h
  call _allocate_memory
  mov r15, rax

  sub rsp, 20h
  mov rdx, rsp
  mov rcx, rax
  call _lookupMapByAddress

  mov  r8, qword [rsp+10h]  ; len
  mov rdx, 01h              ; prot
  mov rcx, qword [rsp]      ; addr
  call _mprotect 
 
  sub rsp, 20h
  mov rdx, rsp
  mov rcx, r15
  call _lookupMapByAddress

  .exit:
    mov rcx, rax
    call _exit
