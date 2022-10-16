; Rotina:    umull32 ----------------------------------------------------------
; Descricao:
; Entradas:  M = R0..R1, m = R2..R3
; Saidas: 	 p = R0..R1
; Efeitos:

umull32:
	; save used registers in stack ------------------------
	;push	LR
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

	; don't enter if parts in case p MSBs != 0, p must be 0 or 1 to enter ifs
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
	and  	R5, R4, R1 						; R4 (LSB of p) & (R1 = 0x0001)
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
	cmp 	R5, R1   						; R5 = (p & 0x1), R1 = 0x01
 	bne 	end_if
	cmp  	R4, R0							; R4 = p_1, R0 = 0x0000
	bne		end_if

	; sub M to p (32 MSB) ---------------------------------
	sub 	R11, R6, R11					; R11 = p (MSB_0), R6 = M (LSB)
	sbc  	R12, R7, R12					; R12 = p (MSB_1), R7 = M (MSB)

end_if:
	; p_1 = p & 0x1 ---------------------------------------
	mov  	R4, R9							; R9 = p (LSB_0) 
	and  	R5, R4, R1 						; R4 (LSB of p) & (R1 = 0x0001)
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
	;pop		PC

	b .
