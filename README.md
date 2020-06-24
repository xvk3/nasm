Repository for storing simple NASM programs

## Programs:

1. hello_world - basic source for a hello world program I found online

2. mem - basic memory manipulation

3. hook - function hooking tests

4. maps - parses /proc/self/maps

## Library:

1. std.asm - general debug and QoL procedures

2. mem.asm - memory manipulation functions

## TODO:

 - [ ] Convert huff_package.asm to assemble under nasm
 - [ ] Improve "printf" fuction in std.asm
 - [ ] Write subroutine to print the value of a register
   - [ ] Dump all registers
 - [ ] Write subroutine to print x bytes of memory
 - [ ] Write subroutine to analyse /proc/self/maps and memory protection/flags
 - [ ] Write subroutine to change memory protection/flags (mprotect wrapper)
