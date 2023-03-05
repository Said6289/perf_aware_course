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

decode_mov:
	push rbp
	mov rbp, rsp

	push rbx
	push rsi
	push rdi
	sub rsp, 8 ; align to 16 bytes

	sub rsp, 32 ; shadow space

	xor rbx, rbx ; rbx will be used to store the instruction
	mov rsi, rcx ; save 1st argument since it is volatile

	; argument already in rcx
	call fgetc
	cmp eax, 0
	jl .return

	; save first byte of instruction for later
	mov bl, al

	; check for register/memory to/from register
	and al, 0b11111100
	cmp al, 0b10001000
	jne .check_immediate_to_reg

	mov rcx, rsi
	call fgetc

	; save second byte of instruction, now whole instruction is in bx
	mov bh, al

	and al, 0b11000000 ; mask out MOD field
	cmp al, 0b11000000 ; check if is a register to register mov
	jne .print_unknown_instruction

	mov si, bx
	and rsi, 0b0011100000000000 ; mask out REG field
	shr si, 11 ; shift into the least significant bits (8 + 3)

	mov di, bx
	and rdi, 0b0000011100000000 ; mask out R/M field
	shr di, 8

	mov al, bl
	mov ah, bl
	and al, 0b01 ; mask out W bit
	and ah, 0b10 ; mask out D bit

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

	; bh contains the last byte we read from the file
	xor rax, rax
	mov al, bh

	jmp .return

.check_immediate_to_reg:
	and al, 0b11110000
	cmp al, 0b10110000
	jne .print_unknown_instruction

	; read the second byte of instruction
	mov rcx, rsi
	call fgetc

	; save second byte of instruction
	mov bh, al

	; check W bit
	mov al, bl
	and al, 0b00001000
	cmp al, 0
	je .skip_third_byte

	; read the third byte of instruction
	mov rcx, rsi
	call fgetc

	; save third byte of instruction
	and eax, 0xFF
	shl eax, 16
	or  ebx, eax

	.skip_third_byte:
	; mask out REG field
	mov di, bx
	and rdi, 0b111

	shl al, 3 ; offset in terms of number of elements

	; set bit 3 which effectively determines the table
	or dil, al

	lea rax, [reg_table_w0]

	lea rcx, [mov_immediate_to_reg]
	lea rdx, [rax + 4 * rdi]
	mov r8d, ebx
	shr r8d, 8
	call printf

	; bh contains the last byte we read from the file
	xor rax, rax
	mov al, bh

	jmp .return

.print_unknown_instruction:
	lea rcx, [unknown_instruction]
	call printf

	mov rax, -1

.return:
	add rsp, 32

	add rsp, 8
	pop rdi
	pop rsi
	pop rbx

	pop rbp

	ret
