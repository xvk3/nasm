BITS 64
;
; nasm/library/std.asm
;


struc s_stat                ; size = 144 /  90h
    .st_dev         resq 1  ; offset 0   /  00h
    .st_ino         resq 1  ; offset 8   /  08h
    .st_nlink       resq 1  ; offset 16  /  10h
    .st_mode        resd 1  ; offset 24  /  18h
    .st_uid         resd 1  ; offset 28  /  1Ch
    .st_gid         resd 1  ; offset 32  /  20h
    .pad0           resb 4  ; offset 36  /  24h
    .st_rdev        resq 1  ; offset 40  /  28h
    .st_size        resq 1  ; offset 48  /  30h
    .st_blksize     resq 1  ; offset 56  /  38h
    .st_blocks      resq 1  ; offset 64  /  40h
    .st_atime       resq 1  ; offset 72  /  48h
    .st_atime_nsec  resq 1  ; offset 80  /  50h
    .st_mtime       resq 1  ; offset 88  /  58h
    .st_mtime_nsec  resq 1  ; offset 96  /  60h
    .st_ctime       resq 1  ; offset 104 /  68h
    .st_ctime_nsec  resq 1  ; offset 112 /  70h
    .__unused       resb 24 ; offset 120 /  78h
endstruc

struc s_map
  .start       resb 8
  .end         resb 8
  .permissions resb 8
  .flags       resb 8
endstruc

;_getFileSize         - calls sys_stat and returns st_size
;                     - returns st_size on success
;       rcx - filename
_getFileSize:
  sub rsp, 90h
  mov rsi, rsp
  mov rdi, rcx
  mov rax, 04h
  syscall
  mov rax, qword [rsi+30h] 
  add rsp, 90h
  ;30h = stat->st_size offset
  ret
_getFileSize_end:

;_print_self_map      - 
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
  mov rdi, .proc_self_maps
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
  .proc_self_maps: db "/proc/self/maps",0
  .etc_hosts:      db "/etc/hosts",0
_print_self_map_end:

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
_allocate_memory_end:

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
_rcx_to_string_end:

_printf:
; expects a string in rcx and length in rdx
  mov rax, 01h          ; sys_write
  mov rdi, 01h          ; stdout
  mov rsi, rcx          ;
  ;db 0xcc
  syscall
  ret
_printf_end:

_read:
; expects a buffer in rcx and length in rdx
  mov rax, 00h          ; sys_read
  mov rdi, 01h          ; stdin
  mov rsi, rcx          ; buffer
  syscall
  ret
_read_end:

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
_strlen_end:

_exit:
; expects the return code in rcx
  mov rax, 60
  mov rdi, rcx
  syscall
_exit_end:
