.eqv WIDTH 16
.eqv HEIGHT 32
.eqv MEM 0x10008000 
.eqv INSTRUMENT 36

.eqv	PURPLE	0x00c032fc
.eqv	CYAN	0x0000FFFF 
.eqv	ORANGE	0x00fc9c00
.eqv	BLUE	0x00404dff
.eqv	YELLOW	0x00FFFF00
.eqv	GREEN 	0x0000FF00
.eqv	RED 	0x00FF0000
.eqv	WHITE	0x00FFFFFF
.eqv	GREY	0x00262626
.eqv	MAROON	0x005F0000
.eqv	BACKGROUND	0x00e3d798

.data
blinking:	.space	160
clearedlines:	.space	4
score: 	.word	0	
colours:.word	PURPLE, CYAN, ORANGE, BLUE, YELLOW, GREEN, RED
#store each block in an array of smaller arrays, one for each rotation.
blocks:	.byte 	-16,-1,0,1, -16,0,1,16, -1,0,1,16, -16,-1,0,16,	#t block
		-1,0,1,2, -16,0,16,32, -2,-1,0,1, -32,-16,0,16			#line block
		-1,0,1,-15, -16,0,16,17, -1,0,1,15, -17,-16,0,16		#L block
		-17,-1,0,1, -16,-15,0,16, -1,0,1,17, -16,0,15,16		#Reverse L block
		-16,-15,0,1, -16,-15,0,1, -16,-15,0,1, -16,-15,0,1		#square
		-16,-15,-1,0, -16,0,1,17, 0,1,15,16, -17,-1,0,16		#squiggly block
		-17,-16,0,1, -15,0,1,16, -1,0,16,17, -16,-1,0,15		#reverse squiggly block
numberframes:	.byte	1,4,16,17,21,23,28,29,31
numbers:	.byte 	8,3,8, 3,8,0, 5,4,7, 4,4,8, 6,1,8, 7,4,5, 8,4,5, 2,2,8, 8,4,8, 7,4,8
speed:		.byte 	25
heldpiece:	.byte	7
.text

main:
	li 	$v0, 30  	#seed based on time
	syscall 	
	move	$a1, $a0
	li 	$a0, 1
	li 	$v0, 40
	syscall
	li	$s3, 0
	
	jal	drawbackground
	
	li	$t3, 1		#ignore first drawblock
	li	$a0, 9		
	li	$a1, -1
	
	newpiece:
		li	$s3, 0
		addi	$a1, $a1, -1	#lock in old block
		li	$t3, 0
		jal	drawblock
		jal	clearlines
			
		li 	$v0, 42  	#generate random piece
		li 	$a1, 7
		syscall 	
		move	$s6, $a0
	ready:				#holding a piece jumps here - no lock or generate
		li	$a0, 9		#starting positions
		li	$a1, 0
		li	$s7, 0
		jal	indic
	loop:
		bne	$s2, 0, nomov
		li	$t3,1
		jal	drawblock		#only erase the block here - indicator should be the same anyways
		addi	$a1, $a1, 1		#movement happens - check if possible, if not, then place
		jal	checkok
		beq	$t1, 1, newpiece
		lb 	$s2, speed
		nomov:
		li	$t3, 0
		jal	drawblock
		
		addi	$s2, $s2, -1	#iterate movement checker
		li	$v0, 32		# delay code
		move	$t0, $a0
		li	$a0, 20
		syscall
		move	$a0, $t0
		
		lw 	$t0, 0xffff0000		# check for input
    		beq 	$t0, 0, loop   		# process input	
    		li	$t3,1			
		jal	drawblock		#only erase when input is called
    		li	$t3,1
		jal	indic				
		lw 	$s1, 0xffff0004		## controls ##	
		beq	$s1, 113, exit		# q - exit
		beq	$s1, 105, rotright	# i - rotate right
		beq	$s1, 107, down		# k - move down
		beq	$s1, 106, left		# j - move left
		beq	$s1, 108, right		# l - move right
		beq	$s1, 122, rotleft	# z - rotate left
		beq	$s1, 99, hold		# c - hold
		beq	$s1, 32, slam		# space - slam
		j 	loop
	
exit:	li	$v0, 10
	syscall

#################################################
# subroutine to draw a pixel
# $a0 = X
# $a1 = Y
# $a2 = color
drawpixel:
	addi 	$sp, $sp, -4
	sw 	$ra, ($sp)
	
	mul	$s1, $a1, WIDTH 	# get Y value
	add	$s1, $s1, $a0		# add X
	mul	$s1, $s1, 4		# multiply by 4 to get word offset
	add	$s1, $s1, MEM		# add to base address
	sw	$a2, 0($s1)		# store color at memory location
	lw 	$ra, ($sp)		#return
	addi 	$sp, $sp, 4
	jr 	$ra
	
# draw a horizontal line
# $t1 is the length
line:
	addi 	$sp, $sp, -4
	sw 	$ra, ($sp)
	li	$t0, 0
	lineloop:
		jal drawpixel
		addi	$a0, $a0, 1
		addi	$t0, $t0, 1
	bne	$t0, $t1, lineloop
	sub	$a0, $a0, $t1		#reset value for simplicity
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr	$ra

# draw the indicator
indic:
	addi 	$sp, $sp, -4
	sw 	$ra, ($sp)
	
	move	$t5, $a1
	indicloop:			#find the valid position
		addi	$a1, $a1, 1
		jal 	checkok
	beq	$t1, 0, indicloop
	addi	$a1, $a1, -1
	
	beq 	$t3, 1, eraseindic	#if run with t3 as 1, erase 	
	li	$t3, 2
	eraseindic:
	jal	drawblock
	
	move	$a1, $t5
	li	$t3, 0
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr	$ra

# draw a block at current position
# $s6 is type of block
# $s7 is rotation  
# $t3 erases
drawblock:				
	addi 	$sp, $sp, -4
	sw 	$ra, ($sp)

	li 	$t0, 0
	la	$t2, blocks
	mul	$t9, $s6, 16
	add	$t2, $t2, $t9	#move to correct position in blocks array
	mul	$t9, $s7, 4
	add	$t2, $t2, $t9	
	
	mul	$s1, $a1, WIDTH
	add	$s1, $s1, $a0
	mul	$s1, $s1, 4
	add	$s1, $s1, MEM
	move	$t9, $s1
	
	#colour setting
	li	$a2, GREY
	beq 	$t3, 2, blockloop	#if run with t3 as 2, set to grey 
	li	$a2, 0
	beq 	$t3, 1, blockloop	#if run with t3 as 1, erase 
	mul	$t4, $s6, 4
	la	$t3, colours
	add	$t3, $t3, $t4		#otherwise, set color normally
	lw	$a2, ($t3)
	
	blockloop:		#draw the block
		move	$s1, $t9
		lb	$t4, ($t2)
		mul	$t4, $t4, 4
		add	$s1, $s1, $t4
		sw	$a2, ($s1)
		
		addi	$t2, $t2, 1
		addi	$t0, $t0, 1
	bne 	$t0, 4, blockloop
	
	li	$t3, 0
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr	$ra

# draws background
drawbackground:
	addi 	$sp, $sp, -4
	sw 	$ra, ($sp)
	
	li 	$a0, 0	#set starting position
	li 	$a1, -1
	li	$a2, BACKGROUND
	li	$t1, WIDTH
	li	$t2, HEIGHT
	li	$t3, 0	#establish loop
	fill:		#makes background colour
		
		addi	$a1, $a1, 1
		addi	$t3, $t3, 1
		jal 	line
	bne	$t3, $t2, fill
	
	li 	$a0, 5	
	li 	$a1, 0
	li	$a2, 0
	li	$t1, 10
	li	$t2, 26
	playspace:	#create playspace
		jal 	line
		addi	$a1, $a1, 1
		addi	$t2, $t2, -1
	bne	$t2, 0, playspace
	
	li 	$a0, 0
	li 	$a1, 1
	li	$a2, 0
	li	$t1, 4
	li	$t2, 6
	holdbox:	#create holdbox
		jal 	line
		addi	$a1, $a1, 1
		addi	$t2, $t2, -1
	bne	$t2, 0, holdbox
	
	#draw text
	li 	$a0, 13
	li	$a1, 31
	li	$a2, 0
	li	$t1, 2
	jal 	line
	li	$a1, 30		
	scoreL:
		jal 	drawpixel
		addi	$a1, $a1, -1
	bne	$a1, 27, scoreL
	
	jal	drawscore
	
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr	$ra

checkok:	#performs a check on the next value to see if everything is fine
	addi 	$sp, $sp, -4
	sw 	$ra, ($sp)
		
	li 	$t0, 0
	la	$t2, blocks
	mul	$t9, $s6, 16
	add	$t2, $t2, $t9	#move to correct position in blocks array
	mul	$t9, $s7, 4
	add	$t2, $t2, $t9	
	move	$t9, $a0
	checkloop:		#check all block positions
		move	$a0, $t9
		lb	$t4, ($t2)
		add	$a0, $a0, $t4
		
		mul	$s1, $a1, WIDTH
		add	$s1, $s1, $a0
		mul	$s1, $s1, 4
		add	$s1, $s1, MEM
		
		lw	$t8, 0($s1)		#if the space isnt black or grey, return failure
		beq	$t8, 0, goodcheck
		beq	$t8, GREY, goodcheck
		j	badcheck
		goodcheck:
		addi	$t2, $t2, 1
		addi	$t0, $t0, 1
	bne 	$t0, 4, checkloop
	#completed checks
	li 	$t1, 0
	move	$a0, $t9
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr	$ra
	badcheck:
	li 	$t1, 1
	move	$a0, $t9
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr	$ra

clearlines:
	addi 	$sp, $sp, -4
	sw 	$ra, ($sp)
	
	la	$t4, clearedlines
	sw	$0, ($t4)
	
	# scan for complete lines, store the next 4 lines
	# do this because max amount of lines cleared at a time is 4, a tetris
	# begin the check at y value 26
	li	$a1, 26	
	li	$t5, -1
	li	$a0, 5	
	li	$t3, 0
	clearloop:
		addi	$t5, $t5, 1
		beq	$t5, 25, completeclear
		addi	$a1, $a1, -1
		li	$t0, 0
		mul	$s1, $a1, WIDTH	
		add	$s1, $s1, $a0
		mul	$s1, $s1, 4
		add	$s1, $s1, MEM
		
		checklineloop:				#check that all spaces are NOT black
			lw	$t2, 0($s1)
			beq	$t2, 0, clearloop
			
			addi	$s1, $s1, 4
			
			addi	$t0, $t0, 1
		bne	$t0, 11, checklineloop
		
		#getting here means that the loop finished - a line has been cleared
		addi	$t3, $t3, 1		# score
		
		la	$t0, clearedlines	# store the y values of the lines cleared
		add	$t0, $t0, $t3
		addi	$t0, $t0, -1
		sb	$a1, ($t0)
		
		la	$t1, blinking		
		addi	$t2, $t3, -1
		mul	$t2, $t2, 40
		add	$t1, $t1, $t2
		
		mul	$s1, $a1, WIDTH	
		add	$s1, $s1, $a0
		mul	$s1, $s1, 4
		add	$s1, $s1, MEM
		
		li	$t0, 0
		saveline:			# store the colours of the lines cleared
			lw	$t8, ($s1)
			sw	$t8, ($t1)
			
			addi	$s1, $s1, 4
			addi	$t1, $t1, 4
			addi	$t0, $t0, 1
		bne	$t0, 10, saveline
				
	bne	$t5, 25, clearloop
	completeclear:
	beq 	$t3, 0, endclear	#no score means no movement or effects, just end
	#add score
	lw	$t0, score
	add	$t0, $t0, $t3
	sw	$t0, score
	#change speed based on total score
	#speed goes faster every line 
	#maxes out at 3 speed
	
	li	$t4, 25
	sub	$t4, $t4, $t0
	blt 	$t0, 22, nonmaxspeed
	li	$t4, 3
	nonmaxspeed:
	sb	$t4, speed
	
	#blink effect
	li	$v0, 32		# delay code - blink time
	li	$a0, 200
	syscall
	li	$a0, 5
	
	li	$t5, 0
	blink:
		la	$t8, blinking
		la	$t4, clearedlines
		
		li	$t1, 0
		drawblinklines:				#draw the lines saved from memory
			lb	$a1, ($t4)		
			mul	$s1, $a1, WIDTH	
			add	$s1, $s1, 5
			mul	$s1, $s1, 4
			add	$s1, $s1, MEM
			
			li	$t2, 0
			drawsingleblinkline:
				
				lw	$a2, ($t8)
				sw	$a2, ($s1)
				
				addi	$t8, $t8, 4
				addi	$s1, $s1, 4
				addi	$t2, $t2, 1
			bne 	$t2, 10, drawsingleblinkline
			
			addi	$t4, $t4, 1
			addi	$t1, $t1, 1	
		bne 	$t1, $t3, drawblinklines
		
		li	$v0, 32		# delay code - time block stays on screen
		li	$a0, 200
		syscall
		li	$a0, 5
		
		la	$t4, clearedlines 
		li	$t2, 0
		blinkoutlines:		#black out the line
			lb	$a1, ($t4)
			li	$t1, 10
			li	$a2, WHITE
			jal	line
			addi	$t4, $t4, 1
			addi	$t2, $t2, 1
		bne 	$t2, $t3, blinkoutlines
		
		li	$v0, 32		# delay code - blink time
		li	$a0, 200
		syscall
		li	$a0, 5
		
		addi	$t5, $t5, 1
	bne	$t5, 3, blink
	
	#draw score on screen
	jal	drawscore
	
	#apply gravity and move everything down
	la	$t4, clearedlines
	add	$t4, $t4, $t3
	add	$t4, $t4, -1
	
	li	$t5, 0
	gravityloop:
		
		lb	$a1, ($t4)
		addi	$a1, $a1, -1
		
		li	$t0, 0
		loopup:
			mul	$s1, $a1, WIDTH		#start the loop from the highest store clearedline value
			add	$s1, $s1, 5
			mul	$s1, $s1, 4
			add	$s1, $s1, MEM
			li	$t1, 0
			shiftdown:
				lw	$t8, ($s1)	#move every piece above the stored line down once
				sw	$0, ($s1)
				sw	$t8, 64($s1)
			
				addi	$s1, $s1, 4
				addi	$t1, $t1, 1
			bne	$t1, 10, shiftdown
			
			addi	$a1, $a1, -1
		bne	$a1, 0, loopup
		
		addi	$t4, $t4, -1
		addi	$t5, $t5, 1
	bne	$t5, $t3, gravityloop
	
	endclear:	
	#check for loss, if top row has anything in it after lines are cleared
	li	$s1, 20
	add	$s1, $s1, MEM
	
	li	$t1, 0
	isthisloss:
		lw	$t0, ($s1)
		bne	$t0, 0, gameover
			
		addi	$s1, $s1, 4
		addi	$t1, $t1, 1
	bne	$t1, 10, isthisloss 

	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr	$ra

drawscore:
	addi 	$sp, $sp, -4
	sw 	$ra, ($sp)
	
	li	$a2, BACKGROUND
	li	$t5, 0
	li	$t1, 11
	li	$a0, 1
	li	$a1, 27
	
	clearscore:
		jal 	line	
		addi	$a1, $a1, 1
		addi	$t5, $t5, 1
	bne	$t5, 5, clearscore
	
	lw	$t0, score
	li	$t1, 0
	li	$t7, 100
	drawnumber:
		
		div	$t0, $t7
		mflo	$a0		#current digit
		mfhi	$t0		#leftover stuff
		div	$t7, $t7, 10
		
		la	$t6, numbers
		mul	$a1, $a0, 3
		add	$a1, $t6, $a1
		li	$t6, 0
		drawdigit:
			li	$s1, 1988	#move to correct position
			add	$s1, $s1, MEM	
			mul	$a0, $t1, 16
			add	$s1, $s1, $a0
			mul	$a0, $t6, 4
			add	$s1, $s1, $a0
			
			la	$a0, numberframes	#grab correct segment
			lb	$t5, ($a1)
			
			add	$a0, $a0, $t5
			lb	$t5, ($a0)
			
			li	$t4, 1
			drawsegment:			#draw out segment - they are stored in binary
				and	$t8, $t4, $t5
				beq	$t8, 0, emptyseg		
				sw	$0, ($s1)
				emptyseg:
				sll	$t4, $t4, 1
				addi	$s1, $s1, -64
			bne	$t4, 32, drawsegment
			
			addi	$a1, $a1, 1
			addi	$t6, $t6, 1
		bne	$t6, 3, drawdigit
		addi	$t1, $t1, 1
	bne	$t1, 3, drawnumber
	
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr	$ra
	
gameover:			#makes playspace maroon, makes score gold
	li	$t1, -1
	li	$s1, -4
	li	$t3, 16
	add	$s1, $s1, MEM
	li	$t2, MAROON
	recolour:
		beq	$t1, 415, setyellow
		beq	$t1, 512, exit
		addi	$s1, $s1, 4
		addi	$t1, $t1, 1
		lw	$t0, ($s1)
		
		div	$t1, $t3
		mfhi	$t4
		bne	$t4, 0, nonlinego
		li	$v0, 32		# delay code so it looks kinda cool
		li	$a0, 15
		syscall
		nonlinego:
		
		bne	$t0, 0, recolour
		sw	$t2, ($s1)
		j	recolour
	
	setyellow:
		li	$t2, YELLOW
		addi	$t1, $t1, 1
	j	recolour

#######################################################
#inputs
#call checkok before each movement - if it returns a failure, then don't perform the movement
left:	
	addi	$a0, $a0, -1
	
	jal 	checkok
	beq	$t1, 0, movupdated
	addi	$a0, $a0, 1
	j	movupdated
	
right:
	addi	$a0, $a0, 1
	
	jal 	checkok
	beq	$t1, 0, movupdated
	addi	$a0, $a0, -1
	j	movupdated
	
down:
	addi	$a1, $a1, 1
	jal 	checkok
	beq	$t1, 0, movupdated
	j	newpiece	
	
slam:
	slamloop:
		addi	$a1, $a1, 1
		jal 	checkok
	beq	$t1, 0, slamloop
	j	newpiece
	
rotleft:
	move	$t5, $s7
	bne 	$s7, 0, rotleftbound
	li	$s7, 4
	rotleftbound:
	addi	$s7, $s7, -1
	
	jal 	checkok
	beq	$t1, 0, movupdated
	move	$s7, $t5
	j	movupdated
rotright:
	move	$t5, $s7
	addi	$s7, $s7, 1	
	li	$t0, 4
	div	$s7, $t0
	mfhi	$s7		#modulus to ensure rotation stays in bounds
	
	jal 	checkok
	beq	$t1, 0, movupdated
	move	$s7, $t5
	j	movupdated
hold:
	beq	$s3, 1, loop
	li	$s3, 1
	
	lb	$t8, heldpiece
	bne	$t8, 7, ispiece
	#if there is nothing held, generate random
	li 	$v0, 42
	li 	$a1, 7
	syscall 	
	move	$t8, $a0
	
	ispiece:
	#erase from the hold slot
	li	$s7, 1
	li	$a0, 1
	li	$a1, 3
	sb	$s6, heldpiece
	move	$s6, $t8
	li	$t3, 1
	jal	drawblock
	#draw new held piece
	lb	$s6, heldpiece
	jal	drawblock
	
	move	$s6, $t8
	j	ready

movupdated:	#forces an update to the indicator
	jal	indic
	j	loop
