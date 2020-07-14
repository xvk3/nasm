BITS 64
;
; nasm/library/mem.asm
;



; _mprotect           - acts as a wrapper for mprotect
;                     - returns 0 on success
;         rcx - lpAddress - 64bit address
;         rdx - prot      - protections flags
;         r8  - len       - length
_mprotect:
  
  ; preserve caller registers
  push rcx
  push rdx
  push r8
  push r9
  push r10
  push r11
  
  ; rdx is already prot flags
  mov rsi, r8         ; len
  mov rdi, rcx        ; start
  mov rax, 0Ah        ; mprotect(2)
  syscall

  ; restore registers
  pop r11
  pop r10
  pop r9
  pop r8
  pop rdx
  pop rcx
  ret
_mprotect_end:
  

; _lookupMapByAddress - reads /proc/self/maps and populates the supplied s_map
;                       structure with the memory map surrounding lpAddress
;                     - returns 0 on success
;         rcx - lpAddress - 64bit address
;         rdx - lps_map   - pointer to s_map structure / 32bytes of writable memory
_lookupMapByAddress:

  ; preserve caller register
  push rcx            ; lpAddress (passed parameter)
  push r8             ; memory map start address
  push r9             ; memory map end address 
  push r10            ; memory permissions
  push r13            ; /proc/self/maps lpAddres
  push r14            ; file descriptor (fd)
  push r15            ; lpAddress holding register
  push rdx            ; lps_map   (passed parameter)

  ; save lpAddress parameter
  mov r15, rcx

  ; open(pathname, flags, mode)
  mov rdi, .proc_self_maps 
  mov rsi, 00h        ; flags | 0_RDONLY
  mov rdx, 00h        ; mode
  mov rax, 02h        ; open(2)
  syscall

  ; save file descriptor
  mov r14, rax

  ; mmap(addr, len, prot, flags, fd, off)
  xor rdi, rdi        ; addr   - 0
  mov rsi, 1000h      ; len
  mov rdx, 06h        ; prot   - PROT_READ(04h) | PROT_WRITE(02h) = 06h
  mov r10, 22h        ; flags  - MAP_ANONYMOUS(20h) | MAP_PRIVATE(02h) = 22h
  mov  r8, -1h        ; fd     - nonce value for an anonymous mapping  
  mov  r9, 00h        ; offset - nonce value for an anonymous mapping
  mov rdx, 06h        ; prot   - PROT_READ(04h) | PROT_WRITE(02h) = 06h
  mov rax, 09h        ; mmap(2)  
  syscall

  ; check for failure
  cmp rax, -1h        ; MAP_FAILED(-1)
  je .error

  ; save the /proc/self/maps lpAddress
  mov r13, rax

  ; read(int fd, void* buf, size_t count)
  mov rdi, r14        ; fd
  mov rsi, r13        ; buf
  mov rdx, 1000h      ; buf_size
  mov rax, 00h        ; read(2)
  syscall

  ; check for failure
  cmp rax, -1h
  je .error

  ; TODO remove this write when function is complete
  ; write(int fd, char* buf, size_t count)
  mov rcx, r13
  mov rdx, rax        ; return value from sys_read
  mov rdi, 01h        ; stdout
  mov rax, 01h        ; write(2)
  syscall

  ; parse map
  ; r8  = start address
  ; r9  = end address
  ; r10 = protection
  mov rsi, r13
  xor rdx, rdx
  xor rax, rax
  .for_each_line:
    xor r10, r10      ; clear previous maps' permissions
    xor r9, r9        ; clear previous maps' end address
    xor r8, r8        ; clear previous maps' start address
    .next_char:
      lodsb

      ; check for non hexadecimal characters
      cmp al, "-"
      je .break_dash
      cmp al, " "
      je .break_space

      ; finished parsing /proc/self/maps
      cmp al, 00h
      je .fin

      cmp  al, 39h
      ja .alpha
      sub  al, 30h    ; convert from ascii "[0-9]" => 4bit value (eg "6"(36h) => 06h)
      .add_nibble:
        shl rdx, 04h  ; shift the value 4bits to the left
        or   dl, al   ; "add" this nibble to the least significant 4 bits of rdx
        jmp .next_char
      .alpha:
        sub al, 37h   ; convert from ascii "A-Z" => 4bit value (eg "C"(43h) => 0Ch / 12 (decimal)) 
        cmp al, 0Fh   ; if 4bit <= 0Fh (15) then al is a valid nibble
        jbe .add_nibble
      ; fallen through, convert from ascii "a-z" => 4bit value
      ; al has already had 37h subtracted, only 20h to convert to uppercase alpha
        sub al, 20h
        jmp .add_nibble

  .break_space:
    xchg r8, r9       ; [2] after the end address is parsed swap r8, r9
  .break_dash:
    mov  r9, rdx      ; [1] after the start address is parsed, r9 is updated
    xor rdx, rdx
    cmp  al, " "      ; [3] if al == " " then the the program jumped to .break_space
    je .continue      ; [4] continue parsing /proc/self/maps
    jmp .next_char

  .continue:
    cmp r15, r8       ; lpAddress > s_map.start
    jb .seek_to_newline
    cmp r15, r9       ; lpAddress < s_map.end
    jae .seek_to_newline
    pop rdx           ; rdx is no lps_map
    mov qword [rdx], r8
    mov qword [rdx+08h], r9
    sub r9, r8        ; calculate region size
    mov qword [rdx+10h], r9

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
    jne .error_uks
    mov qword [rdx+18h], r10
    xor rax, rax
    jmp .fin

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
    lodsb
    cmp al, 0Ah
    jne .seek_to_newline
    jmp .for_each_line

  .error:
  ; general error
    mov rax, 01h
  .error_uks:
  ; error unknown symbol
  
  .fin:
  
  ; mummap(TODO fill this in) 
  mov rsi, 1000h  ; len
  mov rdi, r13    ; addr
  mov rax, 0Bh    ; munmap(2)
  syscall

  ; close(int fd)
  mov rdi, r14    ; fd
  mov rax, 03h    ; close(2)
  syscall

  pop r15
  pop r14
  pop r13
  pop r10
  pop r9
  pop r8
  pop rcx
  ret
  .proc_self_maps: db "/proc/self/maps",0
_lookupMapByAddress_end:
