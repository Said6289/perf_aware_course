bits 64
default rel

section .data
%include "strings.asm"

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
