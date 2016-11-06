.data
oldtime: .word
newtime: .word
starttime: .word
xpos: .word
start: .word 0
end: .word 0
score: .asciiz "The game score is "
newline: .asciiz "\n"
semicolon: .asciiz ":"
subtracter: .byte
error: .asciiz "Error: buffer overflow"

.text

addi $a0, $zero, 31
addi $a1, $zero, 63
addi $a2, $zero, 2
jal _setLED #spawn bug buster in middle of bottom row
addi $s0, $0, 31 # $s0 is the buster's x coordinate

addi $s6, $k0, 0 #start
addi $s7, $k0, 0 #end

li $v0, 30
syscall
move $s4, $a0 #oldtime
move $s5, $a0 #starttime

addi $t5, $0, 0
sb $t5, subtracter #set subtracter to 0

mainloop:
keypress:
add $a0, $0, $s0
la $v0, 0xffff0000 # address for reading key press status
lw $t0, 0($v0) # read the key press status
andi $t0, $t0, 1
beq $t0, $0, continue	# no key pressed
lw $t0, 4($v0)
addi $v0, $t0, -226 # check for left key press
beq $v0, $zero, lkey
addi $v0, $t0, -227 # check for right key press
beq $v0, $zero, rkey
addi $v0, $t0, -224 # check for up key press
beq $v0, $zero, upkey
addi $v0, $t0, -225 # check for down key press
beq $v0, $zero, downkey
addi $v0, $t0, -66 # check for b key press
beq $v0, $zero, bkey

continue:
beq $t7, 0, keypress #if number of b presses is 0 loop back to keypress until b is pressed
bgt $t7, 1, downkey #if number of b presses is greater than 1, end the game
li $v0, 30 #get current time
syscall
sub $a2, $a0, $s4 #get difference
blt $a2, 200, continue #if < 100 milliseconds have passed, loop again
move $s4, $a0 #oldtime #if >= 100, store $a0 to oldtime and continue into loop
li $v0, 30 #get current time
syscall
sub $a2, $a0, $s5
bgt $a2, 120000, downkey #branching to downkey will print the score and end the program if play time > 2 mins
li $a1, 11  # $a1 = upper bound.
li $v0, 42  #generates the random numbe between 1 and 20
syscall
bne $a0, 3, fourspawn #if random number = 3, spawn 3 bugs
jal spawnbug
jal spawnbug 
jal spawnbug
fourspawn:
bne $a0, 4, nospawn #if random number = 4, spawn 3 bugs, else spawn no bugs this loop
jal spawnbug
jal spawnbug 
jal spawnbug
nospawn:

lb $t5, subtracter
add $s1, $s1, $t5 #get correct number of events by subtracting 'subtracter' from event count
addi $t5, $0, 0
sb $t5, subtracter #reset subtracter to 0
beq $s1, 0, mainloop # if no events in queue jump back to the main loop
addi $t4, $0, 0
forloop:
addi $t4, $t4, 1
bgt $t4, $s1, forloopend #if loop counter = eventcounter exit the for loop
addi $t1, $s6, -16
lb $a3, 12($t1) #load identifier to $a3
beq $a3, 1, movered #if 1, move blast
beq $a3, 4, moveboom #if 4, move explosion
beq $a3, 0, next # if 0 (has been removed) go to next
sb $a3, 12($t1)
jal movebug #else, move bug
j next
movered:
jal moveblast
j next
moveboom:
jal moveexplosion
next:
jal incrementfront
j forloop
forloopend:
j mainloop

lkey:
add $a0, $0, $s0 #set x value
addi $a1, $0, 63 #set y value to 63
addi $a2, $0, 0 #set color to no color
jal _setLED #remove led from current spot
addi $s0, $s0, -1 #subtract 1 from x value
addi $a0, $a0, -1 #subtract 1 from x argument
bltz $a0, wrap
j dontwrap
wrap: #bug buster jumps to other side of screen
addi $s0, $0, 63
addi $a0, $0, 63
dontwrap:
addi $a2, $zero, 2 #make sure color is yellow
jal _setLED #set new led position
j continue

rkey:
add $a0, $0, $s0
addi $a1, $0, 63 #set y value to 63
addi $a2, $0, 0 #set color to no color
jal _setLED
addi $s0, $s0, 1 #add 1 to x value
addi $a0, $a0, 1 #add 1 to x argument
bgt $a0, 63, wrapr
j dontwrapr
wrapr: #bug buster jumps to other side of screen
addi $s0, $0, 0
addi $a0, $0, 0
dontwrapr:
addi $a2, $zero, 2 #make sure color is yellow
jal _setLED #set new led position
j continue

upkey:
jal spawnblast #fire a phaser and add it to the queue
j continue

bkey:
addi $t7, $t7, 1 #$t7 is is the b-press counter
j continue

downkey:
la $a0, newline
li $v0, 4
syscall
la $a0, score
li $v0, 4
syscall
move $a0, $s3
li $v0, 1
syscall
la $a0, semicolon
li $v0, 4
syscall
move $a0, $s2
li $v0, 1
syscall #these syscalls print the score
la $a0, newline
li $v0, 4
syscall
li $v0, 10
syscall #the program ends

spawnbug:
addi $s1, $s1, 1 #increment event counter
addi $sp, $sp, -4
sw $ra, 0($sp)
li $a1, 63  # $a1 = upper bound.
li $v0, 42  #generates the random number.
syscall
add $a1, $zero, $zero #set ypos to 0
addi $a2, $zero, 3 #set color to green
jal _setLED
jal incrementend
sb $a0, 0($s7)
sb $a1, 4($s7)
sb $a2, 8($s7) #store the data at the end of the queue
addi $a3, $0, 3 #3 is bug identifier
sb $a3, 12($s7)
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

spawnblast:
addi $s1, $s1, 1 #increment event counter
addi $s2, $s2, 1 #blasts fired counter
addi $sp, $sp, -4
sw $ra, 0($sp)
addi $a0, $s0, 0 #set xpos to current blaster xpos
addi $a1, $zero, 62 #set ypos to 62
addi $a2, $zero, 1 #set color to red
jal incrementend
jal _setLED
sb $a0, 0($s7)
sb $a1, 4($s7)
sb $a2, 8($s7) #store the data at the end of the queue
addi $a3, $0, 1 #1 is blast identifier
sb $a3, 12($s7)
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

spawnexplosion:
addi $s1, $s1, 1 #increment event counter
addi $s3, $s3, 1 #bugs hit counter
jal turnoff
jal incrementend
addi $a3, $0, 1 #initial radius
addi $a2, $0, 1 #initial color
addi $a0, $a0, 1
jal _setLED #led to right
addi $a0, $a0, -2
jal _setLED #led to left
addi $a0, $a0, 1 #reset x value
addi $a1, $a1, 1
jal _setLED #led below
addi $a1, $a1, -2
jal _setLED #led above
addi $a1, $a1, 2
addi  $a0, $a0, -1
jal _setLED #led top left
addi  $a0, $a0, 2
jal _setLED #led top right
addi $a1, $a1, -2
jal _setLED #bottom right
addi $a0, $a0, -2
jal _setLED #bottom left
addi $a0, $a0, 1 #reset x
addi $a1, $a1, 1 #reset y
addi $a3, $0, 4 #set explosion ID
sb $a0, 0($s7) #x coordinate
sb $a1, 4($s7) #y coordinate
sb $a2, 8($s7) #radius
sb $a3, 12($s7) #explosion ID
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

turnoff: #turns an led off after bust, so that the bug/phaser can self-check and remove itself if it is turend off
addi $sp, $sp, -4
sw $ra, 0($sp)
addi $a2, $0, 0
addi $a2, $0, 0
jal _setLED
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

remove:
lb $t5, subtracter
addi $t5, $t5, -1
sb $t5, subtracter #decrement subtracter
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

full: #prints error message if the queue buffer overflows
la $a0, error
li $v0, 4
syscall
li $v0, 10
syscall

removeexplosion:
addi $t1, $s6, -16
lb $a0, 0($t1)
lb $a1, 4($t1)
lb $t5, subtracter
addi $t5, $t5, -1
sb $t5, subtracter
addi $a2, $0, 0 #color to blank
#turn off leds
add $a0, $a0, $a3
jal _setLED #led to right
sub $a0, $a0, $a3
sub $a0, $a0, $a3
jal _setLED #led to left
add $a0, $a0, $a3 #reset x value
add $a1, $a1, $a3
jal _setLED #led above
sub $a1, $a1, $a3
sub $a1, $a1, $a3
jal _setLED #led below
add $a1, $a1, $a3
add $a1, $a1, $a3
sub $a0, $a0, $a3
jal _setLED #led top left
add $a0, $a0, $a3
add $a0, $a0, $a3
jal _setLED #led top right
sub $a1, $a1, $a3
sub $a1, $a1, $a3
jal _setLED #bottom right
sub $a0, $a0, $a3
sub $a0, $a0, $a3
jal _setLED #bottom left
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

movebug:
addi $sp, $sp, -4
sw $ra, 0($sp)
addi $t1, $s6, -16
lb $a0, 0($t1)
lb $a1, 4($t1)
jal _getLED
beq $v0, 0, remove
addi $a2, $0, 0
jal _setLED #turn current LED off
addi $t1, $s6, -16
lb $a2, 8($t1)
addi $a1, $a1, 1
bgt $a1, 62, remove
jal _getLED
beq $v0, 1, spawnexplosion #check to see if a phaser is in the new coordinates, if so spawn burst
jal _setLED #set new LED
addi $a3, $0, 3
jal incrementend
sb $a0, 0($s7) #store coordinates back to queue at end
sb $a1, 4($s7)
sb $a2, 8($s7)
sb $a3, 12($s7)
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

moveblast:
addi $sp, $sp, -4
sw $ra, 0($sp)
addi $t1, $s6, -16
lb $a0, 0($t1)
lb $a1, 4($t1)
jal _getLED
beq $v0, 0, remove
addi $a2, $0, 0
jal _setLED #turn current LED off
addi $t1, $s6, -16
lb $a2, 8($t1)
addi $a1, $a1, -1
beq $a1, 0, remove
jal _getLED
beq $v0, 3, spawnexplosion #check to see if a phaser is in the new coordinates, if so spawn burst
jal _setLED #set new LED
addi $a3, $0, 1
jal incrementend
sb $a0, 0($s7) #store coordinates back to queue at end
sb $a1, 4($s7)
sb $a2, 8($s7)
sb $a3, 12($s7)
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra


moveexplosion:
addi $sp, $sp, -4
sw $ra, 0($sp)
addi $t1, $s6, -16
lb $a0, 0($t1)
lb $a1, 4($t1)
lb $a2, 8($t1) #radius in $a2
add $a3, $0, $a2 #move radius to $a3
addi $a2, $0, 0 #color to blank
#turn off leds
add $a0, $a0, $a3
jal _setLED #led to right
sub $a0, $a0, $a3
sub $a0, $a0, $a3
jal _setLED #led to left
add $a0, $a0, $a3 #reset x value
add $a1, $a1, $a3
jal _setLED #led above
sub $a1, $a1, $a3
sub $a1, $a1, $a3
jal _setLED #led below
add $a1, $a1, $a3
add $a1, $a1, $a3
sub $a0, $a0, $a3
jal _setLED #led top left
add $a0, $a0, $a3
add $a0, $a0, $a3
jal _setLED #led top right
sub $a1, $a1, $a3
sub $a1, $a1, $a3
jal _setLED #bottom right
sub $a0, $a0, $a3
sub $a0, $a0, $a3
jal _setLED #bottom left
add $a0, $a0, $a3
add $a1, $a1, $a3
addi $a2, $0, 1 #color to red
addi $a3, $a3, 1 #increment radius
bgt $a3, 10, remove #if explosion radius is greater than ten, remove it
add $a0, $a0, $a3
beq $a0, 0, removeexplosion #remove burst if it hits an edge of the screen
beq $a0, 63, removeexplosion
beq $a1, 0, removeexplosion
beq $a1, 62, removeexplosion
jal _getLED
beq $v0, 3, spawnexplosion
jal _setLED #led to right
sub $a0, $a0, $a3
sub $a0, $a0, $a3
beq $a0, 0, removeexplosion
beq $a0, 63, removeexplosion
beq $a1, 0, removeexplosion
beq $a1, 62, removeexplosion
jal _getLED
beq $v0, 3, spawnexplosion
jal _setLED #led to left
add $a0, $a0, $a3 #reset x value
add $a1, $a1, $a3
beq $a0, 0, removeexplosion
beq $a0, 63, removeexplosion
beq $a1, 0, removeexplosion
beq $a1, 62, removeexplosion
jal _getLED
beq $v0, 3, spawnexplosion
jal _setLED #led above
sub $a1, $a1, $a3
sub $a1, $a1, $a3
beq $a0, 0, removeexplosion
beq $a0, 63, removeexplosion
beq $a1, 0, removeexplosion
beq $a1, 62, removeexplosion
jal _getLED
beq $v0, 3, spawnexplosion
jal _setLED #led below
add $a1, $a1, $a3
add $a1, $a1, $a3
sub $a0, $a0, $a3
beq $a0, 0, removeexplosion
beq $a0, 63, removeexplosion
beq $a1, 0, removeexplosion
beq $a1, 62, removeexplosion
jal _getLED
beq $v0, 3, spawnexplosion
jal _setLED #led top left
add $a0, $a0, $a3
add $a0, $a0, $a3
beq $a0, 0, removeexplosion
beq $a0, 63, removeexplosion
beq $a1, 0, removeexplosion
beq $a1, 62, removeexplosion
jal _getLED
beq $v0, 3, spawnexplosion
jal _setLED #led top right
sub $a1, $a1, $a3
sub $a1, $a1, $a3
beq $a0, 0, removeexplosion
beq $a0, 63, removeexplosion
beq $a1, 0, removeexplosion
beq $a1, 62, removeexplosion
jal _getLED
beq $v0, 3, spawnexplosion
jal _setLED #bottom right
sub $a0, $a0, $a3
sub $a0, $a0, $a3
beq $a0, 0, removeexplosion
beq $a0, 63, removeexplosion
beq $a1, 0, removeexplosion
beq $a1, 62, removeexplosion
jal _getLED
beq $v0, 3, spawnexplosion
jal _setLED #bottom left
add $a0, $a0, $a3
add $a1, $a1, $a3
jal incrementend
sb $a0, 0($s7)
sb $a1, 4($s7)
add $a2, $0, $a3 #put radius in $a2
addi $a3, $0, 4 #put explosion code back in $a3
sb $a2, 8($s7) #load radius
sb $a3, 12($s7) #load explosion code
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra

incrementfront: #increments the start pointer, and 'wraps' it back to zero if it reaches capacity
addi $s6, $s6, -16
blt $s6, -1024, wrapfront
j nowrapfront
wrapfront:
addi $s6, $0, 0
nowrapfront:
jr $ra

incrementend: #increments the end pointer, and 'wraps' it back to zero if it reaches capacity
addi $s7, $s7, -16
blt $s7, -1024, wrapend
j nowrapend
wrapend:
addi $s7, $0, -16
nowrapend:
beq $s6, $s7, full
jr $ra

# void _setLED(int x, int y, int color)
	#   sets the LED at (x,y) to color
	#   color: 0=off, 1=red, 2=yellow, 3=green
	#
	# arguments: $a0 is x, $a1 is y, $a2 is color
	# trashes:   $t0-$t3
	# returns:   none
	#
_setLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll	$t0,$a1,4      # y * 16 bytes
	srl	$t1,$a0,2      # x / 4
	add	$t0,$t0,$t1    # byte offset into display
	li	$t2,0xffff0008 # base address of LED display
	add	$t0,$t2,$t0    # address of byte with the LED
	# now, compute led position in the byte and the mask for it
	andi	$t1,$a0,0x3    # remainder is led position in byte
	neg	$t1,$t1        # negate position for subtraction
	addi	$t1,$t1,3      # bit positions in reverse order
	sll	$t1,$t1,1      # led is 2 bits
	# compute two masks: one to clear field, one to set new color
	li	$t2,3		
	sllv	$t2,$t2,$t1
	not	$t2,$t2        # bit mask for clearing current color
	sllv	$t1,$a2,$t1    # bit mask for setting color
	# get current LED value, set the new field, store it back to LED
	lbu	$t3,0($t0)     # read current LED value	
	and	$t3,$t3,$t2    # clear the field for the color
	or	$t3,$t3,$t1    # set color field
	sb	$t3,0($t0)     # update display
	jr	$ra
	
	# int _getLED(int x, int y)
	#   returns the value of the LED at position (x,y)
	#
	#  arguments: $a0 holds x, $a1 holds y
	#  trashes:   $t0-$t2
	#  returns:   $v0 holds the value of the LED (0, 1, 2 or 3)
	#
_getLED:
	# byte offset into display = y * 16 bytes + (x / 4)
	sll  $t0,$a1,4      # y * 16 bytes
	srl  $t1,$a0,2      # x / 4
	add  $t0,$t0,$t1    # byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    # address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    # remainder is bit position in byte
	neg  $t1,$t1        # negate position for subtraction
	addi $t1,$t1,3      # bit positions in reverse order
    	sll  $t1,$t1,1      # led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    # shift LED value to lsb position
	andi $v0,$t2,0x3    # mask off any remaining upper bits
	jr   $ra
