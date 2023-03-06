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
	jl decode_mov_return

	; save first byte of instruction for later
	mov bl, al

decode_register_to_register:
	and al, 0b11111100
	cmp al, 0b10001000
	jne decode_immediate_to_reg

	mov rcx, rsi
	call fgetc

	; save second byte of instruction, now whole instruction is in bx
	mov bh, al

	; check MOD field for how many more bytes to fetch
	mov r12, rbx
	and r12, 0b1100000000000000 ; mask out MOD field
	shr r12, 14

	; 8-bit displacement
	cmp r12, 0b01
	jne .word_displacement

	mov rcx, rsi
	call fgetc

	and rax, 0xFF
	movsx rax, al
	shl rax, 16
	or ebx, eax

	jmp .no_displacement

	.word_displacement:
	cmp r12, 0b10
	jne .no_displacement

	mov rcx, rsi
	call fgetc

	and rax, 0xFF
	mov r13, rax

	mov rcx, rsi
	call fgetc

	and rax, 0xFF
	shl rax, 8
	or  r13, rax

	shl r13, 16
	or ebx, r13d

	.no_displacement:

	mov si, bx
	and rsi, 0b0011100000000000 ; mask out REG field
	shr si, 11 ; shift into the least significant bits (8 + 3)

	mov di, bx
	and rdi, 0b0000011100000000 ; mask out R/M field
	shr di, 8

	; check if it is the memory to register case
	cmp r12, 0b11
	jne decode_memory_to_register

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

	lea rcx, [mov_reg_to_reg]
	lea rdx, [rax + 4 * rsi]
	lea r8,  [rax + 4 * rdi]
	call printf

	jmp decode_mov_return_value

decode_memory_to_register:
	mov al, bl
	and al, 0b01 ; mask out W bit

	shl al, 3 ; offset in terms of number of elements

	; set bit 3 which effectively determines the table
	or sil, al

	lea rax, [reg_table_w0]
	lea rdx, [rax + 4 * rsi]

	lea rax, [disp_table]
	lea r8,  [rax + 8 * rdi]

	cmp r12, 0
	jne decode_memory_to_register_displacement

	lea rcx, [mov_mem_to_reg]
	call printf

	jmp decode_mov_return_value

decode_memory_to_register_displacement:
	lea rcx, [mov_mem_to_reg_disp]
	mov r9d, ebx
	shr r9d, 16
	call printf

	jmp decode_mov_return_value

decode_immediate_to_reg:
	and al, 0b11110000
	cmp al, 0b10110000
	jne print_unknown_instruction

	; read the second byte of instruction
	mov rcx, rsi
	call fgetc

	; save second byte of instruction
	mov bh, al

	; check W bit
	mov al, bl
	and al, 0b1000
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

	mov al, bl
	and al, 0b00001000 ; mask out W bit

	; set bit 3 which effectively determines the table
	or dil, al

	lea rax, [reg_table_w0]

	lea rcx, [mov_imm_to_reg]
	lea rdx, [rax + 4 * rdi]
	mov r8d, ebx
	shr r8d, 8
	call printf

	jmp decode_mov_return_value

print_unknown_instruction:
	lea rcx, [unknown_instruction]
	call printf

	mov rax, -1
	jmp decode_mov_return

decode_mov_return_value:
	; bh contains the last byte we read from the file
	xor rax, rax
	mov al, bh

decode_mov_return:
	add rsp, 32

	add rsp, 8
	pop rdi
	pop rsi
	pop rbx

	pop rbp

	ret
