.global _start
_start:
	MOV R0, #2			//store your "x" argument in R0
	MOV R1, #10	 		//store your "n" argument in R1
	BL exp 				//call exp function			
	MOV R4, R0			//put the answer stored in R0 in a
	
	MOV R0, #-5 			//store your "x" argument in R0
	MOV R1, #5			//store your "n" argument in R1
	BL exp 				//call exp function
	MOV R5, R0			//put the answer stored in R0 in b

stop:
	B stop
	
exp:
	PUSH {R4-LR}			//Push to preserve the Callee Save convention
	MOV R4, #1			    //R4 will accumulate the result
	
expLoop:
	SUBS R1, R1, #1			//i--
	BLT exit				// i-- < 0 => exit the loop
	MUL R4, R4, R0			//result=result*x
	B expLoop
	
exit:
	MOV R0, R4			//Move result in R0
	POP {R4-LR}			//Pop all the registers that were pushed
	BX LR				//return

