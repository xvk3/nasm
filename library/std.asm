BITS 64



struc s_map
  .start       resb 8
  .end         resb 8
  .permissions resb 8
  .flags       resb 8
endstruc

;       rcx - buffer
;       rdx - buffer_size
_print_self_map:

  ; calle preservation
  push r15
  push r14
  push r13

  ; preserve parameters
  push rcx
  mov r13, rcx
  mov r14, rdx

  ; open(pathname, flags, mode)
  mov rdi, proc_self_maps
  mov rsi, 00h          ; flags | O_RDONLY
  mov rdx, 00h          ; mode
  mov rax, 02h          ; open(2)
  syscall

  ; save file descriptor
  mov r15, rax

  ; read(int fd, void* buf, size_t count)
  mov rdi, rax          ; fd (File Descriptor)
  mov rsi, r13          ; buf | preserved parameter
  mov rdx, r14          ; count | preserved parameter
  mov rax, 00h          ; read(2)
  syscall

  ;db 0xcc
  ; read until second " " and trim
  mov rsi, r13
  xor rdx, rdx
  xor rax, rax
  ; parse /proc/self/maps
  .for_each_line:
    ;db 0xcc
    xor rdx, rdx
    mov rax, 00h
    .find_space:
      cmp byte [rsi], " "
      je .found_space
      .first_space:
      inc rsi
      inc rdx
    jmp .find_space
    
    .found_space:
      xor rax, 01h
      jnz .first_space
    
  .printf_line:
    mov rcx, rsi
    sub rcx, rdx
    push rsi
    call _printf
    pop rsi
  ; next line
  .seek:
    cmp byte [rsi], 10
    je .for_each_line
    inc rsi
    jmp .seek



  push rax
  ; write(int fd, void* buf, size_t count)
  ;mov rdi, 01h          ; fd (File Descrptor) | stdout=1
  ;mov rsi, r11          ; buffer
  ;mov rdx, rax          ; bytes read
  ;mov rax, 01h          ; write(2)
  ;syscall
  
  ; close(int fd)
  mov rdi, r15
  mov rax, 03h          ; close(2)
  syscall

  pop rdx
  pop rcx
  pop r13
  pop r14
  pop r15
  ret
  proc_self_maps: db "/proc/self/maps",0
  etc_hosts:      db "/etc/hosts",0


;       rcx - qwSize
;       rdx - qwProtections
;       r8  - qwFlags
_allocate_memory:
  mov rdi, 00h
  mov rsi, rcx
  mov r10, r8
  mov r8, -1
  mov r9, 0
  mov rax, 9
  syscall
  ret

_rcx_to_string:
; converts the value of rcx into the hexadecimal representation
; output string is written to the memory pointed to by rdx
  mov rdi, rdx
  xor rdx, rdx
  
  .loop:
    shl rdx, 08h
    mov dl, cl
    shr rcx, 04h
    and dl, 0Fh
    mov ah, 07h
    add dl, 30h
    cmp dl, 39h
    seta al
    mul ah
    add al, dl
    stosb
    test rcx, rcx
  jnz .loop
    ret

_printf:
; expects a string in rcx and length in rdx
  mov rax, 01h          ; sys_write
  mov rdi, 01h          ; stdout
  mov rsi, rcx          ;
  ;db 0xcc
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
