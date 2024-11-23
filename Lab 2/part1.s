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
.equ PB3, 0x00000008
.equ PB, 0xFF200050		// base address of the pushbuttons data register
.equ PBEDGE, 0xFF20005C	// base address of the pushbuttons edgeCapture register
.equ PBINT, 0xFF200058	// base address of the pushbuttons interruptmask register
.equ SW_ADDR, 0xFF200040
.equ LED_ADDR, 0xFF200000

// Array of bytes. Each index stores its corresponding 7-segment value: index 0 stores the value to display a zero to the 7 segment.
values: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

_start:
	BL PB_clear_edgecp_ASM 	// Clear the edge Capture register for the push button
	MOV R0, #0x00000030
	BL HEX_flood_ASM
	B loop
	
loop:
	BL read_slider_switches_ASM			// Read slider switches
	BL write_LEDs_ASM					// Turn LEDs accoriding to switches
	AND R1, R0, #0x0000000F				// Makes a copy of the return value by just taking the last 4 bits (SW3-SW0)
	
	MOV R2, #0x00000200			// Check if SW9 is on
	TST R0, R2
	MOVNE R0, #0x000000FF		// If it's on, clear all displays
	BLNE HEX_clear_ASM
	
	// If the SW9 switch is off, flood the HEX4 and HEX5 displays
	MOVEQ R0, #0x00000030
	BLEQ HEX_flood_ASM
	
	BL read_PB_edgecp_ASM		// Read edge capture register
	CMP R0, #0					// If a push buttons was pressed and released, we clear the edgecapture. (no need to clear if no change)
	BLNE PB_clear_edgecp_ASM		// clear it so that the values displayed dont change if we modify the switches
	MOV R3, R0
	
	LDR R2, =PB0	// If the pushButton 0 was pressed and released
	TST R3, R2
	LDRNE R0, =HEX0	// Load the index of display 0 and display the value determined by the switches on it (already stored in R1)
	BLNE HEX_write_ASM
	
	LDR R2, =PB1
	TST R3, R2
	LDRNE R0, =HEX1
	BLNE HEX_write_ASM
	
	LDR R2, =PB2
	TST R3, R2
	LDRNE R0, =HEX2
	BLNE HEX_write_ASM
	
	LDR R2, =PB3
	TST R3, R2
	LDRNE R0, =HEX3
	BLNE HEX_write_ASM
	B loop

// Slider Switches Driver
// returns the state of slider switches in R0
// post- R1: slide switch state
read_slider_switches_ASM:
    LDR R1, =SW_ADDR     // load the address of slider switch state
    LDR R0, [R1]         // read slider switch state 
    BX  LR

// LEDs Driver
// writes the state of LEDs (On/Off state) in A1 to the LEDs’ memory location
// pre-- A1: data to write to LED state
write_LEDs_ASM:
    LDR R1, =LED_ADDR    // load the address of the LEDs’ state
    STR R0, [R1]         // update LED state with the contents of R0
    BX  LR
	
// Returns the indices of the pressed pushbuttons 
//(the keys from the pushbuttons Data register)
read_PB_data_ASM:
	PUSH {R4, LR}
	LDR R4, =PB
	LDR R0, [R4]	// Load the content of the register at address in PB in R0
	POP {R4, LR}
	BX LR

// Receives a pushbutton index as an argument. 
// Returns 0x00000001 if the corresponding pushbutton is pressed
PB_data_is_pressed_ASM:
	PUSH {R4, R5, LR}
	LDR R4, =PB
	LDR R5, [R4]			// Load the content of the register at address in PB in R0
	TST R0, R5				// Use one hot encoding and 'and' the content of the data register and the passed argument
	MOVEQ R0, #0x00000000	// If the and operation is '0', the button is not pressed so output 0
	MOVNE R0, #0x00000001	// else output '1'
	POP {R4, R5, LR}
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
	
// Receives a pushbutton index as an argument. 
// Returns 0x00000001 if the corresponding pushbutton has been pressed and released.
PB_edgecp_is_pressed_ASM:
	PUSH {R4, R5, LR}
	LDR R4, =PBEDGE
	LDR R5, [R4]			// Load the content of the register at address in PB in R0
	TST R0, R5				// Use one hot encoding and 'and' the content of the data register and the passed argument
	MOVEQ R0, #0x00000000	// If the and operation is '0', the button is not pressed so output 0
	MOVNE R0, #0x00000001	// else output '1'
	POP {R4, R5, LR}
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
	
// Receives the pushbutton indices as an argument. 
// It enables the interrupt function for the corresponding pushbuttons by setting the interrupt mask bits to '1'
enable_PB_INT_ASM:
	PUSH {R4, R5, LR}
	LDR R4, =PBINT		
	LDR R5, [R4]		// Load the content of the register at address in PBINT in R5
	ORR R5, R5, R0		// Or the content of the interruptmask register with the argument to keep track of the bits already set to '1'
	STR R5, [R4]		// Store the result back in the register
	POP {R4, R5, LR}
	BX LR
	
// Receives pushbutton indices as an argument.
// It disables the interrupt function for the corresponding pushbuttons by setting the interrupt mask bits to '0'.
disable_PB_INT_ASM:
	PUSH {R4, R5, LR}
	LDR R4, =PBINT		
	LDR R5, [R4]		// Load the content of the register at address in PBINT in R5
	MVN R0, R0			// Not the content in R0
	AND R5, R5, R0		// And the content of the interruptmask register with the inverse of the argument to keep the state of the other bits in the register.
	STR R5, [R4]		// Store the result back in the register
	POP {R4, R5, LR}
	BX LR
	
// The subroutine will turn off all the segments of the HEX 
// displays passed in the argument. 
// It receives the HEX display indices through register R0 as an argument.
HEX_clear_ASM:
	PUSH {R4, R5, LR}	// Respect the subroutine calling convention
	MOV R4, R0			// Move the argument in R4 to call other function using R0
	
	LDR R5, =HEX0		// Move the HEX0 display index in R5 
	TST R4, R5			// Use the one hot encoding to AND the display index and the passed argument
	MOVNE R0, #0		// If the and operation outputs '1', the display must be cleared. Move its index in R0
	LDRNE R1, =SEG1		// Select the register to write to (depending on the display we write to)
	BLNE clearHEX		// Call a subfunction to clear (use the SEG1 variable to modify the display)
	
	// The same procedure for the HEX0 display is applied for the all the other displays.
	LDR R5, =HEX1
	TST R4, R5
	MOVNE R0, #1
	LDRNE R1, =SEG1
	BLNE clearHEX
	
	LDR R5, =HEX2		 
	TST R4, R5			
	MOVNE R0, #2
	LDRNE R1, =SEG1
	BLNE clearHEX
	
	LDR R5, =HEX3		
	TST R4, R5			
	MOVNE R0, #3
	LDRNE R1, =SEG1
	BLNE clearHEX
	
	LDR R5, =HEX4 		
	TST R4, R5			
	MOVNE R0, #0		// Move '0' in R0 because the segments of the HEX4 display are set using the first byte segment of the register stored in the SEG2 variable
	LDRNE R1, =SEG2
	BLNE clearHEX	
	
	LDR R5, =HEX5	
	TST R4, R5			
	MOVNE R0, #1		// Move '1' in R0 because the segments of the HEX5 display are set using the second byte segment of the register stored in the SEG2 variable
	LDRNE R1, =SEG2
	BLNE clearHEX
	
	POP {R4, R5, LR}	// Respect the subroutine calling convention

	BX LR				// Restores the PC value 
	
// Function clears HEX display associated with the number passed in R0.
// If R0 contains #2, we clear the HEX2 display
// The second argument contains the address that holds the state of the corresponding HEX display (SEG1 or SEG2)
clearHEX:
	PUSH {R4, LR}		// Respect the subroutine calling convention
	MOV R4, #0b0000000	// Move the new byte value to clear the selected display in R5
	STRB R4, [R1, R0]	// Stores the content of R5 in the corresponding bits of the register at the address stored in R1 (SEG1 or SEG2)(see Manual)
	POP {R4, LR}		// Respect the subroutine calling convention
	BX LR

// The subroutine will turn on all the segments of the HEX displays passed in the argument.
// It receives the HEX display indices through register R0 as an argument.
HEX_flood_ASM: 
	PUSH {R0, R1, R4, R5, LR}	// Respect the subroutine calling convention
	MOV R4, R0
	
	LDR R5, =HEX0 		// Move the HEX0 display index in R5 
	TST R4, R5			// Use the one hot encoding to and the display index and the passed argument
	MOVNE R0, #0		// If the and operation outputs '1', the display must have all its segments turn on. Move the display's index in R0 (0,1,2...)
	LDRNE R1, =SEG1		// Select the register to write to (depending on the display we write to)
	BLNE floodHEX		// Call a subfunction to turn all the segments on (use the SEG1 variable to modify the display)
	
	// The same procedure for the HEX0 display is applied for the other displays.
	LDR R5, =HEX1
	TST R4, R5			
	MOVNE R0, #1
	LDRNE R1, =SEG1
	BLNE floodHEX
	
	LDR R5, =HEX2
	TST R4, R5			
	MOVNE R0, #2
	LDRNE R1, =SEG1
	BLNE floodHEX
	
	LDR R5, =HEX3
	TST R4, R5			
	MOVNE R0, #3
	LDRNE R1, =SEG1
	BLNE floodHEX
	
	LDR R5, =HEX4
	TST R4, R5			
	MOVNE R0, #0		// Move '0' in R0 because the segments of the HEX4 display are set using the first byte segment of the register stored in the SEG2 variable
	LDRNE R1, =SEG2
	BLNE floodHEX	
	
	LDR R5, =HEX5
	TST R4, R5			
	MOVNE R0, #1		// Move '1' in R0 because the segments of the HEX5 display are set using the second byte segment of the register stored in the SEG2 variable
	LDRNE R1, =SEG2
	BLNE floodHEX
	
	POP {R0, R1, R4, R5, LR}	// Respect the subroutine calling convention
	BX LR
	
// Function floods HEX display passed in R0
// If R0 contains #2, we flood the HEX2 display
// R1 stores the corresponding base address to change the segments of the selected display (SEG1 or SEG0)
floodHEX:
	PUSH {R4, LR}		// Respect the subroutine calling convention
	MOV R4, #0b1111111	// Move the new byte value to turn on all segments of the selected display in R5
	STRB R4, [R1, R0]	// Stores the content of R5 in the corresponding bits of the register at the address stored in R1 (SEG1 or SEG2) (see Manual)
	POP {R4, LR}		// Respect the subroutine calling convention
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
	