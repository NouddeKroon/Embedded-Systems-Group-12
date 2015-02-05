@DATA
	leds_timers DS 8
	button_prev_state DS 8
	
@CODE
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
    
    ; ARRAYS

	TIMER_INTR_ADDR  EQU  16
    TIMER_DELTA  EQU  10

   main :
			LOAD R0  timer_interrupt
			ADD  R0  R5
			LOAD R1  TIMER_INTR_ADDR
			STOR R0  [R1]
			LOAD R5  IOAREA
			LOAD R0  0	
			SUB  R0  [R5+TIMER]
			STOR R0  [R5+TIMER]
			SETI 8
			
	update_buttons_loop:
			LOAD R0 1
			BTS  update_button
			LOAD R0 2
			BTS  update_button
			LOAD R0 3
			BTS  update_button
			LOAD R0 4
			BTS  update_button
			LOAD R0 5
			BTS  update_button
			LOAD R0 6
			BTS  update_button
			LOAD R0 7
			BTS  update_button
			
	;Subroutine that checks if button in R0 is pressed, and updates stored value.
	update_button:
			LOAD R2 [R5+INPUT]			;Load input bits into R2
			LOAD R3 R2					;Save the values of the bits in R3 as well
			LOAD R1 R0					;Load the button to be pressed in R1
			LOAD R0 1					;Load the number 1 in R0 in preparation of bit shift
			BTS  shift_bits				;Shift bits
			AND  R2 R0
			BEQ  update_button_end
			LOAD R4 [GB+button_prev_state+R1]
			AND  R4 R0
			BNE  update_button_end
			AND  R3 1
			BEQ  increment
			LOAD R0 [GB+leds_timers+R1]
			BEQ  update_button_end
			SUB  R0 10
			STOR R0 [GB+leds_timers+R1]
			BRA  update_button_end
	increment:
			LOAD R0 [GB+leds_timers+R1]
			CMP  R0 100
			BEQ  update_button_end
			ADD  R0 10
			STOR R0 [GB+leds_timers+R1]
			BRA  update_button_end
	update_button_end:
			RTS
			
			
	update_ad_button:
			
			
	; R0 is value to be shifted (right) and R1 number of bits to be shifted
shift_bits:
        PUSH R1
        CMP  R1  0
shift_bits_cond:
        BEQ  shift_bits_end
        MULS  R0  2 ; shift left
        SUB  R1  1
        BRA shift_bits_cond
shift_bits_end:
        PULL R1
        RTS
		
		
	
	timer_interrupt:
	
			