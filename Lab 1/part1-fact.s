.global _start
_start:
	MOV R0, #5 			//Store the "n" argument in R0
	BL fact
	MOV R4, R0			// Store result in R4 (a)
	
	MOV R0, #10 		//Store the "n" argument in R0
	BL fact
	MOV R5, R0			// Store result in R5 (b)

stop:
	B stop

fact:
	PUSH {R4-LR}		// Push registers to preserve Callee Save Convention
	CMP R0, #2			// R0-2 == n-2
	BLT baseCase		// If n-2<0 return 1
	MOV R4, R0 			// else make a copy of r0
	SUB R0, R0, #1		// Next argument must be in R0 =>(n-1)
	BL fact				// recursive call: fact(n-1)
	MUL R0, R4, R0		// R0 = R4 * R0 (R4 is n (copy of orginal argument)), 
						// R0 has the result of the other recursive call
	POP {R4-LR}			// Pop
	BX LR
	
baseCase:
	MOV R0, #1			// return 1
	POP {R4-LR}			// Pop
	BX LR
	
	
