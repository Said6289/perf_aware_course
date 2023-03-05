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

	; counter for number of bytes to fetch
	mov r13, r12
	cmp r13, 2
	mov rax, 0
	cmovg r13, rax ; fetch maximum of 2 bytes

	; fetch al bytes
	.fetch:
	; loop condition
	cmp r13, 0
	jle .fetch_exit
	; read next byte
	mov rcx, rsi
	call fgetc
	; or byte into ebx
	and eax, 0xFF
	mov ecx, 2
	sub ecx, r12d
	shl eax, cl
	or  ebx, eax
	; decrement number of bytes
	sub r13, 1
	jmp .fetch
	.fetch_exit:

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
	mov ah, bl
	and al, 0b01 ; mask out W bit
	and ah, 0b10 ; mask out D bit

	shl al, 3 ; offset in terms of number of elements

	; set bit 3 which effectively determines the table
	or sil, al

	lea rcx, [mov_mem_to_reg]

	lea rax, [reg_table_w0]
	lea rdx, [rax + 4 * rsi]

	lea rax, [disp_table]
	imul rdi, 8 ; stride by 8
	lea r8,  [rax + rdi]

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
