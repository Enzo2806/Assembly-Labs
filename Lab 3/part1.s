.global _start

.equ PIXBUF, 0xc8000000
.equ CHARBUFF, 0xc9000000

_start:
        bl      draw_test_screen
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
	
	LDR R4, =PIXBUF			// Load base address in R4
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
		CMP R1, #240
		ADDLT R1, #1
		BLT Loop2
	
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

draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
