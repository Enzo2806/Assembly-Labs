.global _start

//initilization of the array of numbers:
numbers: .word 68, -22, -31, 75, -10, -61, 39, 92, 94, -55	

_start:
	LDR R0, =numbers		// put address of array in R0 =ptr
	MOV R1, #0				// Place second argument in R1 =start
	MOV R2, #9				// Place third argument in R2 =end
	BL quicksort
	MOV R4, R0				// Store address of sorted array in R4
	
stop:
	B stop
	
quicksort:
	PUSH {R4-LR}	// Push registers to preserve Callee Save Convention
	CMP R1, R2		// start-end => updates CPSR
	BGE return		// if start >= end => exit
	MOV R4, R1		// pivot = start
	MOV R5, R1		// i = start
	MOV R6, R2		// j = end

whileLoop1:
	CMP R5, R6		// i-j => updates CPSR
	BGE endLoop1	// exit while loop if i >= j
	
	//move i right until we find a number greater than the pivot
	whileLoop2:
	LDR R7, [R0, R5, LSL#2]	// R7 <= arr[i]
	LDR R8, [R0, R4, LSL#2]	// R8 <= arr[pivot]
	CMP R7, R8		// arr[i]-arr[pivot] => updates CPSR
	BGT whileLoop3	// exit whileloop if arr[i] > arr[pivot]
	CMP R5, R2		//i-end => updates CPSR
	BGE whileLoop3	// exit while loop if i >= end
	ADD R5, R5, #1	// i++
	B whileLoop2
	
	// move j left until we find a number smaller than the pivot
	whileLoop3:
	LDR R7, [R0, R6, LSL#2]	// R7 <= arr[j]
	LDR R8, [R0, R4, LSL#2]	// R8 <= arr[pivot]
	CMP R7, R8		// arr[j]-arr[pivot] => updates CPSR
	BLE endLoop3	// exit whileloop if arr[j] <= arr[pivot]
	SUB R6, R6, #1	// j--
	B whileLoop3
	
	// swap the elements at these positions unless they are already relatively sorted
	endLoop3:
	CMP R5, R6 		// i-j => updates CPSR
	BGE endLoop1	// exit while loop if i >= j otherwise swap(i,j)
	
	PUSH {R1, R2}	// Push arguments
	MOV R1, R5		// R1 <= i ; second argument to swap (a)
	MOV R2, R6		// R2 <= j ; third argument to swap (b)
	BL swap
	POP {R1, R2}	// Pop arguments 
	B whileLoop1
	
endLoop1:
	// swap pivot and element j
	PUSH {R1, R2}	// Push arguments
	MOV R1, R4		// R1 <= pivot ; second argument to swap (a)
	MOV R2, R6		// R2 <= j ; third argument to swap (b)
	BL swap
	POP {R1, R2}	// Pop arguments 
	
	// recurse on the subarrays before and after element j
	MOV R4, R2	//Store end value in R4
	SUB R2, R6, #1	// R2 <= j-1
	BL quicksort
	
	MOV R2, R4 //Restore end value in R2
	ADD R1, R6, #1	// R1 <= j+1
	BL quicksort
	B return
	
swap:
	PUSH {R4-LR}	 // Push registers to preserve Callee Save Convention
	LDR R4, [R0, R1, LSL#2]	// R4 <= arr[a]	
	LDR R5, [R0, R2, LSL#2]	// R5 <= arr[b]
	STR R5, [R0, R1, LSL#2] // arr[a]=arr[b]
	STR R4, [R0, R2, LSL#2] // arr[b]=arr[a]
	B return

return:
	POP {R4-LR}	// Pop
	BX LR

	

	
