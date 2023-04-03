# CS 21 LAB4 -- S2 AY 2021-2022
# Allaine Ricci U. Tan -- 04/12/2022
# 202010443_4.asm -- 4x4 sudoku solver in MIPS

.macro			get_start(%result, %index)			
			li	$t9, 2					#$t9 = 2
			div	%index, $t9				#index // 2
			mflo	%result					#result = index // 2
			mult	%result, $t9				#result * 2
			mflo	%result					#result = result * 2
.end_macro

.macro			get_address(%result, %rowIndex, %colIndex, %size, %baseAddress, %dataSize)
									#address = baseAddress + (rowIndex*colSize + colIndex)*dataSize
			mult	%rowIndex, %size	 		#rowIndex*colSize
			mflo	%result					#result = rowIndex*colSize
			add	%result, %result, %colIndex		#result = (rowIndex*colSize + colIndex)
			mult	%result, %dataSize			#(rowIndex*colSize + colIndex)*dataSize
			mflo	%result					#result = (rowIndex*colSize + colIndex)*dataSize
			add	%result, %result, %baseAddress		#result = address = baseAddress + (rowIndex*colSize + colIndex)*dataSize
.end_macro
		
.macro 			build_grid()
			li	$s0, 0					#$s0 = rowIndex
			lw	$s1, size				#$s1 = size
build_forloop:		beq	$s0, $s1, build_endloop			#for rowIndex in range(size)
			la	$a0, inp				#$a0 = address of input
			la	$a1, grid				#$a1 = baseAddress
			input($s0)					#get user input and parse in row
			addi	$s0, $s0, 1				#$s0 = rowIndex ++
			j	build_forloop				#loop back
build_endloop:
.end_macro

.macro 			input(%rowIndex)
			li	$v0, 8					
			syscall
			move	$t0, $v0				#$t0 = user input
		
			li	$t1, 0					#$t1 = colIndex
input_forloop:		beq	$t1, $s1, input_endloop   		#for colIndex in range(size)
		
			get_address($t2, %rowIndex, $t1, $a2, $a1, $a3)	#$t2 = address (grid[row][col])
									#getting the appropriate byte from user input
			add	$t4, $a0, $t1				#$t6 = input baseAddress + offset
			lb	$t3, 0($t4)				#$t5 = byte
			sw	$t3, 0($t2)				#store byte at address
		
			addi	$t1, $t1, 1 				#$t1 = colIndex++
			j 	input_forloop				#loop back
input_endloop:	
.end_macro

.macro 			print_grid()			
			la 	$t0, grid				#$t0 = baseAddress
			li	$t1, 1					#$t1 = counter (for space)
			li	$t2, 0					#$t2 = counter (for all elements)
			li	$t3, 0					#$t3 = offset, to be incremented by 4
			mult 	$s1, $s1
			mflo	$t9					#$t9 = size^2
print_forloop:		beq	$t2, $t9, print_endloop			#for counter in range(size^2)
			add	$t4, $t0, $t3				#$t4 = incremented address
			lw	$t5, 0($t4)				#load value from the offset address
		
			move	$a0, $t5				
			li	$v0, 11		
			syscall						#print ascii character corresponding to $t5
									#checking if new line needs to be printed
			bne 	$t1, $s1, skip				#if elements printed not equal to size, don't print space
			li 	$v0, 4  	
   			la 	$a0, space      			
    			syscall						#else, pring a space
    			li	$t1, 0					#reset t1 to 0
    		
skip:			addi	$t1, $t1, 1				#$t1 = counter++ (for space)
			addi	$t2, $t2, 1				#$t2 = counter++ (for all elements)
			addi	$t3, $t3, 4				#$t3 = offset + 4
			j	print_forloop				#loop back

print_endloop:		li	$v0, 10					#end the program after printing
			syscall

.end_macro

.text		
main:			la	$a0, inp				#a0 = inputAddress
			la	$a1, grid				#a1 = baseAddress
			lw	$a2, size				#a2 = size
			lw	$a3, data_size				#a3 = dataSize
			
			build_grid()					#take in user input and make a grid
			
			la	$a0, grid				#a0 = baseAddress (argument to solve)
			jal	solve					#call the solve function

			print_grid()					#print the solved grid
	
find_next:		########FIND NEXT##########	
			# Finds the next empty space in the grid and returns the rowIndex, colIndex and address of the empty space.
			# Arguments: $a0 = base address, $a1 = size, $a2 = data_size	
			# Return values: $v0 = rowIndex, $v1 = colIndex
			########FIND NEXT##########
			
			#####preamble######
			subu 	$sp, $sp, 36				#allocate 36 byte stack frame
			sw 	$ra, ($sp)				#save return address
			sw	$t0, 4($sp)				#$t0 = rowIndex
			sw	$t1, 8($sp)				#$t1 = colIndex
			sw	$t2, 12($sp)				#$t2 = resulting address (grid[row][col])
			sw	$t3, 20($sp)				#$t3 = number stored at resulting address
			sw	$s5, 24($sp)				#$s5 = argument: baseAddress
			sw	$s6, 28($sp)				#$s6 = argument: size
			sw	$s7, 32($sp)				#$s7 = argument: dataSize
			#####preamble######		
									#moving arguments
			move	$s5, $a0				#$s5 = baseAddress
			move	$s6, $a1				#$s6 = size
			move	$s7, $a2				#$s7 = dataSize
			
			li	$t0, 0					#$t0 = rowIndex = 0
next_row_forloop:	beq	$t0, $s6, next_row_endloop		#for rowIndex in range(size)
		
			li	$t1, 0					#$t1 = colIndex = 0
next_col_forloop:	beq	$t1, $s6, next_col_endloop 		#for colIndex in range(size)

			get_address($t2, $t0, $t1, $s6, $s5, $s7)	#$t2 = address (grid[row][col])
			
			lw	$t3, 0($t2)				#if content at the address == 0 (30 in ascii), then return address
			beq	$t3, 0x30, is_empty			
			addi	$t1, $t1, 1				#$t1 = colIndex ++
			j	next_col_forloop			#loop back
next_col_endloop:
			addi	$t0, $t0, 1				#$t0 = rowIndex ++
			j	next_row_forloop			#loop back
	
									#if there is no more empty areas, return row = -1 and col = -1
next_row_endloop:	li	$v0, -1					#return $v0 = row = -1
			li	$v1, -1					#return $v1 = col = -1		
			j	next
				
									#if an empty spot is found, return rowIndex and colIndex
is_empty:		move	$v0, $t0				#return $v0 = rowIndex
			move	$v1, $t1				#return $v1 = colIndex
			
next:			########end########
			lw 	$ra, ($sp)	
			lw	$t0, 4($sp)	
			lw	$t1, 8($sp)	
			lw	$t2, 12($sp)	
			lw	$t3, 20($sp)	
			lw	$s5, 24($sp)	
			lw	$s6, 28($sp)	
			lw	$s7, 32($sp)	
			addu 	$sp, $sp, 36	
			########end########
			jr 	$ra
			
is_valid:		########IS VALID##########
			# Checks if the current guess is in the same row, col or square
			# Arguments: $a0 = base_address, $a1 = rowIndex, $a2 = colIndex, $a3 = guess
			# Return Values: $v0 = 1 if guess is valid, 0 if not valid
			########IS VALID##########

			#####preamble######
			subu 	$sp, $sp, 56				#allocate 56 byte stack frame
			sw 	$ra, ($sp)				#save return address
			sw	$t0, 4($sp)				#$t0 = colIndex/rowIndex // row in checksquare 
			sw	$t1, 8($sp)				#$t1 = rowStart
			sw	$t2, 12($sp)				#$t2 = colStart
			sw	$t3, 16($sp)				#$t3 = resulting address (grid[row][col])
			sw	$t4, 20($sp)				#$t4 = size
			sw	$t5, 24($sp)				#$t5 = dataSize
			sw	$t6, 28($sp)				#$t6 = number stored at resulting address
			sw	$s1, 32($sp) 				#$s1 = rowStart + 2
			sw	$s2, 36($sp)				#$s2 = colStart + 2
			sw	$s4, 40($sp)				#$s4 = argument: baseAddress
			sw	$s5, 44($sp)				#$s5 = argument: rowIndex
			sw	$s6, 48($sp)				#$s6 = argument: colIndex
			sw	$s7, 52($sp)				#$s7 = argument: guess
			#####preamble######
									#moving arguments
			move	$s4, $a0				#$s4 = baseAddress
			move	$s5, $a1				#$s5 = rowIndex
			move	$s6, $a2				#$s6 = colIndex
			move	$s7, $a3				#$s7 = guess
			
			lw 	$t4, size				#$t4 = size
			lw 	$t5, data_size				#$t5 = dataSize
			
			##checking if guess is already in the row##
			li	$t0, 0					#$t0 = colIndex = 0
checkrow_forloop:	beq	$t0, $t4, checkrow_endloop 		#for col in range(size)
			get_address($t3, $s5, $t0, $t4, $s4, $t5)	#$t3 = address (grid[row][col])
			lw	$t6, 0($t3)				#$t6 = number stored at resulting address
			beq	$t6, $s7, invalid			#if number == guess, invalid
			addi	$t0, $t0, 1				#$t0 = colIndex ++
			j	checkrow_forloop			#loop back
checkrow_endloop:
			##checking if quess is already in the column##
			li	$t0, 0					#$t0 = rowIndex = 0
checkcol_forloop:	beq	$t0, $t4, checkcol_endloop 		#for col in range(size)
			get_address($t3, $t0, $s6, $t4, $s4, $t5)	#$t3 = address (grid[row][col])
			lw	$t6, 0($t3)				#$t6 = number stored at resulting address
			beq	$t6, $s7, invalid			#if number == guess, invalid
			addi	$t0, $t0, 1				#$t0 = rowIndex ++
			j	checkcol_forloop			#loop back
checkcol_endloop:
			##checking if guess is already in the square grid##
			
			get_start($t1, $s5)				#$t1 = rowStart = starting rowIndex of grid
			addi	$s1, $t1, 2				#$s1 = boundary for row = row+2
squarerow_forloop:	beq	$t1, $s1, squarerow_endloop		#for row in range(rowStart, rowStart+2)
			
			get_start($t2, $s6)				#$t2 = colStart = starting colIndex of grid
			addi	$s2, $t2, 2				#$s2 = boundary for col = col+2
squarecol_forloop:	beq	$t2, $s2, squarecol_endloop		#for col in range(colStart, colStart+2)
			get_address($t3, $t1, $t2, $t4, $s4, $t5)	#$t3 = address (grid[row][col])
			lw	$t6, 0($t3)				#$t6 = number stored at resulting address
			beq	$t6, $s7, invalid			#if number == guess, invalid
			addi	$t2, $t2, 1				#$t2 = colStart ++
			j	squarecol_forloop 			#loop back

squarecol_endloop:	addi	$t1, $t1, 1				#$t1 = rowStart ++
			j	squarerow_forloop 			#loop back
									#if all values in row, col and grid are checked and none are invalid
squarerow_endloop:	li	$v0, 1					#return $v0 = 1
			j	end_check	
									#if there is a same value in row, col and grid
invalid:		li	$v0, 0					#return $v0 = 0
			
end_check:		########end########
			lw 	$ra, ($sp)	
			lw	$t0, 4($sp)	
			lw	$t1, 8($sp)	
			lw	$t2, 12($sp)	
			lw	$t3, 16($sp)	
			lw	$t4, 20($sp)	
			lw	$t5, 24($sp)	
			lw	$t6, 28($sp)	
			lw	$s1, 32($sp) 	
			lw	$s2, 36($sp)	
			lw	$s4, 40($sp)	
			lw	$s5, 44($sp)	
			lw	$s6, 48($sp)	
			lw	$s7, 52($sp)	
			addu 	$sp, $sp, 56	
			########end########
			jr	$ra

solve:			########SOLVE SUDOKU##########
			#Solves the sudoku puzzle
			#Arguments: $a0 = baseAddress
			########SOLVE SUDOKU##########
			
			#####preamble######
			subu 	$sp, $sp, 48				#allocate 12 byte stack frame
			sw 	$ra, ($sp)				#save return address
			sw	$t0, 4($sp)				#$t0 = result of is_valid (1 if valid, 0 if not valid)
			sw	$t1, 8($sp)				#$t1 = result of solve (1 if true, 0 if false)
			sw	$t2, 12($sp)				#$t2 = resulting address (grid[row][col])
			sw	$t3, 16($sp)				#$t3 = 0x30 (for resetting when backtracking)
			sw 	$t4, 20($sp)				#$t4 = guess
			sw	$t5, 24($sp)				#$t5 = rowIndex
			sw	$t6, 28($sp)				#$t6 = colIndex
			sw	$t7, 32($sp)				#$t7 = max guess
			sw	$s0, 36($sp) 				#$s0 = size
			sw	$s1, 40($sp)				#$s1 = dataSize
			sw	$s2, 44($sp)				#$s2 = argument: baseAddress
			#####preamble######
									#moving arguments
			li	$t3, 0x30				#$t3 = 0x30 (for resetting when backtracking)
			lw	$s0, size				#$s0 = size
			lw	$s1, data_size				#$s1 = dataSize
			move	$s2, $a0				#$s2 = baseAddress

									#check if no more empty spaces
			la	$a0, grid				#$a0 = baseAddress
			lw	$a1, size				#$a1 = size
			lw	$a2, data_size				#$a2 = dataSize
			jal 	find_next				#returns $v0 = rowIndex and $v1 = colIndex
			
									#inputs to is_valid
			move 	$t5, $v0				#$t5 = rowIndex
			move	$t6, $v1				#$t6 = colIndex
			
			beq	$t5, 0xffffffff, done			#if $t5 = rowIndex == -1 (no more empty spot), return true
			
									#if there's an empty spot, guess from 1 to 4
			li	$t4, 0x31	  			#$t4 = initial guess = 0x31
			subi	$t7, $s0, 1				#$t7 = 0x4 - 1 = 0x3 (to make it scalable)
			add	$t7, $t7, $t4				#$t7 = max guess = 0x31 + 0x3 = 0x34
guess_forloop:		bgt	$t4, $t7, guess_endloop 		#for i in range(1, max guess), if it ends, return false
			
									#check if guess is valid
			la	$a0, grid				#$a0 = baseAddress for is_valid
			move	$a1, $t5  				#$a1 = rowIndex for is_valid
			move	$a2, $t6				#$a2 = colIndex for is_valid
			move	$a3, $t4				#$a3 = guess
			jal	is_valid				#checking if it's valid
			move	$t0, $v0				#moving result to $t0 (1 if valid, 0 if not valid)
			
			get_address($t2, $a1, $a2, $s0, $s2, $s1)	#$t2 = resulting address (grid[row][col])
			
			beq	$t0, 0, backtrack			#if is_valid(puzzle, i, row, col):
			sw	$t4, 0($t2)				#grid[row]col] = $t4 = guess
												
			jal	solve					##recursive call
			move 	$t1, $v0				#$t1 = result of solve (1 if solved, 0 if not)
			beq	$t1, 1, done				#if solve(puzzle):
			
backtrack:		sw	$t3, 0($t2)				#puzzle[row][col] = $t3 = 0x30	
			addi	$t4, $t4, 0x1				#$t4 = guess++
			j	guess_forloop				#loop back
				
guess_endloop:		li	$v0, 0					#return false
			j	end
done:			li	$v0, 1					#return true

end:			########end########
			lw 	$ra, ($sp)				
			lw	$t0, 4($sp)				
			lw	$t1, 8($sp)				
			lw	$t2, 12($sp)				
			lw	$t3, 16($sp)				
			lw 	$t4, 20($sp)				
			lw	$t5, 24($sp)				
			lw	$t6, 28($sp)				
			lw	$t7, 32($sp)				
			lw	$s0, 36($sp) 				
			lw	$s1, 40($sp)				
			lw	$s2, 44($sp)				
			addi 	$sp, $sp, 48				
			########end########
			jr	$ra

.data
inp:			.asciiz "testing"
			.space 	4
grid:			.word 	1, 1, 1, 1
			.word 	2, 2, 2, 2
			.word 	3, 3, 3, 3
			.word 	4, 4, 4, 4
size: 			.word 	4
data_size:		.word	4
space:			.asciiz "\n"
		
		
