; Ficheiro:  .S
; Descricao: Programa de suporte a realizacao do 1o trabalho prático de
;            Arquitetura de Computadores.

; Autor:     47190 Ana Gaspar
;    		 45837 Miguel Santos
;	    	 45824 Nuno Venâncio
;	   			
; Data:      05-10-2022


; Definicao dos valores dos simbolos utilizados no programa ===================

.equ	STACK_SIZE, 64				; Dimensao do stack - 64B (16b x 10), we push 9 registers in umull32
.equ	N, 10
.equ	SRAND_VAL_L, 0x2F  			; 5434 = 0x152F
.equ	SRAND_VAL_H, 0x15
.equ 	RAND_MAX, 0xFFFF
.equ 	SEED_MULTIPLIER, 214013
.equ	SEED_SUMMAND, 2531011
.equ	SEED, 1
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

	.section .text

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
	mov  	R0, SRAND_VAL_L & 0xFF
	movt  	R0, #( SRAND_VAL_L >> 8 ) & 0xFF
	mov  	R1, SRAND_VAL_H & 0xFF
	movt  	R1, #( SRAND_VAL_H >> 8 ) & 0xFF

	bl  	srand 					; call to srand, nseed is in R0..R1

for_loop:
	; check if i < N
	mov  	R0, N & 0xFF
	movt	R0, (0 >> 8) & 0xFF
	cmp  	R0, R5
	bhs     end_loop

	; rand_number = rand(), return will be in mem val of seed
	bl 		rand
	mov  	R0, #seed_addr
	ldr  	R0, [R0, #0]
	str  	R0, [R4, #0]			; maybe wrong

	; if rand_number == result[i] -> brach for_loop, rand_number is in R4
	ldr  	R0, result_addr
	ldr 	R0, [R0, R5]
	cmp 	R0, R4
	beq  	for_loop

end_loop:

	; restore used registers from stack
	pop		R5
	pop		R4

rand_number_addr:
	.word rand_number

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

	ldr		R2, seed_addr			; get seed mem addr
	str		R0, [R2, #0]			; get the value in seed mem addr (LSbits)
	str		R1, [R2, #2]			; get the value in seed mem addr (MSbits)
	
	pop		PC


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
	push 	R6

	ldr		R0, seed_addr 			; get seed mem addr
	ldr		R0, [R0, #0]            ; get the value in seed mem addr (LSbits)
	ldr		R1, [R0, #2]			; get the value in seed mem addr (MSbits)

	; move seed multiplier (32bits) to R2..R3
	mov		R2, #SEED_MULTIPLIER & 0xFF
	movt	R2, #( SEED_MULTIPLIER >> 8 ) & 0xFF
	mov 	R3, #( SEED_MULTIPLIER >> 16 ) & 0xFF
	movt	R3, #( SEED_MULTIPLIER >> 24 ) & 0xFF

	bl		umull32					; return will come in R0..R3

	; move SEED_SOMMAND (32bits) to R4..R5
	mov		R4, #(SEED_SUMMAND & 0xFF)
	movt	R4, #(( SEED_SUMMAND >> 8 ) & 0xFF)
	mov 	R5, #(( SEED_SUMMAND >> 16 ) & 0xFF)
	movt	R5, #(( SEED_SUMMAND >> 24 ) & 0xFF)

	; sum SEED_SOMMAND (32bits) to umull32 resul (64bits)
	mov 	R6, #0x00 		; adc doesnt support #0
	movt  	R6, #0x00
	add 	R0, R0, R4
	adc		R1, R1, R5
	adc 	R2, R2, R6
	adc		R3, R3, R6

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
	pop		R6
	pop		R5
	pop		R4
	pop		PC

seed_addr:
	.word seed


; Rotina:    umull32 ----------------------------------------------------------
; Descricao:
; Entradas:  M = R0..R1, m = R2..R3
; Saidas: 	 p = R0..R1
; Efeitos:

umull32:
	; save used registers in stack ------------------------
	push	LR
	push  	R4							; 0x0000 in the op p >> 1 to adc to the next part of the number
	push  	R5							; i
	push    R6							; M (LSB)
	push  	R7  						; M (MSB)
	push  	R9   						; p (LSB_0)
	push  	R8							; p_1
	push    R10							; p (LSB_1)
	push    R11							; p (MSB_0)
	push  	R12							; p (MSB_1)

	; tranfer M to R7..R6 ---------------------------------
	mov 	R6, R0 						; R0 = M (LSB)
	mov  	R7, R1						; R1 = M (MSB) 

	; assign p = m (64b) ----------------------------------
	mov   	R9, R2 						; R2 = m (LSB)
	mov  	R10, R3						; R3 = m (MSB)
	mov   	R11, #0x00 & 0xFF			; fill the remaining MSB of 32b with 0x0000
	movt   	R11, #(0x00 >> 8) & 0xFF    
	mov   	R12, #0x00 & 0xFF
	movt   	R12, #(0x00 >> 8) & 0xFF

	; assign p_1 = 0 --------------------------------------
	mov  	R8, #0x00 & 0xFF
	movt  	R8, #(0x00 >> 8) & 0xFF

	; assign i = 0 ----------------------------------------
	mov  	R5, #0x00 & 0xFF
	movt  	R5, #(0x00 >> 8) & 0xFF
	

	; for loop ============================================
for_loop_mull:

	; assign R0 with 0x0000 -------------------------------
	mov  	R0, 0x00 & 0xFF
	movt   	R0, #(0x00 >> 8) & 0xFF

	; assign R1 with 0x0001 -------------------------------
	mov  	R1, 0x01 & 0xFF
	movt   	R1, #(0x00 >> 8) & 0xFF

	; assign R2 with 32 (0x0020) ----------------------------
	mov   	R2, #0x20 & 0xFF
	movt 	R2, #(0x00 >> 8) & 0xFF 

	; if (i >= 32) break loop -----------------------------
	cmp 	R5, R2							; R5 = i, R2 = 32 (0x0020)
	bhs 	end_loop_mull	

	; don't enter if parts in case p MSBs != 0 ------------
	mov   	R5, R10							; R10 = p (LSB_1) 
	cmp 	R5, R0							; R0 = 0x0000
	bne 	end_if

	mov     R5, R11							; R11 = p (MSB_0)
	cmp  	R5, R0							; R0 = 0x0000
	bne  	end_if

	mov     R5, R12							; R12 = p (MSB_1)
	cmp  	R5, R0							; R0 = 0x0000
	bne  	end_if

	; if ((p & 0x1) == 0 && p_1 == 1) ---------------------
	mov  	R4, R9							; R9 = p (LSB_0) 
	and  	R5, R4, R1 						; R9 (LSB of p) & (R1 = 0x0001)
	cmp  	R5, R0							; R5 = (p & 0x1), R0 = 0x0000 
	bne 	if_2
	mov  	R4, R8							; R8 = p_1
	cmp   	R4, R1							; R4 = p_1, R1 = 0x0001
	bne		end_if

	; sum M to p (32 MSB) ---------------------------------
	add 	R11, R6, R11					; R11 = p (MSB_0), R6 = M (LSB)
	adc     R12, R7, R12					; R12 = p (MSB_1), R7 = M (MSB)

	; if ((p & 0x1) == 1 && p_1 = 0) ----------------------
if_2:
	cmp 	R5, R1   						; R5 = (p & 0x1), R4 = 0x01
 	bne 	end_if
	cmp  	R4, R0							; R4 = p_1, R0 = 0x0000
	bne		end_if

	; sub M to p (32 MSB) ---------------------------------
	sub 	R11, R6, R11					; R11 = p (MSB_0), R6 = M (LSB)
	sbc  	R12, R7, R12					; R12 = p (MSB_1), R7 = M (MSB)

end_if:
	; p_1 = p & 0x1 ---------------------------------------
	mov 	R8, R5							; R8 = p_1, R5 = p & 0x0001
	
	; p >>= 1, need to move p to R3..R0 so we can do the shift
	mov     R0, R9							; R9 = p (LSB_0)			
	mov     R1, R10							; R10 = p (LSB_1)
	mov     R2, R11 						; R11 = p (MSB_0)
	mov     R3, R12							; R12 = p (MSB_1)

	mov 	R4, #0x00 & 0xFF                ; R4 = 0x0000 to use in adc
	movt 	R4, #(0x00 >> 8) & 0xFF     
	
	; make the shift right by 1 ---------------------------
	lsr  	R3, R3, #1
	adc 	R2, R2, R4
	lsr  	R2, R2, #1
	adc     R1, R1, R4
	lsr  	R1, R1, #1
	adc  	R0, R0, R4
	lsr  	R0, R0, #1

	; move back p to R12..R9 -----------------------------
	mov     R9, R0							; R0 = p (LSB_0)		
	mov     R10, R1							; R1 = p (LSB_1)
	mov     R11, R2 						; R2 = p (MSB_0)
	mov     R12, R3 						; R3 = p (MSB_1)

	b  		for_loop_mull

end_loop_mull:
	; move p (LSB) to R1..R0, only need the 32b part of p -
	mov     R0, R9 							; R9 = p (LSB_0)			
	mov     R1, R10 						; R10 = p (LSB_1)

	; restore used registers from stack -------------------
	pop  	R12
	pop  	R11
	pop  	R10
	pop  	R9
	pop 	R8
	pop  	R7
	pop  	R6
	pop  	R5
	pop  	R4
	pop		PC

; =============================================================================


; Seccao:    .data ============================================================
; Descricao: Guarda as variáveis globais com um valor inicial definido
	.section .data

seed:
	.word 0x0001

result:
	.word 17747, 2055, 3664, 15611, 9819, 18005, 7515, 4525, 17337, 30985
; =============================================================================


; Seccao:    .bss =============================================================
; Descricao: Guarda as variáveis globais sem valor inicial definido
	.section .bss

rand_number:
	.word rand_number
; =============================================================================


; Seccao:    .stack ===========================================================
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
	.section .stack
	.space	STACK_SIZE
tos:	
