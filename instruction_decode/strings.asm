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
