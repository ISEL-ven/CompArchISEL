; Rotina:    umull32 ----------------------------------------------------------
; Descricao:
; Entradas:  M = R0..R1, m = R2..R3
; Saidas: 	p = R0..R1
; Efeitos:

umull32:
	; save used registers in stack ------------------------
	;push	LR
	push  	R4							; constant values for comparisson
	push  	R5							; i
	push    R6							; M (LSB)
	push  	R7  							; M (MSB)
	push  	R8							; p_1
	push  	R9  							; (p & 0x1) first bit of p (FBP)

	; tranfer M (32b) to R7..R6 ---------------------------------
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

for_loop_mull:							;( p & 0x1 ) == 0 && p_1 == 1 )
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
	;pop		PC

	b .
