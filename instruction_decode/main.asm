bits 64
default rel

section .data
	usage db "USAGE: %s <file>", 0xd, 0xa, 0
	file_not_found db "File not found.", 0xd, 0xa, 0
	unknown_instruction db 0x25, 0x25, `error "encountered unknown instruction"`, 0xd, 0xa, 0
	mode db "rb", 0
	first_line db "; %s disassembly:", 0xd, 0xa, 0
	second_line db "bits 16", 0xd, 0xa, 0
	reg_table_w0 db "al", 0, 0, "cl", 0, 0, "dl", 0, 0, "bl", 0, 0, "ah", 0, 0, "ch", 0, 0, "dh", 0, 0, "bh", 0, 0
	reg_table_w1 db "ax", 0, 0, "cx", 0, 0, "dx", 0, 0, "bx", 0, 0, "sp", 0, 0, "bp", 0, 0, "si", 0, 0, "di", 0, 0
	mov_instruction db "mov %s, %s", 0xd, 0xa, 0
	mov_immediate_to_reg db "mov %s, %u", 0xd, 0xa, 0

section .text

extern fopen
extern fclose
extern fgetc
extern printf

global main
main:
	push rbp
	mov rbp, rsp
	sub rsp, 32 ; allocate shadow space

	cmp rcx, 2
	jl .no_file_specified

	mov rsi, [rdx + 8]

	mov rcx, rsi
	lea rdx, [mode]
	call fopen ; FILE* is in rax now

	mov rbx, rax ; store FILE* in rbx

	cmp rbx, 0 ; check if FILE* is NULL
	je .could_not_read_file

	lea rcx, [first_line]
	mov rdx, rsi
	call printf

	lea rcx, [second_line]
	call printf

	.decode_start:
	mov rcx, rbx
	call decode_mov
	cmp eax, 0
	jl .decode_end
	jmp .decode_start
	.decode_end:

	mov rcx, rbx ; close FILE*
	call fclose

	jmp .return

	.no_file_specified:
	lea rcx, [usage]
	mov rdx, [rdx]
	call printf
	jmp .return

	.could_not_read_file:
	lea rcx, [file_not_found]
	call printf
	jmp .return

	.return:
	add rsp, 32 ; deallocate shadow space
	pop rbp

	xor rax, rax
	ret

%include "decode_mov.asm"
