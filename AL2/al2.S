	.text
	ldr 	R0, var2_addr
loop:
	ldrb	R1, [R0, #0]
	add 	R1, R1, #1
	strb 	R1, [R0, #0]
	b  		loop

var2_addr:
	.word var2

	.data
var1:
	.byte 0xAC
var2:
	.byte 126
var3:
	.word 0x2022

