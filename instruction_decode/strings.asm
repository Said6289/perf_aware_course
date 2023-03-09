usage db "USAGE: %s <file>", 0xd, 0xa, 0
mode db "rb", 0
file_not_found db "File not found.", 0xd, 0xa, 0

first_line db "; %s disassembly:", 0xd, 0xa, 0
second_line db "bits 16", 0xd, 0xa, 0

unknown_instruction db 0x25, 0x25, `error "encountered unknown instruction"`, 0xd, 0xa, 0

reg_table_w0 db "al", 0, 0, "cl", 0, 0, "dl", 0, 0, "bl", 0, 0, "ah", 0, 0, "ch", 0, 0, "dh", 0, 0, "bh", 0, 0
reg_table_w1 db "ax", 0, 0, "cx", 0, 0, "dx", 0, 0, "bx", 0, 0, "sp", 0, 0, "bp", 0, 0, "si", 0, 0, "di", 0, 0

disp_table:
	db "bx + si", 0
	db "bx + di", 0
	db "bp + si", 0
	db "bp + di", 0
	db "si", 6 dup byte (0)
	db "di", 6 dup byte (0)
	db "bp", 6 dup byte (0)
	db "bx", 6 dup byte (0)

mov_reg_to_reg      db "mov %s, %s",        0xd, 0xa, 0
mov_mem_to_reg      db "mov %s, [%s]",      0xd, 0xa, 0
mov_reg_to_mem      db "mov [%s], %s",      0xd, 0xa, 0
mov_mem_to_reg_disp db "mov %s, [%s %c %hd]", 0xd, 0xa, 0
mov_reg_to_mem_disp db "mov [%s %c %hd], %s", 0xd, 0xa, 0

mov_imm_to_reg db "mov %s, %d", 0xd, 0xa, 0

fmt_s16 db "%hd", 0
fmt_u16 db "%hu", 0
mov_mnemonic db "mov ", 0
comma db ", ", 0
byte_str db "byte ", 0
word_str db "word ", 0
