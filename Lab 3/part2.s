.global _start

.equ PIXBUF, 0xc8000000
.equ CHARBUFF, 0xc9000000
.equ PS2, 0xff200100

_start:
        bl      input_loop
end:
        b       end

// draws a point on the screen with the color as indicated in the third argument
// by accessing only the pixel buffer memory. 
// C func: void VGA_draw_point_ASM(int x, int y, short c);
VGA_draw_point_ASM:
	PUSH {R4, R5, R6, LR}
	// Check if the corrdinates given are valid
	CMP R0, #320
	BGE EXIT1
	CMP R1, #240
	BGE EXIT1
	
	LDR R4, =PIXBUF		// Load base address in R4
	LSL R5, R0, #1			// x << 1
	LSL R6, R1, #10			// y << 10
	ORR R4, R4, R5
	ORR R4, R4, R6
	
	STRH R2, [R4]
	
EXIT1:
	POP {R4, R5, R6, LR}
	BX LR
	
// lears (sets to 0) all the valid memory locations in the pixel buffer. 
// It takes no arguments and returns nothing. 
// C func: void VGA_clear_pixelbuff_ASM();
VGA_clear_pixelbuff_ASM:
	PUSH {LR}
	
	// R0 and R1 keep track of the memory location
	MOV R0, #0
	MOV R1, #0
	MOV R2, #0
	
Loop1:
	Loop2:
	BL VGA_draw_point_ASM
	CMP R1, #239
	ADDLE R1, #1
	BLE Loop2
	
	MOV R1, #0
	CMP R0, #320
	ADDLT R0, #1
	BLT Loop1
	
	POP {LR}
	BX LR

// Method to write the ASCII code passed in the third argument (r2) to 
// the screen at the (x, y) coordinates given in the first two arguments (r0 and r1). 
// It stores the value of the third argument at the address 
// calculated with the first two arguments. 
// The subroutine checks that the coordinates supplied are valid, 
// i.e., x in [0, 79] and y in [0, 59]. 
// C func: void VGA_write_char_ASM(int x, int y, char c);
VGA_write_char_ASM:
	PUSH {R4, R5, LR}
	// Check if the corrdinates given are valid
	CMP R0, #80
	BGE EXIT2
	CMP R1, #60
	BGE EXIT2
	
	LDR R4, =CHARBUFF
	LSL R5, R1, #7
	ORR R4, R4, R5
	ORR R4, R4, R0
	
	STRB R2, [R4]
EXIT2:
	POP {R4, R5, LR}
	BX LR
	
// clears (sets to 0) all the valid memory locations in the character buffer. 
// It takes no arguments and returns nothing. 
VGA_clear_charbuff_ASM:
	PUSH {LR}
	// R0 and R1 keep track of the memory location
	MOV R0, #0
	MOV R1, #0
	MOV R2, #0
Loop3:
	Loop4:
		BL VGA_write_char_ASM
		CMP R1, #60
		ADDLE R1, #1
		BLE Loop4
	MOV R1, #0
	CMP R0, #80
	ADDLE R0, #1
	BLE Loop3
	POP {LR}
	BX LR

// Input argument: A memory address in which the data that is read from the PS/2 keyboard will be stored 
// Output argument: Integer that denotes whether the data read is valid or not.
// Description: Method checks the RVALID bit in the PS/2 Data register. 
// If it is valid, then the data from the same register should be stored at the address in the pointer argument,
// and the subroutine should return 1 to denote valid data. 
// If the RVALID bit is not set, then the subroutine should simply return 0.
// C func: int read_PS2_data_ASM(char *data);
read_PS2_data_ASM:
	PUSH {R4, R5, R6, LR}
	LDR R4, =PS2		// Load data register address in R4
	LDR R6, [R4]
	
	LSR R5, R6, #15		// shift data register by 15 to the right
	AND R5, R5, #0x1	// Extract lowest bit (15th bit of R4)
	CMP R5, #1			// Check if RVALID bit was set
	
	MOVNE R0, #0		// if it wasn't set, return 0
	BNE Exit4	
	
	AND R6, R6, #0xFF
	STRB R6, [R0]
	MOV R0, #1
	
Exit4:
	POP {R4, R5, R6, LR}
	BX LR

write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}