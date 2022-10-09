; Ficheiro:  .S
; Descricao: Programa de suporte a realizacao do 1o trabalho prático de
;            Arquitetura de Computadores.

; Autor:     47190 Ana Gaspar
;    		 45837 Miguel Santos
;	    	 45824 Nuno Venâncio
;	   			
; Data:      05-10-2022


; Definicao dos valores dos simbolos utilizados no programa ===================

.equ	STACK_SIZE, 160				; Dimensao do stack - 160b (16b x 10), we push 9 registers in umull32
.equ	N, 10
.equ	SRAND_VAL_L, 0x2F  			; 5434 = 0x152F
.equ	SRAND_VAL_H, 0x15
.equ 	RAND_MAX, 0xFFFF
.equ 	SEED_MULTIPLIER, 214013
.equ	SEED_SUMMAND, 2531011
; =============================================================================


; Section:    .startup ========================================================
; Descricao: Guarda o código de arranque do sistema

	.section .startup
	b		_start

_start:
	ldr		SP, tos_addr		; set SP (stack pointer) to begining of stack addr
	ldr		PC, main_addr		; set PC (prog counter) to begining of main addr

tos_addr:
	.word	tos

main_addr:
	.word	main

; =============================================================================

; Section:    .text ===========================================================
; Descricao: Guarda o código do programa

	.text

; Rotina:    main -------------------------------------------------------------
; Descricao:
; Entradas:  none
; Saidas:	 none
; Efeitos:

main:
	; save used registers in stack 
	push 	R4
	push 	R5

	; don't need the error vaiable, we can break directly in the for_loop
	; if rand_number != result[i] 
	;mov 	R4, #0 					; error
	ldr 	R4, rand_number_addr 	; get rand_number mem addr
	ldr 	R4, [R4, #0] 			; get the value in rand_number mem addr
	mov  	R5, #0 & 0xFF 			; i (lsb)
	movt	R5, #( 0 >> 8) & 0xFF 	; i (msb)

	; get srand parameter to R0..R1, 5423 = 0x152F
	mov  	R0, #SRAND_VAL_L & 0xFF
	movt  	R0, #( SRAND_VAL_L >> 8 ) & 0xFF
	mov  	R1, #SRAND_VAL_H & 0xFF
	movt  	R1, #( SRAND_VAL_H >> 8 ) & 0xFF

	bl  	srand 					; call to srand, nseed is in R0..R1

for_loop:
	; check if i < N
	mov  	R0, #N & 0xFF
	movt	R0, (0 >> 8) & 0xFF
	cmp  	R0, R5
	bhs     end_loop

	; rand_number = rand(), return will be in mem val of seed
	bl 		rand
	mov  	R0, #seed_addr
	ldr  	R0, [R0, #0]
	str  	R0, [R4, #0]			; maybe wrong

	; if rand_number == result[i] -> brach for_loop, rand_number is in R4
	ldr  	R0, #result_addr
	ldr 	R0, [R0, R5]
	cmp 	R0, R4
	beq  	for_loop

end_loop:

	; restore used registers from stack
	pop		R5
	pop		R4

rand_number_addr:
	.word rand_number
seed_addr_:
	.word seed
result_addr:
	.word result

; Rotina:    srand ------------------------------------------------------------
; Descricao:
; Entradas:  nseed in R0..R1
; Saidas:	 none
; Efeitos:

srand:
	; think this routine is unecessary could be done directly on main 
	; R0 - LSbits of nseed, R1 - MSbits of nseed 
	push	LR

	ldr		R2, seed_addr 			; get seed mem addr
	str		R0, [R2, #0]			; get the value in seed mem addr (LSbits)
	str		R1, [R2, #2]			; get the value in seed mem addr (MSbits)
	
	pop		PC

seed_addr_:
	.word seed


; Rotina:    rand -------------------------------------------------------------
; Descricao:
; Entradas:  
; Saidas:
; Efeitos:

rand:
	; save used registers in stack 
	push	LR
	push 	R4
	push 	R5

	ldr		R0, seed_addr 			; get seed mem addr
	ldr		R0, [R0, #0]            ; get the value in seed mem addr (LSbits)
	ldr		R1, [R0, #2]			; get the value in seed mem addr (MSbits)

	; move seed multiplier (32bits) to R2..R3
	mov		R2, #SEED_MULTIPLIER & 0xFF
	movt	R2, #( SEED_MULTIPLIER >> 8 ) & 0xFF
	mov 	R3, #( SEED_MULTIPLIER >> 16 ) & 0xFF
	movt	R3, #( SEED_MULTIPLIER >> 32 ) & 0xFF

	bl		umull32					; return will come in R0..R3

	; move SEED_SOMMAND (32bits) to R4..R5
	mov		R4, #SEED_SOMMAND & 0xFF
	movt	R4, #( SEED_SOMMAND >> 8 ) & 0xFF
	mov 	R5, #( SEED_SOMMAND >> 16 ) & 0xFF
	movt	R5, #( SEED_SOMMAND >> 32 ) & 0xFF

	; sum SEED_SOMMAND (32bits) to umull32 resul (64bits)
	add 	R0, R0, R4
	adc		R1, R1, R5
	adc 	R2, R2, #0
	adc		R3, R3, #0

	; calculate modulus with RAND_MAX
	; (number can't pass RAND_MAX, 64bits shrink to 32bits)
	; https://stackoverflow.com/questions/42938673/how-to-do-the-modulo-operation-in-arm-assembly
	; i think we can do nothing and get only the lower part (32bit) of the 64 bits value which is in R0..R1


	; store seed in mem rigth shifted by 16
	; i think rsh 16 is the same to mov the value from R0 to R1 and then mov #0 to R0
	mov 	R1, R0
	mov 	R0, #0 & 0xFF
	movt    R0, #( 0 >> 8) & 0xFF

	; restore used registers from stack
	pop		R5
	pop		R4
	pop		PC

seed_addr_:
	.word seed

; Rotina:    umull32 ----------------------------------------------------------
; Descricao:
; Entradas:  M = R0..R1, m = R2..R3
; Saidas: 	 p = R0..R3
; Efeitos:

umull32:
	; save used registers in stack 
	push	LR
	push  	R4						; M LSB
	push  	R5						; M MSB
	push    R6						; p_1
	push  	R7  					; i
	push  	R8   					; #32
	push    R9						; #0
	push    R10						; #1
	push  	R11						; p & 0x1 in the ifs

	; convert M to 64b, and assign p = m (64b) and p_1 = 0
	; M64 -> R4..R7
	mov  	R4, R0 & 0xFF
	movt  	R4, ( R0 >> 8 ) & 0xFF
	mov 	R5, R1 & 0xFF
	movt  	R5, (R1 >> 8 ) & 0xFF
	; p -> R0..R3
	mov  	R0, #0 & 0xFF
	movt  	R0, #( 0 >> 8 ) & 0xFF
	mov  	R1, #0 & 0xFF
	movt  	R1, #( 0 >> 8 ) & 0xFF
	; p_1 -> R6
	mov  	R6, #0

	; for loop variables preparation
	mov 	R7, #0 & 0xFF 				; i LSB
	movt  	R7, #( 0 >> 8 ) & 0xFF  	; i MSB
	mov  	R8, #0x0 & 0xFF 			; #32 = 0x20 LSB(0)
	movt 	R8, #( 0x2 >> 8 ) & 0xFF 	; #32 = 0x20 MSB(2)
	mov  	R9, #0 & 0xFF 				; #0
	mov 	R10, #1 & 0xFF 				; #1

for_loop_mull:
	; if (i >= 32) break loop
	cmp 	R7, R8
	bhs 	end_loop_mull

	; p & 0x1
	and  	R11, R11, R10 

	; don't enter if parts in case p MSBs != 0
	cmp 	R1, R9
	bne 	end_if
	cmp  	R2, R9
	bne  	end_if
	cmp  	R3, R9
	bne  	end_if

	; if ((p & 0x1) == 0 && p_1 == 1)
	cmp  	R11, R9
	bne 	if_2
	cmp   	R6, R10
	bne		end_if

	; sum M to p (32 MSB)
	add 	R2, R2, R4
	adc     R3, R3, R5

	; if ((p & 0x1) == 1 && p_1 = 0)
if_2:
	cmp 	R11, R10
	bne 	end_if
	cmp  	R6, R9
	bne		end_if

	; sub M to p (32 MSB)
	sub 	R2, R2, R4
	sbc  	R3, R3, R5

end_if:
	; p_1 = p & 0x1
	and  	R0, R0, R10
	mov 	R6, R0
	
	; p >>= 1
	lsr  	R3, R3, #1
	adc 	R2, R2, #0
	lsr  	R2, R2, #1
	adc     R1, R1, #0
	lsr  	R1, R1, #1
	adc  	R0, R0, #0
	lsr  	R0, R0, #1

	b  		for_loop_mull

end_loop_mull:

	; restore used registers from stack
	pop  	R11
	pop  	R10
	pop  	R9
	pop  	R8
	pop  	R7
	pop  	R6
	pop  	R5
	pop  	R4
	pop		PC
; =============================================================================

; Seccao:    .data ============================================================
; Descricao: Guarda as variáveis globais com um valor inicial definido

seed:
	.word 0x0001

result:
	.word 17747, 2055, 3664, 15611, 9819, 18005, 7515, 4525, 17337, 30985
; =============================================================================


; Seccao:    .bss =============================================================
; Descricao: Guarda as variáveis globais sem valor inicial definido

rand_number:
	.word
; =============================================================================


; Seccao:    .stack ===========================================================
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
	.section .stack
	.space	STACK_SIZE
tos:	
