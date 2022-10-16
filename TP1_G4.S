; File:  TP1_G4.S
; Description: Support program of the first pratical assignment of Computer Architecture

; Author:	47190 Teresa Gaspar
;		45837 Miguel Queluz
;		45824 Nuno Venâncio
		
; Date:      16-10-2022

; Definition of the values and symbols used along the program =================== 

.equ	STACK_SIZE, 64			; Stack dimension - 64B (16b x 10), we push 9 registers in umull32
.equ	N, 20					; N=10 but needs to be 20 because i increments by 2 (due to memory address rules)

; Srand val :  5423 = 0x152F (one register (32))
.equ	SRAND_VAL_L0, 0x2F			; LSB0 of srand val
.equ	SRAND_VAL_L1, 0x15			; LSB1 of srand val

; Rand Max : 0xFFFFFFFF (2^32-1) (max value for 32bits)
.equ 	RAND_MAX, 0xFF		;=0xFF (is 1/4 of rand max value)

; Seed multiplier 214013 = 0x343FD
.equ 	SEED_M_L0,0xFD
.equ 	SEED_M_L1,0x43
.equ 	SEED_M_H0,0x03

; Seed summand 2531011 = 0x269EC3
.equ	SEED_S_L0, 0xC3
.equ	SEED_S_L1, 0x9E
.equ	SEED_S_H0, 0x26
; =============================================================================


; Section:    .startup ========================================================
; Description: Saves the system startup code

	.section .startup
	b		_start

_start:
	ldr	SP, tos_addr		; set SP (stack pointer) to begining of stack addr
	ldr	PC, main_addr		; set PC (prog counter) to begining of main addr

tos_addr:
	.word	tos

main_addr:
	.word	main

; =============================================================================

; Section:    .text ===========================================================
; Descricao: Guarda o código do programa

	.section .text

; Routine:		main 
; Description:	main function
; Entradas:		none
; Outputs:		zero
main:
	mov  	R3, #0				; i (lsb)
	movt	R3, #0				; i (msb)

	; get srand parameter to [R1..R0], 5423 = 0x152F
	mov  	R0, #SRAND_VAL_L0
	movt	R0, #SRAND_VAL_L1
	mov  	R1, #0
	movt  	R1, #0
	bl  	srand 				; call to srand, nseed is in R0..R1

for_loop:					;(i = 0; error == 0 && i < N; i++)
	; check if i < N
	mov  	R0, #N
	cmp  	R3, R0				; i - N 
	bhs     end_loop			; if (i >= N) breaks loop

	; rand_number = rand(), return will be in mem val of seed
	bl 	rand				; R0 holds the value of seed>>16
	ldr 	R2, rand_number_addr 	; get rand_number mem addr
	str  	R0, [R2, #0] 			; store the value in R0 in rand_number

	; don't need the error variable, we can break directly in the for_loop
	; if rand_number == result[i] -> branch for_loop
	ldr  	R0, result_addr
	ldr 	R0, [R0, R3]			; R0 = result[i]
	ldr 	R2, [R2, #0]			; R2 holds the value of rand_number
	add	R3,R3,#2			; i = i+2
	cmp 	R0, R2
	beq  	for_loop			; if R0 == R2 continues loop
	
end_loop:
	mov	R0,#0				;returns zero

rand_number_addr:
	.word rand_number

result_addr:
	.word result


; Routine:		srand 
; Description:	store nseed in seed (in memory)
; Entries:		nseed in [R1..R0]
; Outputs:		none

srand:

	; R0 - LSbits of nseed, R1 - MSbits of nseed 
	push	LR
	ldr	R2, seed_addr			; get seed mem addr
	str	R0, [R2, #0]			; get the value in seed mem addr (LSbits)			
	str	R1, [R2, #2]			; get the value in seed mem addr (MSbits)
	pop	PC


; Routine:    	rand 
; Description:	Linear Congruential Generator - LCG
; Entries:		none
; Outputs:		R0 = seed >> 16

rand:
	push	LR
	push	R3

	; loads value of seed to [R1..R0]			(m in umull)
	ldr	R0, seed_addr 		; get seed mem addr
	ldr	R1, [R0, #2]            	; get the value in seed mem addr (MSbits)	(in order to reuse the address in R0 we changed the order)		
	ldr	R0, [R0, #0]			; get the value in seed mem addr (LSbits)

	; move seed multiplier (32bits) to [R3..R2]	(M in umull)
	mov	R2, #SEED_M_L0
	movt	R2, #SEED_M_L1
	mov 	R3, #SEED_M_H0
	movt	R3, #0

	bl	umull32			; return will come in [R1..R0]

	; move seed summand (32bits) to [R3..R2]
	mov	R2, #SEED_S_L0
	movt	R2, #SEED_S_L1
	mov 	R3, #SEED_S_H0
	movt	R3, #0

	; sum seed summand (32bits) to umull32 result (32bits)
	add 	R0, R0, R2
	adc	R1, R1, R3
	
	; x = umull32 ( seed , 214013 ) + 2531011)
	; x % RAND_MAX  is always gonna be equal to x as long as x < RAND_MAX if X=RAND_MAX, x % RAND_MAX = 0, x can never be > RAND_MAX
	mov	R2,#RAND_MAX
	movt	R2,#RAND_MAX
	cmp	R0,R2							;r0-r2 => <=0 
	bne	jump	
	cmp	R1,R2
	bne	jump
	mov	R0,#0
	movt	R0,#0
	mov	R1,#0
	movt	R1,#0
jump:
	bl	srand							;saves in seed the value in [R1..R0]
	mov	R0,R1							; seed >> 16
	pop	R3
	pop	PC

seed_addr:
	.word seed


; Routine:		umull32
; Description: 	Multiplication shift and add algorithm (M(32b) x m(32b))
; Entries:  		M = [R1..R0], m = [R3..R2]
; Outputs: 		p = [R1..R0]

umull32:
	; save used registers in stack ------------------------
	push	LR
	push  	R4							; constant values for comparisson
	push  	R5							; i
	push    R6							; M (LSB)
	push  	R7  							; M (MSB)
	push  	R8							; p_1
	push  	R9  							; (p & 0x1) first bit of p (FBP)

	; tranfer M (32b) to [R7..R6] ---------------------------------
	mov 	R6, R0 							; R0 = M (LSB)
	mov  	R7, R1							; R1 = M (MSB) 

	; assign p = m (64b) [R3..R0]----------------------------------
	mov	R0, R2
	mov	R1, R3
	mov	R2, #0
	movt	R2, #0
	mov	R3, #0
	movt	R3, #0
	
	; assign p_1 = 0 --------------------------------------
	mov  	R8, #0							;p_1 uint8 (only LSB)

	; assign i = 0 ----------------------------------------
	mov  	R5, #0							;0 <= i < 32

	; for loop ============================================

for_loop_mull:							;(p & 0x1) == 0 && p_1 == 1 )
	; if (i >= 32) break loop -----------------------------
	mov  	R4, #32
	cmp 	R5, R4							; R5 = i, R4 = 32 (i - 32)
	bhs 	end_loop_mull	

if_loop:								; if ((p & 0x1) == 0 && p_1 == 1)
	mov	R4, #1
	and	R9, R4, R0						; R9 = FBP = (p & 0x1)
	mov	R4, #0
	cmp  	R4, R9							; FBP == 0 ?
	bne 	if_else						; if FBP != 0 jumps to else_if	
	mov	R4, #1
	cmp   	R4, R8							; p_1 == 1 ?
	bne	end_if							; if p_1 != 1 jumps to end_if

	; sum M to p (32 MSB) --------------------------------- p += M << 32
	add 	R2, R2, R6						; R2 = p (MSB_0), R6 = M (LSB)
	adc     R3, R3, R7						; R3 = p (MSB_1), R7 = M (MSB)
	
if_else:								; if ((p & 0x1) == 1 && p_1 = 0) 
	mov	R4, #0
	cmp  	R4, R8							; p_1 == 0 ?
	bne	end_if							; if p_1 != 0 jumps to end_if	

	; sub M to p (32 MSB) ---------------------------------
	sub 	R2, R2, R6						; R2 = p (MSB_0), R6 = M (LSB)
	sbc  	R3, R3, R7						; R3 = p (MSB_1), R7 = M (MSB)

end_if:
	; p_1 = p & 0x1 ---------------------------------------
	mov 	R8, R9							; p_1(R8) = FBP (R9)
	
	; p >> 1 -----------------------------------------------
	lsr  	R3, R3, #1
	rrx  	R2, R2
	rrx  	R1, R1
	rrx  	R0, R0
	
	; i++ --------------------------------------------------
	add	R5,R5,#1						
	b	for_loop_mull

end_loop_mull:
	pop  	R9 
	pop 	R8
	pop  	R7
	pop  	R6
	pop  	R5
	pop  	R4
	pop	PC

; =============================================================================

; Section:    .data ============================================================
; Description: Stores global variables with initial value pre-defined
	.section .data

seed:
	.word 0x0001

result:
	.word 17747, 2055, 3664, 15611, 9819, 18005, 7515, 4525, 17337, 30985
; =============================================================================

; Section:    .bss ============================================================
; Description: Stores global variables without initial value pre-defined
	.section .bss

rand_number:
	.word rand_number
; =============================================================================

; Section:    .stack ===========================================================
; Description: Implements Stack with pre defined size (STACK_SIZE)

	.section .stack
	.space	STACK_SIZE
tos:	


/* 
================================================Respostas às perguntas do enunciado=================================================
	
1. Considere a definição da função umull32 que realiza a multiplicação de dois números naturais codificados 
com 32 bits, em que o parâmetro M corresponde ao multiplicando e o parâmetro m ao multiplicador.
	a) Implemente a função umull32 
		R: A função encontra-se implementada nas linhas 176 a 256.
		
	b) Indique, em número de bytes, a quantidade de memória de código ocupada por essa implementação. Justifique a sua resposta.
		R: 0x00DE - 0x007E = 0x60 (em decimal 96), a memória ocupada por esta implementação é de 24Bytes uma vez que
		esta é calculada pelo número de linhas de código usadas para a execução desta função multiplicado pelo valor 
		dois (cada instrução recorre a dois bites de memória) seguida pela divisão por 8 de modo a convertermos 
		o valor em bytes (1 byte = 8 bits) (96*2/8).
	
2. Considere a definição da função srand que afeta a variável global seed com o valor de uma nova semente.
	a) Implemente a definição da variável seed, definindo as secções necessárias. Justifique a sua resposta.
		R: A variável seed é definida (linha 264) na secção .data uma vez que é lá que são guardadas as variáveis 
		com valor inicial, sendo .word 0x0001.
		
	b) Implemente a função srand.
		R: A função encontra-se implementada entre as linhas 107 a 114.
	
3. Considere a definição da função rand que implementa um gerador congruencial linear (Linear Congruential Generator - LCG) 
para gerar números pseudo-aleatórios entre zero e RAND_MAX. A constante RAND_MAX corresponde ao maior valor possível de 
codificar numa variável com tipo uint32_t.
	a) Indique duas possibilidades de implementação da constante RAND_MAX e discuta as suas vantagens e desvantagens 
	quanto aos requisitos de memória.
		R:?
		
	b) Implemente a função rand.
		R: Esta implementação encontra-se descrita entre as linhas 122 a 168.

4. Considere a definição da função main
	a) Indique, justificando, que registo é preferível utilizar para implementar a variável error: R0 ou R5?
		R: Entre os registos R0 e R5, será preferível usar o R5 uma vez que o R0 é usado para passar argumentos em rotinas
		e retornar os valores das mesmas.
	b) Implemente a função main e a definição da variável result.
		R: A função main encontra-se descrita entre as linhas 61 a 93; A variável result é definida na secção .data, pois os 
		valores já são previamente definidos, no contexto do trabalho esta variável consiste num array de valores .word
		
====================================================================================================================================
*/