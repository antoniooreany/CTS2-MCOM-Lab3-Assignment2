###############################################
# MCOM-Labor: Vorlage fuer Assemblerprogramm
# Edition History:
# 28-04-2009: Getting Started - ms
# 12-03-2014: Stack organization changed - ms
###############################################

###############################################
# Definition von symbolen Konstanten
###############################################
	#.equ PUSH_r9_1, subi sp, sp, 4
	#.equ PUSH_r9_2, stw r9, (sp)
	#.equ POP_r9_1, ldw r9, (sp)
	#.equ POP_r9_2, addi sp, sp, 4
	.equ STACK_SIZE, 0x400	# stack size
	.equ periodl_addr, 0xFF202008
	.equ periodh_addr, 0xFF20200C
	.equ control_addr, 0xFF202004
	.equ status_addr, 0xFF202000
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
	movia r15, 200000000	# r15 <- 200.000.000 // 2 seconds
	call init_timer		# subroutine init_timer(r15) is called
	movi r7, 1
	call write_LED		# write_LED(on)
	call wait_timer		# subroutine wait_timer() is called
	mov r7, r0	
	call write_LED		# write_LED(on)
	br endloop		# end

init_timer:
	movia r2, periodl_addr	# periodl_addr -> r2
	sth r15, (r2)		# r15L -> periodl TODO: ?is it enough to write only one word?
	movia r2, periodh_addr	# periodh_addr -> r2
	srli r15, r15, 16	# shift right by 16 bits
	sth r15, (r2)		# r15H -> periodh TODO: ?is it enough to write only one word?
	ret
	
wait_timer:
	movia r2, control_addr	# control_addr -> r2
	ldw r15, (r2)		# content of control -> r15
	ori r15, r15, 0b0100	# mask 2nd bit of the content of control (r15||0b0100 -> r15)
	stw r15, (r2)		# start timer(masked content of control -> control)
	movia r2, status_addr	# status_addr -> r2
	stw r0, (r2)		# control <- 0 for explicit clear the timeout-bit
WHILE:
	movia r2, status_addr	# status_addr -> r2
	ldw r15, (r2)		# status -> r15
	andi r15, r15, 0b0001	# mask the content of the status
	beq r15, r0, WHILE	# if timer is not expired(masked status == 0), check again
				# the timer has expired(masked status != 0)
	ret
	
	
###############################################
write_LED:
	subi sp, sp, 4		# PUSH_r9_1
	stw r9, (sp)		# PUSH_r9_2
	movia r9, 0xFF200000	# r9 <- 0xFF200000=output_register_address
	
	stw r7, (r9)		# r7 -> (r9) COUNTER -> output_register
	ldw r9, (sp)		# POP_r9_1
	addi sp, sp, 4		# POP_r9_2
ret
###############################################


endloop:
	br endloop		# that's it
###############################################
	.end





	
