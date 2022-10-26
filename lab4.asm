########################################################################################################################
# Created by:  Cesario, Ethan
#	       1829522 
#	       2 December, 2021
#
# Assignment:  Lab 4: Functions and Graphics
#              CSE 12: Computer Systems Assembly Language and Lab 
#              UC Santa Cruz, Fall 2021
#
# Description: This program has macros and subroutines that work with one another to make lines, pixels, and crosshairs
#              on a 1 unit width and height, and a 128 unit height and width display. Pixels also have select colors.
#              Base address display should be set to. 0xFFFF0000
#
# Notes: This program is intended to be run from MARS IDE
#######################################################################################################################

# Spring 2021 CSE12 Lab 4 Template
######################################################
# Macros made for you (you will need to use these)
######################################################

# Macro that stores the value in %reg on the stack 
#	and moves the stack pointer.
.macro push(%reg) # Given macro that allow selected registers to be pushed onto the stack
	subi $sp $sp 4
	sw %reg 0($sp)
.end_macro 

# Macro takes the value on the top of the stack and 
#	loads it into %reg then moves the stack pointer.
.macro pop(%reg) # Given macro that allow selected registers to be popped onto the stack
	lw %reg 0($sp)
	addi $sp $sp 4	
.end_macro

#################################################
# Macros for you to fill in (you will need these)
#################################################

# Macro that takes as input coordinates in the format
#	(0x00XX00YY) and returns x and y separately.
# args: 
#	%input: register containing 0x00XX00YY
#	%x: register to store 0x000000XX in
#	%y: register to store 0x000000YY in
.macro getCoordinates(%input %x %y)
	and %y, %input, 0x000000FF # This compares the given coordinate against a base coordinate to find the proper coordinates for the y portion
	srl %x, %input, 16         # Intervals the coordianate the proper bit amount, the gives the x portion
	 
.end_macro

# Macro that takes Coordinates in (%x,%y) where
#	%x = 0x000000XX and %y= 0x000000YY and
#	returns %output = (0x00XX00YY)
# args: 
#	%x: register containing 0x000000XX
#	%y: register containing 0x000000YY
#	%output: register to store 0x00XX00YY in

.macro formatCoordinates(%output %x %y) 
	sll %output, %x, 16      # This compares adds in the x portion into the output address, making sure to space it 16 bits so it does not get confused with the y coordinates portion
	add %output, %output, %y # This adds the y section needed into the register address by adding into the current address with xx coordinates already inside
	
.end_macro 

# Macro that converts pixel coordinate to address
# 	  output = origin + 4 * (x + 128 * y)
# 	where origin = 0xFFFF0000 is the memory address
# 	corresponding to the point (0, 0), i.e. the memory
# 	address storing the color of the the top left pixel.
# args: 
#	%x: register containing 0x000000XX
#	%y: register containing 0x000000YY
#	%output: register to store memory address in
.macro getPixelAddress(%output %x %y)
	
	li $t6, 128                  # Assigns value 128 to register $t6 to be used for later computations   
    	li $t7, 4                    # Assigns value 4 to register $t7 to be used for later computations   
    	mul $t6, $t6, %y	     # Multiplies the value, 4 in register $t6 by the given y address then stores in register $t6
    	add $t6, $t6, %x             # Adds the value in register $t6 by the given x address then stores in register $t6
    	mul $t6, $t6, $t7            # Multiplies the value in register $t6 by the value in register $t7, value of 128, then stores in register $t6
	add %output, $t6, 0xFFFF0000 # Adds the value in register $t6, by 0xFFFF0000, this will give the proper final pixel address, and is finally stored in %output 
	
.end_macro


.text
# prevent this file from being run as main
li $v0 10 
syscall

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Subroutines defined below
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#*****************************************************
# Clear_bitmap: Given a color, will fill the bitmap 
#	display with that color.
# -----------------------------------------------------
# Inputs:
#	$a0 = Color in format (0x00RRGGBB) 
# Outputs:
#	No register outputs
#*****************************************************
clear_bitmap: nop
	
	push($t0)            # Pushes register $t0 onto the stack 
	push($t1)            # Pushes register $t1 onto the stack 
	li $t0, 0xFFFF0000   # Clears/Reassigns register $t0 to be safe, this is the starting blank address
	li $t1, 0xFFFFFFFC   # Clears/Reassigns register $t1 to be safe, this is the final blank address
	
	while:                    # Start/Main body of the loop
 		beq $t0, $t1, end # Loop tracker to see if finished criteria is met
 		sw $a0, ($t0)     # Stores register $t0 onto $a0, this will be used to assign each coordinate the gray slate color used to paint the bitmap display
 		addi $t0, $t0, 4  # Adds 4 into register $t0, this will move the address directly onto the next drawable bit
 		j while           # Jumps back to main of the loop to go again
 		
 	end:                      # End of the loop, criteria has been met
 		sw $a0, ($t0)     # Stores the address one last for the final bit
 		addi $t0, $t0, 4  # Intervals for the last bit a final time, might be redundant
 		pop($t1)          # Pops register $t1 from the stack
 		pop($t0)          # Pops register $t0 from the stack
 		jr $ra # Jumps back to lab4_f21_test.asm

#*****************************************************
# draw_pixel: Given a coordinate in $a0, sets corresponding 
#	value in memory to the color given by $a1
# -----------------------------------------------------
#	Inputs:
#		$a0 = coordinates of pixel in format (0x00XX00YY)
#		$a1 = color of pixel in format (0x00RRGGBB)
#	Outputs:
#		No register outputs
#*****************************************************
draw_pixel: nop
	
	push ($t0)                      # Pushes register $t0 onto the stack
	push ($t1)                      # Pushes register $t1 onto the stack
	push ($t2)                      # Pushes register $t2 onto the stack
	li $t0, 0                       # Clears/Reassigns register $t0 to be safe
	li $t1, 0                       # Clears/Reassigns register $t1 to be safe
	li $t2, 0                       # Clears/Reassigns register $t2 to be safe
	getCoordinates ($a0, $t0, $t1)  # Runs macro GetCoordinates to deassemble coordinate into usable x and y values
	getPixelAddress ($t2, $t0, $t1) # Runs macro getPixelAddress to properly get correct bitmap display address from earlier found x and y values
	sw $a1, ($t2)                   # Stores the found Pixed Address from register $t2 and places it in $a1 for use
	pop ($t2)                       # Pops register $t2 from the stack
	pop ($t1)                       # Pops register $t1 from the stack
 	pop($t0)          		# Pops register $t0 from the stack
	jr $ra # Jumps back to lab4_f21_test.asm
	
#*****************************************************
# get_pixel:
#  Given a coordinate, returns the color of that pixel	
#-----------------------------------------------------
#	Inputs:
#		$a0 = coordinates of pixel in format (0x00XX00YY)
#	Outputs:
#		Returns pixel color in $v0 in format (0x00RRGGBB)
#*****************************************************
get_pixel: nop
    	
    	li $t0, 0                       # Clears/Reassigns register $t0 to be safe
	li $t1, 0		        # Clears/Reassigns register $t1 to be safe
	li $t2, 0		        # Clears/Reassigns register $t2 to be safe
	push ($t0)		        # Pushes register $t0 onto the stack	
	push ($t1)                      # Pushes register $t1 onto the stack
	push ($t2)                      # Pushes register $t2 onto the stack
	getCoordinates($a0, $t0, $t1)   # Runs macro GetCoordinates to deassemble coordinate into usable x and y values
	getPixelAddress ($t2, $t0, $t1) # Runs macro getPixelAddress to properly get correct bitmap display address from earlier found x and y values
	lw $v0, ($t2)                   # Stores the found Pixed color from register $t2 and places it in $v0 for use 
	pop ($t2)			# Pops register $t2 from the stack
	pop ($t1)			# Pops register $t1 from the stack
	pop ($t0)			# Pops register $t0 from the stack
	jr $ra # Jumps back to lab4_f21_test.asm

#*****************************************************
# draw_horizontal_line: Draws a horizontal line
# ----------------------------------------------------
# Inputs:
#	$a0 = y-coordinate in format (0x000000YY)
#	$a1 = color in format (0x00RRGGBB) 
# Outputs:
#	No register outputs
#*****************************************************
draw_horizontal_line: nop
	
	push ($t2)				# Pushes register $t2 onto the stack
	push ($t3)				# Pushes register $t3 onto the stack
	push ($a0)				# Pushes register $a0 onto the stack
	push ($t9)				# Pushes register $t9 onto the stack
	li $t9, 0				# Clears/Reassigns register $t9 to be safe
	li $t2, 0				# Clears/Reassigns register $t2 to be safe
	la $t3, ($a0)				# Loads register $a0, into register $t3, this will carry the y coordinates that will be used in later macros
	
	while_horizontal:			# Start/Main of the loop which will draw a horizontal line
			
		beq $t9, 128, end_horizontal	 # Parameter which checks if the entirety of the line is drawn, if yes it will jump to the end of the loop
		formatCoordinates($a0, $t2, $t3) # Runs macro with blank x coordinates and given y coordinates from the start of sub routine, then this will combine the x and y coordinates to be used for drawing the horizontal line
		push ($ra)			 # Pushes back to the main test program, fetches or already has the color of the needed coordinate	
		jal draw_pixel			 # Runs Macro drawing pixel with given proper coordinate and fetched color
		pop ($ra)			 # Pops back from the main test program	
		addi $t2, $t2, 1                 # Adds 1 to the $t2 register which will move the loop onto the next coordinate
		addi $t9, $t9, 1                 # Adds 1 to the $t9 register which will be used for incramenting the loop
		j while_horizontal               # Jumps back to the main of the while_horizontal loop, thus starting the loop over again
	
	end_horizontal:   # End of the draw_horizontal_line loop, criteria has been met
		
		pop ($t9) # Pops register $t9 from the stack
		pop ($a0) # Pops register $a0 from the stack
		pop ($t3) # Pops register $t3 from the stack
		pop ($t2) # Pops register $t2 from the stack
 		jr $ra # Jumps back to lab4_f21_test.asm


#*****************************************************
# draw_vertical_line: Draws a vertical line
# ----------------------------------------------------
# Inputs:
#	$a0 = x-coordinate in format (0x000000XX)
#	$a1 = color in format (0x00RRGGBB) 
# Outputs:
#	No register outputs
#*****************************************************
draw_vertical_line: nop
	
	push ($t2)    # Pushes register $t2 onto the stack
	push ($t3)    # Pushes register $t3 onto the stack
	push ($a0)    # Pushes register $a0 onto the stack
	push ($t9)    # Pushes register $t9 onto the stack
	li $t9, 0     # Clears/Reassigns register $t9 to be safe
	li $t3, 0     # Clears/Reassigns register $t3 to be safe
	la $t2, ($a0) # Loads register $a0, into register $t2, this will carry the x coordinates that will be used in later macros
	
	while_vertical: # Start/Main of the loop which will draw a vertical line
		
		beq $t9, 128, end_vertical       # Parameter which checks if the entirety of the line is drawn, if yes it will jump to the end of the loop
		formatCoordinates($a0, $t2, $t3) # Runs macro with blank y coordinates and given x coordinates from the start of sub routine, then this will combine the x and y coordinates to be used for drawing the vertical line
		push ($ra)			 # Pushes back to the main test program, fetches or already has the color of the needed coordinate
		jal draw_pixel			 # Runs Macro drawing pixel with given proper coordinate and fetched color
		pop ($ra)      			 # Pops back from the main test program	
		addi $t3, $t3, 1		 # Adds 1 to the $t3 register which will move the loop onto the next coordinate
		addi $t9, $t9, 1		 # Adds 1 to the $t9 register which will be used for incramenting the loop
		j while_vertical		 # Jumps back to the main of the while_vertical loop, thus starting the loop over again
	
	end_vertical: # End of the draw_vertical_line loop, criteria has been met
		
		pop ($t9) # Pops register $t9 from the stack
		pop ($a0) # Pops register $a0 from the stack
		pop ($t3) # Pops register $t3 from the stack
		pop ($t2) # Pops register $t2 from the stack
 		jr $ra # Jumps back to lab4_f21_test.asm


#*****************************************************
# draw_crosshair: Draws a horizontal and a vertical 
#	line of given color which intersect at given (x, y).
#	The pixel at (x, y) should be the same color before 
#	and after running this function.
# -----------------------------------------------------
# Inputs:
#	$a0 = (x, y) coords of intersection in format (0x00XX00YY)
#	$a1 = color in format (0x00RRGGBB) 
# Outputs:
#	No register outputs
#*****************************************************
draw_crosshair: nop
	
	push($ra)
	
	# HINT: Store the pixel color at $a0 before drawing the horizontal and 
	# vertical lines, then afterwards, restore the color of the pixel at $a0 to 
	# give the appearance of the center being transparent.
	
	# Note: Remember to use push and pop in this function to save your t-registers
	# before calling any of the above subroutines.  Otherwise your t-registers 
	# may be overwritten.  
	
	# YOUR CODE HERE, only use t0-t7 registers (and a, v where appropriate)
	
	jal get_pixel # This grabs the center of the crosshairs pixel color which will be saved for later use in which it will be reprinted with the original colors once lines have been drawn
	push ($a1)    # Pushes register $a1 onto the stack
	push ($t2)    # Pushes register $t2 onto the stack
	push ($t3)    # Pushes register $t3 onto the stack
	push ($a0)    # Pushes register $a0 onto the stack
	push ($t1)    # Pushes register $t1 onto the stack
	la $t0, ($v0) # Loads the pixel color from  register $v0 from the macro get_pixel and stores it in register $t0 for later use 
	
	getCoordinates($a0, $t2, $t3) # Runs macro GetCoordinates to deassemble coordinate into usable x and y values
	
	la $a0, ($t2)          # Stores the y format only from register $t2 into register $a0, where it will be used in drawing the vertical line section if the crosshair
	jal draw_vertical_line # Macro that will draw the vertical line portion of the crosshair, will use the coordinate saved in $a0
	
	la $a0, ($t3)            # Stores the x format only from register $t3 into register $a0, where it will be used in drawing the horizontal line section if the crosshair
	jal draw_horizontal_line # Macro that will draw the horizontal line portion of the crosshair, will use the coordinate saved in $a0
	
	la $a1, ($t0)                    # Stores the saved gray color from before and inputs that value from register $t1 into register $a0
	formatCoordinates($a0, $t2, $t3) # Uses macro formatCoordinates with saved values x and y values in registers $t2 and $t3, then will have new combined address saved in register $a0
	jal draw_pixel                   # Uses macro draw_pixel to fill in the center coordinate from address saved in register $a0 and color saved in register $a1
	
	pop ($t1) # Pops register $t1 from the stack
	pop ($a0) # Pops register $a0 from the stack
	pop ($t3) # Pops register $t3 from the stack
	pop ($t2) # Pops register $t2 from the stack
	pop ($a1) # Pops register $a1 from the stack
	# HINT: at this point, $ra has changed (and you're likely stuck in an infinite loop). 
	# Add a pop before the below jump return (and push somewhere above) to fix this.
	jr $ra # Jumps back to lab4_f21_test.asm
