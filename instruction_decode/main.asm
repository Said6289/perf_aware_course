bits 64
default rel

section .data
	usage db "USAGE: %s <file>", 0xd, 0xa, 0
	file_not_found db "File not found.", 0xd, 0xa, 0
	unknown_instruction db "; unknown instruction", 0xd, 0xa, 0
	mode db "rb", 0
	reg_table_w0 db "al", 0, 0, "cl", 0, 0, "dl", 0, 0, "bl", 0, 0, "ah", 0, 0, "ch", 0, 0, "dh", 0, 0, "bh", 0, 0
	reg_table_w1 db "ax", 0, 0, "cx", 0, 0, "dx", 0, 0, "bx", 0, 0, "sp", 0, 0, "bp", 0, 0, "si", 0, 0, "di", 0, 0
	mov_instruction db "mov %s, %s", 0xd, 0xa, 0

section .text

extern fopen
extern fclose
extern fseek
extern ftell
extern fgetc
extern printf

global main
main:
	push rbp
	mov rbp, rsp
	sub rsp, 32 ; allocate shadow space

	cmp rcx, 2
	jl .no_file_specified

	mov rcx, [rdx + 8]
	lea rdx, [mode]
	call fopen ; FILE* is in rax now

	mov rbx, rax ; store FILE* in rbx

	cmp rbx, 0 ; check if FILE* is NULL
	je .could_not_read_file

	; do the fseek(), ftell(); fseek() dance
	mov rcx, rbx
	mov rdx, 0 ; offset = 0
	mov r8, 2  ; origin = SEEK_END
	call fseek

	mov rcx, rbx
	call ftell
	mov rdi, rax
	shr rdi, 1 ; compute number of 2 byte instructions in the file, i.e. divide by 2

	mov rcx, rbx
	mov rdx, 0 ; offset = 0
	mov r8,  0 ; origin = SEEK_SET
	call fseek

.decode_start:
	cmp rdi, 0
	je .decode_end
	mov rcx, rbx
	call decode_mov
	sub rdi, 1
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

decode_mov:
	push rbp
	mov rbp, rsp

	push rbx
	push rsi
	push rdi
	sub rsp, 8 ; align to 16 bytes

	sub rsp, 32 ; shadow space

	mov rsi, rcx ; save 1st argument since it is volatile

	xor rbx, rbx

	; argument already in rcx
	call fgetc
	mov bl, al

	mov rcx, rsi
	call fgetc
	mov bh, al

	; instruction now in bx
	xor rax, rax
	mov al, bl
	and al, 0b11111100 ; mask out opcode

	cmp al, 0b10001000 ; check if it is the mov opcode
	jne .print_unknown_instruction

	mov al, bh
	and al, 0b11000000 ; mask out MOD field
	cmp al, 0b11000000 ; check if is a register to register mov
	jne .print_unknown_instruction

	mov al, bl
	mov ah, bl
	and al, 0b01 ; mask out W bit
	and ah, 0b10 ; mask out D bit

	xor rsi, rsi
	mov si, bx
	and si, 0b0011100000000000 ; mask out REG field
	shr si, 11 ; shift into the least significant bits (8 + 3)

	xor rdi, rdi
	mov di, bx
	and di, 0b0000011100000000 ; mask out R/M field
	shr di, 8

	shl al, 3 ; offset in terms of number of elements

	; set bit 3 which effectively determines the table
	or sil, al
	or dil, al

	cmp ah, 0b10 ; check D bit to know if we should swap registers
	cmovne rax, rsi
	cmovne rsi, rdi
	cmovne rdi, rax

	lea rax, [reg_table_w0]
	lea rcx, [mov_instruction]
	lea rdx, [rax + 4 * rsi]
	lea r8,  [rax + 4 * rdi]
	call printf

	jmp .return

.print_unknown_instruction:
	lea rcx, [unknown_instruction]
	call printf

.return:
	add rsp, 32

	add rsp, 8
	pop rdi
	pop rsi
	pop rbx

	pop rbp

	ret
