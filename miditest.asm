.eqv TIME 100
.eqv INSTRUMENT 36

.data

notes:	.byte	
	64,59,60,62,64,62,60,59, 57,57,60,64,62,60, 59,60,62,64, 60,57,57, 62,65,69,67,65, 64,60,64,62,60, 59,59,60,62,64, 60,57,57
	#E,B,C,D,E,D,C,B, A,A,C,E,D,C, B,C,D,E, C,A,A, D,E,A1,G,F, E,C,E,D,C, B,B,C,D,E, C,A,A

times:	.byte
	#the value 1 is a 16th of a bar
	4,2,2,2,1,1,2,2, 4,2,2,4,2,2, 6,2,4,4, 4,4,10, 4,2,4,2,2, 6,2,4,2,2, 4,2,2,4,4, 4,4,8

.text
main:	
	la	$t0, notes
	la	$t1, times
	li	$t2, 39
	li	$t3, TIME
	
	li	$v0, 32
	li	$a0, 200 
	syscall
	
	loop:
	lb	$t5, ($t1)
	mul	$t4, $t3, $t5
	
	li	$v0, 31
	lb 	$a0, ($t0)
	move	$a1, $t4 
	addi	$a1, $a1, 50
	li	$a2, INSTRUMENT
	li	$a3, 127
	syscall
	
	li	$v0, 32
	move	$a0, $t4 
	syscall
	
	addi	$t0, $t0, 1
	addi	$t1, $t1, 1
	addi	$t2, $t2, -1
	bne  	$t2, 0, loop
	
	la	$t0, notes
	la	$t1, times
	li	$t2, 39
	
	j loop
	

exit:	li	$v0, 10
	syscall
