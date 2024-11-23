.global _start
_start:
	MOV R0, #2 			//Store the x argument in R0
	MOV R1, #10			//Store the n argument in R1
	BL exp
	MOV R4, R0			//Store result in R4 (a)
	
	MOV R0, #-5 		// Store the "x" argument in R0
	MOV R1, #5			// Store the "n" argument in R1
	BL exp
	MOV R5, R0			// Store result in R5 (b)
	
stop:
	B stop

exp:
	PUSH {R4-LR}		// Push registers to preserve Callee Save Convention
		
	CMP R1, #0			// R1-0 => updates CPSR
	BEQ baseCase		// if n==0, branch to baseCase
	
	CMP R1, #1			// R1-1 => updates CPSR
	BEQ return			// if R1==1 => return x (already in R0 so branch to return)
	
	MOV R5, R0			// store current argument "x" in R5
	MOV R6, R1			// store current argument "n" in R6
	
	MUL R0, R0, R0		// New R0 is x*x (next argument)
	LSR R1, R1, #1		// New R1 is n >> 1 (next argument)
	BL exp				// R0 now stores exp(x*x, n >> 1)
	
	AND R4, R6, #1		// R4 <- n & 1
	CMP R4, #1			// R4-1 => updates CPSR. If R1 is odd, R4-1=0, else it's -1
	BEQ odd
	B return
	
baseCase:
	MOV R0, #1			// return 1
	B return

odd:
	MUL R0, R5, R0		// return x* exp(x*x, n >> 1)
	B return
	
return:
	POP {R4-LR}			// Pop
	BX LR	
	
