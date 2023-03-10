%macro __read_second_byte 0
	mov rcx, rsi
	call fgetc

	; save second byte of instruction, now whole instruction is in bx
	mov bh, al
%endmacro

%macro __read_disp 1
	; check MOD field for how many more bytes to fetch
	mov %1, rbx
	and %1, 0b1100000000000000 ; mask out MOD field
	shr %1, 14

	mov di, bx
	and rdi, 0b0000011100000000 ; mask out R/M field
	shr di, 8

	; no displacement or 16-bit displacement
	cmp %1, 0b0
	jne .try_byte_displacement
	cmp rdi, 0b110
	jne .try_byte_displacement
	jmp .word_displacement

	.try_byte_displacement:
	cmp %1, 0b01
	jne .try_word_displacement

	mov rcx, rsi
	call fgetc

	and rax, 0xFF
	movsx rax, al
	shl rax, 16
	or ebx, eax

	jmp .done

	.try_word_displacement:
	cmp %1, 0b10
	jne .done

	.word_displacement:
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

	.done:
%endmacro

%macro __write_mnemonic 0
	lea rcx, [mov_mnemonic]
	call write_string
%endmacro

%macro __write_reg 1
	mov rcx, %1
	mov dl, bl
	and rdx, 0b01 ; W bit
	call write_reg
%endmacro

%macro __write_disp 1-2
	mov rcx, rdi
	mov rdx, %2
	mov r8, rbx
	shr r8, 16
	and r8, 0xFFFF
	call write_disp
%endmacro

%macro __write_comma 0
	lea rcx, [comma]
	call write_string
%endmacro

%macro __write_newline 0
	mov rcx, 0xa
	call putchar
%endmacro

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
	and al, 0b11111110

decode_imm_to_mem:
	cmp al, 0b11000110
	jne decode_reg_to_reg

	__read_second_byte
	__read_disp r12

	; read first data byte
	mov rcx, rsi
	call fgetc
	mov r13, rax

	mov al, bl
	and al, 0b1 ; W bit
	cmp al, 0b1
	jne .done_data_bytes

	; read second data byte
	mov rcx, rsi
	call fgetc
	shl rax, 8
	or r13, rax

	.done_data_bytes:
	mov di, bx
	and rdi, 0b0000011100000000 ; mask out R/M field
	shr di, 8

	__write_mnemonic

	; check if it is the memory to register case
	cmp r12, 0b11
	jne .L0
	__write_disp rdi, r12
	jmp .L1
	.L0:
	__write_reg rdi
	.L1:
	__write_comma

	mov rcx, byte_str
	mov al, bl
	and al, 0b1 ; W bit
	cmp al, 0b1
	mov rax, word_str
	cmove rcx, rax

	call write_string

	lea rcx, [fmt_u16]
	mov rdx, r13
	call printf

	__write_newline

	jmp decode_mov_return_value

decode_reg_to_reg:
	and al, 0b11111100
	cmp al, 0b10001000
	jne decode_imm_to_reg

	__read_second_byte
	__read_disp r12

	mov si, bx
	and rsi, 0b0011100000000000 ; mask out REG field
	shr si, 11 ; shift into the least significant bits (8 + 3)

	mov di, bx
	and rdi, 0b0000011100000000 ; mask out R/M field
	shr di, 8

	; check if it is the memory to register case
	cmp r12, 0b11
	jne decode_mem_to_reg

	mov al, bl
	and al, 0b10 ; mask out D bit
	cmp al, 0b10 ; check D bit to know if we should swap registers
	cmovne rax, rsi
	cmovne rsi, rdi
	cmovne rdi, rax

	__write_mnemonic
	__write_reg rsi
	__write_comma
	__write_reg rdi
	__write_newline

	jmp decode_mov_return_value

decode_mem_to_reg:
	__write_mnemonic

	mov al, bl
	and al, 0b10 ; D bit
	cmp al, 0b10
	jne .swap
	__write_reg rsi
	__write_comma
	__write_disp rdi, r12
	jmp .no_swap
	.swap:
	__write_disp rdi, r12
	__write_comma
	__write_reg rsi

	.no_swap:
	__write_newline

	jmp decode_mov_return_value

decode_imm_to_reg:
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

; rcx = register index [0, 8)
; rdx = 0 -> byte, 1 -> word
write_reg:
	push rbx
	sub rsp, 32

	shl rdx, 3   ; move to bit 3
	or  rcx, rdx ; select table

	; load string into rbx
	lea rax, [reg_table_w0]
	lea rcx, [rax + 4 * rcx]
	call write_string

	add rsp, 32
	pop rbx
	ret

; rcx = equation index [0, 8)
; rdx = MOD [0, 3)
; r8  = displacement in bytes
write_disp:
	push rbx
	push rsi
	push rdi
	sub rsp, 32

	mov rdi, rcx
	mov rbx, rdx
	mov rsi, r8

	mov rcx, '['
	call putchar

	cmp rbx, 0
	jle .no_disp

	lea rax, [disp_table]
	lea rcx, [rax + 8 * rdi]
	call write_string

	cmp rsi, 0
	je .end

	mov rcx, 0x20
	call putchar

	mov rcx, '+'
	mov rax, '-'
	cmp si, 0
	cmovl rcx, rax
	call putchar

	mov rcx, 0x20
	call putchar

	jmp .write_number

	.no_disp:
	cmp rdi, 0b110 ; check for direct address
	je .write_number

	lea rax, [disp_table]
	lea rcx, [rax + 8 * rdi]
	call write_string
	jmp .end

	.write_number:
	lea rcx, [fmt_s16]
	; compute absolute value of dx
	mov rdx, rsi
	sar si, 15
	xor dx, si
	sub dx, si
	call printf

	.end:
	mov rcx, ']'
	call putchar

	add rsp, 32
	pop rdi
	pop rsi
	pop rbx
	ret

; rcx = address of string
write_string:
	push rbx
	sub rsp, 32
	mov rbx, rcx
	.loop:
	movzx rcx, byte [rbx]
	cmp rcx, 0 ; check for null terminator
	je .end
	call putchar
	add rbx, 1
	jmp .loop
	.end:
	add rsp, 32
	pop rbx
	ret
