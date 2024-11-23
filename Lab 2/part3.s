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
.equ PBINT, 0xFF200058	// base address of the pushbuttons interruptmask register

.equ TIMSTATUS, 0xFFFEC60C		// Address of the interrupt status register for the private timer
.equ TIMCONT, 0xFFFEC608		// Address of the control register for the private timer
.equ TIMCOUNT, 0xFFFEC604		// Address of register containing the  counter value of the private timer
.equ TIMLOAD, 0xFFFEC600		// Address of register containing the load value of the private timer
.equ time, 20000000				// (200MHz * 100ms)-1

PB_int_flag:
	.word 0x0

tim_int_flag:
	.word 0x0

.section .vectors, "ax"
B _start            // reset vector
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0             // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

// Array of bytes. Each index stores its corresponding 7-segment value: index 0 stores the value to display a zero to the 7 segment.
values: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

_start:
	/* Set up stack pointers for IRQ and SVC processor modes */
    MOV R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR CPSR_c, R1           // change to IRQ mode
    LDR SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR CPSR, R1             // change to supervisor mode
    LDR SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL  CONFIG_GIC             // configure the ARM GIC
   
	MOV R0, #0x0000000F		// * Used to enable the interrupt for all pushbuttons
	BL enable_PB_INT_ASM	// * Enable interrupts using the subroutine wrote in part 1
	
	LDR R0, =time			// * Down counting from 100ms to 0, the counter counts in increments of 100ms
	MOV R1, #0x6			// * I(interrupt)=1; A(Timer restarts after 0)=1; E(stop if 0)=0
	BL ARM_TIM_config_ASM    	// * Set up the interrupt for the ARM A9 private timer
	
	// enable IRQ interrupts in the processor
    MOV R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR CPSR_c, R0
	
	MOV R5, #0				// R5 is the count value for diciseconds
	MOV R6, #0				// R6 is the count value for units of seconds
	MOV R7, #0				// R7 is the count value for tens of seconds
	MOV R8, #0				// R8 is the count for units of minutes
	MOV R9, #0				// R9 is the count value for tens of minutes
	MOV R10, #0 			// R10 is the count value for hours

IDLE:	
	LDR R4, =PB_int_flag	// * Load the memory address of PB_int_flag in R2
	LDR R3, [R4]			// * read PB_int_flag and place its ocntent in R3
	
	LDR R2, =PB0			// If the pushButton 0 was pressed and released start the counter
	TST R3, R2
	MOVNE R1, #0x7			// I(interrupt)=1; A(Timer restarts after 0)=1; E(start if 1)=1
	LDRNE R4, =TIMCONT		// Load address of control register of the timer 
	STRNEB R1, [R4]			// Store configuartion bits in control register
	
	LDR R2, =PB1			// If the pushButton 1 was pressed and released stop the counter
	TST R3, R2
	MOVNE R1, #0x6			// I(interrupt)=1; A(Timer restarts after 0)=1; E(stop if 0)=0
	LDRNE R4, =TIMCONT		// Load address of control register of the timer 
	STRNEB R1, [R4]			// Store configuartion bits in control register
	
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
	MOVNE R5, #0x0			// Reset the memory address of PB_int_flag after reading it
	STRNE R5, [R4]
	
	// * Check for timer interrupts
	LDR R1, =tim_int_flag
	LDR R0, [R1]
	CMP R0, #0x00000001	
	BNE IDLE					// * If no interrupt detected go back to beginning of the loop
	
	MOV R0, #0x00000000			// * Reset the memory address of tim_int_flag after reading it
	STR R0, [R1]
	
	ADD R5, R5, #1	// Else increase the diciseconds counter
	
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
	
	B IDLE
	
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

/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ----------------------------------------*/
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR
Timer_check:
	CMP R5, #29		// * Check if the interrupt id correpsonds to the ARM A9 private timer
	BNE Pushbutton_check
	BL ARM_TIM_ISR
	B EXIT_IRQ
	
Pushbutton_check:
    CMP R5, #73		// Check if the interrupt id corresponds to the PushButton
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
    BL KEY_ISR
	
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
	SUBS PC, LR, #4
/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ

CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
	MOV R0, #29				// Timer port (Interrupt ID = 29)
	MOV R1, #1				// this field is a bit-mask; bit 0 targets cpu0
	BL CONFIG_INTERRUPT

/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC

* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
	
// Pushbutton interrupt service routine
KEY_ISR:
    LDR R0, =PBEDGE    		// read edge capture register
    LDR R1, [R0]
	AND R1, R1, #0x00000007	// Keep the last three bits only

	LDR R2, =PB_int_flag
	STR R1, [R2]			// write content of pushButton edgecapture to PB_int_flag
	
	MOV R2, #0xF
    STR R2, [R0]     // clear the interrupt
END_KEY_ISR:
    BX LR

// ARM A9 private timer interrupt service routine
ARM_TIM_ISR:
	LDR R0, =TIMSTATUS		// Read interrupt status register
	LDR R1, [R0]
	
	AND R1, R1, #0x00000001	// Isolate the last bit F value
	
	LDR R2, =tim_int_flag
	STR R1, [R2]
	
	STR R1, [R0]			// clear the interrupt
	
END_ARM_TIM_ISR:
	BX LR