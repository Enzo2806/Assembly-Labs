.global _start

.equ HEX0, 0x00000001
.equ HEX1, 0x00000002
.equ HEX2, 0x00000004
.equ HEX3, 0x00000008
.equ HEX4, 0x00000010
.equ HEX5, 0x00000020
.equ SEG1, 0xFF200020	// Base address of the 7 segments for HEX0 to HEX3 displays
.equ SEG2, 0xFF200030	// Base address of the 7 segments for HEX4 and HEX5 displays

.equ PB0, 0x00000001
.equ PB1, 0x00000002
.equ PB2, 0x00000004
.equ PB, 0xFF200050		// base address of the pushbuttons data register
.equ PBEDGE, 0xFF20005C	// base address of the pushbuttons edgeCapture register


.equ TIMSTATUS, 0xFFFEC60C		// Address of the interrupt status register for the private timer
.equ TIMCONT, 0xFFFEC608		// Address of the control register for the private timer
.equ TIMCOUNT, 0xFFFEC604		// Address of register containing the  counter value of the private timer
.equ TIMLOAD, 0xFFFEC600		// Address of register containing the load value of the private timer
.equ time, 20000000				// (200MHz * 100ms)

// Array of bytes. Each index stores its corresponding 7-segment value: index 0 stores the value to display a zero to the 7 segment.
values: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71


_start:
	LDR R0, =time			// Down counting from 100ms to 0, the counter counts in increments of 100ms
	MOV R1, #0x6			// I(interrupt)=1; A(Timer restarts after 0)=1; E(stop if 0)=0
	BL ARM_TIM_config_ASM
	
	MOV R5, #0				// R5 is the count value for diciseconds
	MOV R6, #0				// R6 is the count value for units of seconds
	MOV R7, #0				// R7 is the count value for tens of seconds
	MOV R8, #0				// R8 is the count for units of minutes
	MOV R9, #0				// R9 is the count value for tens of minutes
	MOV R10, #0 			// R10 is the count value for hours
	
loop:	
	BL read_PB_edgecp_ASM
	CMP R0, #0x00000000			// Compare the state of the psuhbuttons with 0. If the result is not 0, this means one of the pushbuttons was pressed and released, so we need to clear it. 
	BLNE PB_clear_edgecp_ASM	// We clear if the edgecapture was different from 0. This allows for better response when we press and release a pushbutton.
	MOV R3, R0				// Copy the return value in R3
	
	LDR R2, =PB0			// If the pushButton 0 was pressed and released start the counter
	TST R3, R2
	MOVNE R1, #0x7			// I(interrupt)=1; A(Timer restarts after 0)=1; E(start if 1)=1
	LDRNE R4, =TIMCONT		// Load address of control register of the timer 
	STRNE R1, [R4]			// Store configuartion bits in control register
	
	LDR R2, =PB1			// If the pushButton 1 was pressed and released stop the counter
	TST R3, R2
	MOVNE R1, #0x6			// I(interrupt)=1; A(Timer restarts after 0)=1; E(stop if 0)0
	LDRNE R4, =TIMCONT		// Load address of control register of the timer 
	STRNE R1, [R4]			// Store configuartion bits in control register
	
	LDR R2, =PB2			// If the pushButton 3 was pressed and released reset the counter (and the displayed value on the displays)
	TST R3, R2
	LDRNE R0, =time			// Reset counter by calling the config subroutine
	MOVNE R1, #0x7			// I(interrupt)=1; A(Timer restarts after 0)=1; E(start if 1)=1
	BLNE ARM_TIM_config_ASM
	MOVNE R5, #0			// reset diciseconds
	MOVNE R6, #0			// reset seconds
	MOVNE R7, #0			
	MOVNE R8, #0			// reset minutes
	MOVNE R9, #0
	MOVNE R10, #0			// reset hours
	
	// Check the "F" value
	BL ARM_TIM_read_INT_ASM
	CMP R0, #0x00000001	
	BNE loop					// If the "F" value is not one, go back to beginning of the loop
	BLEQ ARM_TIM_clear_INT_ASM	// Else, clear the "F" value 
	ADDEQ R5, R5, #1			// And increase the diciseconds counter
	
	CMP R5, #10			// If We are at 10 diciseconds, set the diciseconds back to 0
	MOVEQ R5, #0
	ADDEQ R6, R6, #1	// Add 1 to the units of second counter
	
	CMP R6, #10			// If the units of seconds is 10, set it back to 0
	MOVEQ R6, #0
	ADDEQ R7, #1		// Add 1 to the tens of seconds counter
	
	CMP R7, #6			// if the tens of seconds is 6 (total of 60 seconds) reset it to 0
	MOVEQ R7, #0
	ADDEQ R8, R8, #1	// Add one to the units of minute counter
	
	CMP R8, #10			// If the units of minutes is 10, set it back to 0
	MOVEQ R8, #0
	ADDEQ R9, R9, #1	// Add 1 to the tens of minutes counter
	
	CMP R9, #6			// if the tens of minutes is 6 (total of 60 minutes) reset it to 0
	MOVEQ R9, #0
	ADDEQ R10, R10, #1	// Add one to the hour counter
	
	CMP R10, #10		// If we are at ten hours reset the hour counter 
	MOVEQ R10, #0		// (we only have one display for the hour so it can be 9 max)
		
	// Write diciseconds on HEX0
	LDR R0, =HEX0	
	MOV R1, R5
	BL HEX_write_ASM
	
	// Write seconds on HEX1 and HEX2
	LDR R0, =HEX1	
	MOV R1, R6
	BL HEX_write_ASM
	LDR R0, =HEX2	
	MOV R1, R7
	BL HEX_write_ASM
	
	// Write minutes on HEX3 and HEX4
	LDR R0, =HEX3	
	MOV R1, R8
	BL HEX_write_ASM
	LDR R0, =HEX4	
	MOV R1, R9
	BL HEX_write_ASM
	
	// Write hours on HEX5
	LDR R0, =HEX5	
	MOV R1, R10
	BL HEX_write_ASM
	
	B loop
	
// Configure the private timer. Takes two arguments
// The first argument is the initial count value (we put in the load register of the timer)
// The second argument is the configuration bits (set in the control register of the private timer)
ARM_TIM_config_ASM:
	PUSH {R4, LR}			// Respect the subroutine calling convention
	LDR R4, =TIMLOAD		// Load address of Load register of the private timer
	STR R0, [R4]			// Store the initial count value in the load register	
	LDR R4, =TIMCONT		// Load address of control register of the timer 
	STRB R1, [R4]			// Store configuartion bits in control register
	POP {R4, LR}
	BX LR
	
// Returns the “F” value (0x00000000 or 0x00000001) 
// from the private timer Interrupt status register
ARM_TIM_read_INT_ASM: 
	PUSH {R4, LR}			// Respect the subroutine calling convention
	LDR R4, =TIMSTATUS		// Load address of status register of the timer 
	LDR R0, [R4]			// STore the content of the status register in R0
	AND R0, R0, #0x00000001	// Isolate the last bit (ITO)
	POP {R4, LR}
	BX LR
	
// Clears the “F” value in the private timer Interrupt status register. 
// It is cleared to 0 by writing a 0x00000000 into the Interrupt status register.
ARM_TIM_clear_INT_ASM: 
	PUSH {R4, R5, LR}			// Respect the subroutine calling convention
	LDR R4, =TIMSTATUS		// Load address of status register of the timer 
	MOV R5, #0x00000001
	STR R5, [R4]
	POP {R4, R5, LR}
	BX LR
	
// The subroutine receives HEX display indices and an integer value in 0-15 to display.
// These are passed in registers R0 and R1, respectively. 
// Based on the second argument (R1), the subroutine will display the corresponding 
// hexadecimal digit (0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F) on the display(s).
HEX_write_ASM:
	PUSH {R4, R5, LR}	// Respect the subroutine calling convention
	MOV R4, R0
	
	LDR R5, =HEX0 		// Move the HEX0 display index in R5 
	TST R4, R5			// Use the one hot encoding to and the display index and the passed argument
	MOVNE R0, #0		// If the and operation outputs '1', the display must display the value stored in the second argument. Move the display's index in R0 (0,1,2...)
	LDRNE R2, =SEG1		// Select the register to write to (depending on the display we write to)
	BLNE writeHEX		// Call a subfunction to display the value of the second argument to that display (use the SEG1 variable to modify the display)
	
	// The same procedure for the HEX0 display is applied for the other displays.
	LDR R5, =HEX1
	TST R4, R5			
	MOVNE R0, #1
	LDRNE R2, =SEG1
	BLNE writeHEX
	
	LDR R5, =HEX2
	TST R4, R5			
	MOVNE R0, #2
	LDRNE R2, =SEG1
	BLNE writeHEX
	
	LDR R5, =HEX3
	TST R4, R5			
	MOVNE R0, #3
	LDRNE R2, =SEG1
	BLNE writeHEX
	
	LDR R5, =HEX4
	TST R4, R5			
	MOVNE R0, #0		// Move '0' in R0 because the segments of the HEX4 display are set using the first byte segment of the register stored in the SEG2 variable
	LDRNE R2, =SEG2
	BLNE writeHEX	
	
	LDR R5, =HEX5
	TST R4, R5			
	MOVNE R0, #1		// Move '1' in R0 because the segments of the HEX5 display are set using the second byte segment of the register stored in the SEG2 variable
	LDRNE R2, =SEG2
	BLNE writeHEX
	
	POP {R4, R5, LR}	// Respect the subroutine calling convention
	BX LR

// Method to write a particular value / number to a particular display.
// The first argument stores the number of the display toi use (if R0 is 2, we write to the HEX2 display)
// The second argument stores the value to display.
// The third argument selects the register to write to (either the one stored at the address in SEG1 or SEG2)
// The following hex values can be displayed: 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F
writeHEX:
	PUSH {R4, R5, R6, LR}	// Respect the subroutine calling convention
	LDR R5, =values			// Store the address of the array of bytes conatining all the values to display. Each index has its corresponding value.
	LDRB R4, [R5, R1]		// Select the byte value using the value stored in R1 and the index of the array. We store this byte value in R5.
	STRB R4, [R2, R0]		// Stores the content of R5 in the corresponding bits of the register at the address stored in SEG1 (see Manual) dpeending on the display to use
	POP {R4, R5, R6, LR}	// Respect the subroutine calling convention
	BX LR

// Returns the indices of the pushbuttons that have been pressed and then released 
// (the edge bits from the pushbuttons’ Edgecapture register).	
read_PB_edgecp_ASM:	
	PUSH {R4, LR}
	LDR R4, =PBEDGE
	LDR R0, [R4]	// Store the content of the register at address in PBEDGE in R0
	AND R0, R0, #0x0000000F	// Keep the last four bits only
	POP {R4, LR}
	BX LR
	
// Clears the pushbutton Edgecapture register. 
// Read the edgecapture register and write what we just read 
// back to the edgecapture register to clear it
PB_clear_edgecp_ASM:
	PUSH {R4, R5, LR}
	LDR R4, =PBEDGE
	LDR R5, [R4]			// Load the content of the register at address in PBEDGE in R0
	STR R5, [R4]			// Store it back in the edgeCapture register to clear it
	POP {R4, R5, LR}
	BX LR
	
	
	
	
