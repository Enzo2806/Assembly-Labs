.global _start

.equ PIXBUF, 0xc8000000
.equ CHARBUFF, 0xc9000000
.equ PS2, 0xff200100
.equ yellow, 0xffe0
.equ darkred, 0xf800
.equ white, 0x0000ffff
.equ black, 0x0000

_start:
		BL VGA_clear_charbuff_ASM
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

draw_real_life_flag:
	push    {r4, lr}
	// Draw a rectangle for the blue background
	sub     sp, sp, #8
	ldr     r3, .flags_L32	// use the blue color of the texas flag
	str     r3, [sp]
	mov     r3, #240		// full screen rectangle
	mov     r2, #320
	mov     r1, #0			// starts at (0,0)
	mov     r0, r1
	bl      draw_rectangle  
	
	// Draw all stars of the european flag (12 total)
	// Use the yellow variable storing the 16 bit value for yellow
	// Coordinates were calculated using a photo editing software (see report)
	// Use a radius of 20 for all stars
	LDR r3, =yellow	
	mov r2, #20
	mov r0, #158
	mov r1, #38
	bl draw_star
	
	mov r0, #158
	mov r1, #205
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	mov r0, #199
	mov r1, #50
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	mov r0, #199
	mov r1, #194
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	mov r0, #229
	mov r1, #81
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	mov r0, #229
	mov r1, #163
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	mov r0, #240
	mov r1, #122
	LDR r3, =yellow
	mov r2, #20
	bl draw_star

	mov r0, #116
	mov r1, #50
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	mov r0, #116
	mov r1, #194
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	mov r0, #86
	mov r1, #81
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	mov r0, #86
	mov r1, #163
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	mov r0, #75
	mov r1, #122
	LDR r3, =yellow
	mov r2, #20
	bl draw_star
	
	add sp, sp, #8
	pop {r4, lr}
	BX LR

draw_imaginary_flag:
	push    {r4, lr}
	// Draw a rectangle for the white contour
	sub     sp, sp, #8
	ldr     r3, =white		// use the blue color of the texas flag
	str     r3, [sp]
	mov     r3, #240		// full screen rectangle
	mov     r2, #320
	mov     r1, #0			// starts at (0,0)
	mov     r0, r1
	bl      draw_rectangle  
	
	// Draw a rectangle for the red background
	sub     sp, sp, #8
	ldr     r3, .flags_L32+8	// use the blue color of the texas flag
	str     r3, [sp]
	mov     r3, #200		// full screen rectangle
	mov     r2, #280
	mov     r1, #20			// starts at (0,0)
	mov     r0, r1
	bl      draw_rectangle  
	
	mov r0, #160
	mov r1, #120
	mov R2, #90
	LDR r3, =white
	bl draw_star

	mov r0, #160
	mov r1, #120
	mov R2, #80
	LDR r3, =black
	bl draw_star
	
	mov r0, #160
	mov r1, #120
	mov R2, #60
	LDR r3, =white
	bl draw_star
	
	mov r0, #160
	mov r1, #120
	mov R2, #40
	LDR r3, =black
	bl draw_star
	add sp, sp, #8
	add sp, sp, #8
	pop     {r4, lr}
	BX LR

draw_texan_flag:
        push    {r4,lr}
        sub     sp, sp, #8
        ldr     r3, .flags_L32
        str     r3, [sp]
        mov     r3, #240
        mov     r2, #106
        mov     r1, #0
        mov     r0, r1
        bl      draw_rectangle
        ldr     r4, .flags_L32+4
        mov     r3, r4
        mov     r2, #43
        mov     r1, #120
        mov     r0, #53
        bl      draw_star
        str     r4, [sp]
        mov     r3, #120
        mov     r2, #214
        mov     r1, #0
        mov     r0, #106
        bl      draw_rectangle
        ldr     r3, .flags_L32+8
        str     r3, [sp]
        mov     r3, #120
        mov     r2, #214
        mov     r1, r3
        mov     r0, #106
        bl      draw_rectangle
        add     sp, sp, #8
        pop     {r4, pc}
.flags_L32:
        .word   2911
        .word   65535
        .word   45248

draw_rectangle:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        ldr     r7, [sp, #32]
        add     r9, r1, r3
        cmp     r1, r9
        popge   {r4, r5, r6, r7, r8, r9, r10, pc}
        mov     r8, r0
        mov     r5, r1
        add     r6, r0, r2
        b       .flags_L2
.flags_L5:
        add     r5, r5, #1
        cmp     r5, r9
        popeq   {r4, r5, r6, r7, r8, r9, r10, pc}
.flags_L2:
        cmp     r8, r6
        movlt   r4, r8
        bge     .flags_L5
.flags_L4:
        mov     r2, r7
        mov     r1, r5
        mov     r0, r4
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        cmp     r4, r6
        bne     .flags_L4
        b       .flags_L5
should_fill_star_pixel:
        push    {r4, r5, r6, lr}
        lsl     lr, r2, #1
        cmp     r2, r0
        blt     .flags_L17
        add     r3, r2, r2, lsl #3
        add     r3, r2, r3, lsl #1
        lsl     r3, r3, #2
        ldr     ip, .flags_L19
        smull   r4, r5, r3, ip
        asr     r3, r3, #31
        rsb     r3, r3, r5, asr #5
        cmp     r1, r3
        blt     .flags_L18
        rsb     ip, r2, r2, lsl #5
        lsl     ip, ip, #2
        ldr     r4, .flags_L19
        smull   r5, r6, ip, r4
        asr     ip, ip, #31
        rsb     ip, ip, r6, asr #5
        cmp     r1, ip
        bge     .flags_L14
        sub     r2, r1, r3
        add     r2, r2, r2, lsl #2
        add     r2, r2, r2, lsl #2
        rsb     r2, r2, r2, lsl #3
        ldr     r3, .flags_L19+4
        smull   ip, r1, r3, r2
        asr     r3, r2, #31
        rsb     r3, r3, r1, asr #5
        cmp     r3, r0
        movge   r0, #0
        movlt   r0, #1
        pop     {r4, r5, r6, pc}
.flags_L17:
        sub     r0, lr, r0
        bl      should_fill_star_pixel
        pop     {r4, r5, r6, pc}
.flags_L18:
        add     r1, r1, r1, lsl #2
        add     r1, r1, r1, lsl #2
        ldr     r3, .flags_L19+8
        smull   ip, lr, r1, r3
        asr     r1, r1, #31
        sub     r1, r1, lr, asr #5
        add     r2, r1, r2
        cmp     r2, r0
        movge   r0, #0
        movlt   r0, #1
        pop     {r4, r5, r6, pc}
.flags_L14:
        add     ip, r1, r1, lsl #2
        add     ip, ip, ip, lsl #2
        ldr     r4, .flags_L19+8
        smull   r5, r6, ip, r4
        asr     ip, ip, #31
        sub     ip, ip, r6, asr #5
        add     r2, ip, r2
        cmp     r2, r0
        bge     .flags_L15
        sub     r0, lr, r0
        sub     r3, r1, r3
        add     r3, r3, r3, lsl #2
        add     r3, r3, r3, lsl #2
        rsb     r3, r3, r3, lsl #3
        ldr     r2, .flags_L19+4
        smull   r1, ip, r3, r2
        asr     r3, r3, #31
        rsb     r3, r3, ip, asr #5
        cmp     r0, r3
        movle   r0, #0
        movgt   r0, #1
        pop     {r4, r5, r6, pc}
.flags_L15:
        mov     r0, #0
        pop     {r4, r5, r6, pc}
.flags_L19:
        .word   1374389535
        .word   954437177
        .word   1808407283
draw_star:
        push    {r4, r5, r6, r7, r8, r9, r10, fp, lr}
        sub     sp, sp, #12
        lsl     r7, r2, #1
        cmp     r7, #0
        ble     .flags_L21
        str     r3, [sp, #4]
        mov     r6, r2
        sub     r8, r1, r2
        sub     fp, r7, r2
        add     fp, fp, r1
        sub     r10, r2, r1
        sub     r9, r0, r2
        b       .flags_L23
.flags_L29:
        ldr     r2, [sp, #4]
        mov     r1, r8
        add     r0, r9, r4
        bl      VGA_draw_point_ASM
.flags_L24:
        add     r4, r4, #1
        cmp     r4, r7
        beq     .flags_L28
.flags_L25:
        mov     r2, r6
        mov     r1, r5
        mov     r0, r4
        bl      should_fill_star_pixel
        cmp     r0, #0
        beq     .flags_L24
        b       .flags_L29
.flags_L28:
        add     r8, r8, #1
        cmp     r8, fp
        beq     .flags_L21
.flags_L23:
        add     r5, r10, r8
        mov     r4, #0
        b       .flags_L25
.flags_L21:
        add     sp, sp, #12
        pop     {r4, r5, r6, r7, r8, r9, r10, fp, pc}
input_loop:
        push    {r4, r5, r6, r7, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      draw_texan_flag
        mov     r6, #0
        mov     r4, r6
        mov     r5, r6
        ldr     r7, .flags_L52
        b       .flags_L39
.flags_L46:
        bl      draw_real_life_flag
.flags_L39:
        strb    r5, [sp, #7]
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .flags_L39
        cmp     r6, #0
        movne   r6, r5
        bne     .flags_L39
        ldrb    r3, [sp, #7]    @ zero_extendqisi2
        cmp     r3, #240
        moveq   r6, #1
        beq     .flags_L39
        cmp     r3, #28
        subeq   r4, r4, #1
        beq     .flags_L44
        cmp     r3, #35
        addeq   r4, r4, #1
.flags_L44:
        cmp     r4, #0
        blt     .flags_L45
        smull   r2, r3, r7, r4
        sub     r3, r3, r4, asr #31
        add     r3, r3, r3, lsl #1
        sub     r4, r4, r3
        bl      VGA_clear_pixelbuff_ASM
        cmp     r4, #1
        beq     .flags_L46
        cmp     r4, #2
        beq     .flags_L47
        cmp     r4, #0
        bne     .flags_L39
        bl      draw_texan_flag
        b       .flags_L39
.flags_L45:
        bl      VGA_clear_pixelbuff_ASM
.flags_L47:
        bl      draw_imaginary_flag
        mov     r4, #2
        b       .flags_L39
.flags_L52:
        .word   1431655766