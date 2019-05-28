###############################################
# MCOM-Labor: Vorlage fuer Assemblerprogramm
# Edition History:
# 28-04-2009: Getting Started - ms
# 12-03-2014: Stack organization changed - ms
###############################################

###############################################
# Definition von symbolen Konstanten
###############################################
	.equ STACK_SIZE, 0x400	# stack size
	
	.equ PUSH_r9_1, subi sp, sp, 4
	.equ PUSH_r9_2, stw r9, (sp)
	
	.equ POP_r9_1, ldw r9, (sp)
	.equ POP_r9_2, addi sp, sp, 4
	
	.equ PUSH_r2_1, subi sp, sp, 4
	.equ PUSH_r2_2, stw r2, (sp)
	
	.equ POP_r2_1, ldw r2, (sp)
	.equ POP_r2_2, addi sp, sp, 4
	
	.equ PUSH_r15_1, subi sp, sp, 4
	.equ PUSH_r15_2, stw r15, (sp)
	
	.equ POP_r15_1, ldw r15, (sp)
	.equ POP_r15_2, addi sp, sp, 4
###############################################
# DATA SECTION
# assumption: 12 kByte data section (0 - 0x2fff)
# stack is located in data section and starts
# directly behind used data items at address
# STACK_END.
# Stack is growing downwards. Stack size
# is given by STACK_SIZE. A full descending
# stack is used, accordingly first stack item
# is stored at address STACK_END+(STACKSIZE).
###############################################	
	.data
TST_PAK1:
	.word 0x11112222	# test data

STACK_END:
	.skip STACK_SIZE	# stack area filled with 0

###############################################
# TEXT SECTION
# Executable code follows
###############################################
	.global _start
	.text
_start:
	#######################################
	# stack setup:
	# HAVE Care: By default JNiosEmu sets stack pointer sp = 0x40000.
	# That stack is not used here, because SoPC does not support
	# such an address range. I. e. you should ignore the STACK
	# section in JNiosEmu's memory window.
	
	movia	sp, STACK_END		# load data section's start address
	addi	sp, sp, STACK_SIZE	# stack start position should
					# begin at end of section
START:
########################################################################################
	#mov r7, r0		# COUNTER init

LOOP:
	#call write_LED		# subroutine write_LED is called
	#call read_COUNT_BUTTON	# subroutine read_COUNT_BUTTON is called
	#call read_CLEAR_BUTTON	# subroutine read_CLEAR_BUTTON is called
	#br LOOP		# check for the key pressed again
########################################################################################

	movi r15, 0x1068	# r15 <- 4200
	call init_timer		# subroutine init_timer(r15) is called
	
	call wait_timer		# subroutine wait_timer() is called
	
	br endloop		# end

init_timer:
	movia r2, 0xFF202008	# periodl_addr -> r2
	stw r15, (r2)		# r15 -> period_n TODO: ?is it enough to write only one word?
	ret
	
wait_timer:
	movia r2, 0xFF202004	# control_addr -> r2
	movui r15, 0b0100	# 0b0100 -> r15
	stw r15, (r2)		# start timer(0b0100 -> control)
WHILE:
	movia r2, 0xFF202000	# status_addr -> r2
	ldw r15, (r2)		# status -> r15
	andi r15, r15, 0b0001	# mask the content of the status
	beq r15, r0, WHILE	# if timer is not expired(masked status == 0), check again
				# the timer has expired(masked status != 0)
	ret



########################################################################################
read_COUNT_BUTTON:
	PUSH_r9_1
	PUSH_r9_2
	movia r9, 0x840		# r9 <- 0x840
	ldw r9, (r9)		# r9 <- (0x840)
	andi r9, r9, 0x1	# r9 <- masked value of (0x840)
	bne r9, r0, RELEASED	# Pressed: if r9!=0 => goto RELEASED
	br return_read_COUNT_BUTTON
RELEASED:
	movia r9, 0x840		# r9 <- 0x840
	ldw r9, (r9)		# r9 <- (0x840)
	andi r9, r9, 0x1	# r9 <- masked value of (0x840)
	bne r9, r0, RELEASED	# Pressed: if r9!=0 => goto RELEASED
	addi r7, r7, 1		# Pressed: COUNTER++ 
return_read_COUNT_BUTTON:
	POP_r9_1
	POP_r9_2
	ret	
	
read_CLEAR_BUTTON:
	PUSH_r9_1
	PUSH_r9_2
	movia r9, 0x840		# r9 <- 0x840
	ldw r9, (r9)		# r9 <- (0x840)
	andi r9, r9, 0x8	# r9 <- masked value of (0x840)
	beq r9, r0, return_CLEAR_BUTTON	# if r9==0 => goto return_COUNT_BUTTON 
	mov r7, r0		# COUNTER=0
return_CLEAR_BUTTON:
	POP_r9_1
	POP_r9_2
	ret			# return

write_LED:
	PUSH_r9_1
	PUSH_r9_2
	movia r9, 0x810		# r9 <- 0x810=output_register_address
	stw r7, (r9)		# r7 -> (r9) COUNTER -> output_register
	POP_r9_1
	POP_r9_2
	ret

endloop:
	br endloop		# that's it
###############################################
	.end
	