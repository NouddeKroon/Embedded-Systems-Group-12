@DATA
	leds_timers DS 8
	button_prev_state DW 0
	counter DW 90
	
@CODE
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
	ADCONV     EQU    6  ;  rel pos of ad converter values
    
    ; ARRAYS

	TIMER_INTR_ADDR  EQU  16
    TIMER_DELTA  EQU  10

   main :
			LOAD R0  timer_interrupt
			ADD  R0  R5
			LOAD R1  TIMER_INTR_ADDR
			STOR R0  [R1]
			LOAD R5  IOAREA
			LOAD R0  10	
			SUB  R0  [R5+TIMER]
			STOR R0  [R5+TIMER]
			SETI 8
			
	update_buttons_loop:
			LOAD R0 1
			BRS  update_button
			LOAD R0 2
			BRS  update_button
			LOAD R0 3
			BRS  update_button
			LOAD R0 4
			BRS  update_button
			LOAD R0 5
			BRS  update_button
			LOAD R0 6
			BRS  update_button
			LOAD R0 7
			BRS  update_button
			BRS  update_ad_button
			BRA  update_buttons_loop
			
	;Subroutine that checks if button in R0 is pressed, and updates stored value.
	update_button:
			LOAD R2 [R5+INPUT]					;Load input bits into R2
			LOAD R3 R2							;Save the values of the bits in R3 as well
			LOAD R1 R0							;Load the button to be pressed in R1
			LOAD R0 1							;Load the number 1 in R0 in preparation of bit shift
			BRS  shift_bits						;Shift bits
			AND  R2 R0							;Select the relevant input bit	
			BEQ  update_button_set_zero			;If 0, jump to update_button_set_zero, to store the state
			LOAD R4 [GB+button_prev_state]		;Load previous state in R4
			AND  R4 R0							;Select the relevant bit of the previous state
			BNE  update_button_end				;If previous state has relevant bit already pressed, jump to end
			ADD  R1 leds_timers					;Load the address of the relevant timer in R1
			AND  R3 1							;Select only the first bit of the input
			BEQ  increment						;If this is 0, we increment the counter
			LOAD R4 [GB+R1]						;Load the previous led timer in R0
			BEQ  update_state					;If this is already 0, we jump to update_state
			SUB  R4 10							;If not already 0, substract 10
			STOR R4 [GB+R1]						;Store the newfound value at the led timer
			BRA  update_state					;Branch to update state
	increment:
			LOAD R4 [GB+R1]						;Load the previous led timer in R0
			CMP  R4 100							
			BEQ  update_state					;If previous timer is already 100, skip to update_button_end
			ADD  R4 10							;Increment the timer by 10
			STOR R4 [GB+R1]						;Store the new timer in the array
	update_state:
			LOAD R1 [GB+button_prev_state]		;Load the previous state in R1
			OR   R1 R0							;Set the relevant button to 1
			STOR R1 [GB+button_prev_state]		;Store the new state
			BRA  update_button_end				;Branch to end
	update_button_set_zero:
			LOAD R1  [GB+button_prev_state]		;Load the previous state in R1
			XOR  R0  %1							;Flip all the bits in R0
			AND  R1  R0							;Set the relevant bit to 0
			STOR R1 [GB+button_prev_state]		;Store the new state
	update_button_end:
			RTS
			
			
	update_ad_button:
			LOAD R0 [R5+ADCONV]
			MULS R0 100
			DIV  R0 255
			STOR R0 [GB+leds_timers]
			
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
		LOAD R0 [GB+counter]
		ADD  R0 10
		CMP  R0 100
		BNE  continue_interrupt
		LOAD R0 0
	continue_interrupt:
		STOR R0 [GB+counter]
		LOAD R2 0
		LOAD R1 [GB+leds_timers]
		CMP  R1 R0
		BLE  continue_button_1
		XOR  R2 %01
	continue_button_1:
		LOAD R1 [GB+leds_timers+1]
		CMP  R1 R0
		BLE  continue_button_2
		XOR  R2 %010
	continue_button_2:
		LOAD R1 [GB+leds_timers+2]
		CMP  R1 R0
		BLE  continue_button_3
		XOR  R2 %0100
	continue_button_3:
		LOAD R1 [GB+leds_timers+3]
		CMP  R1 R0
		BLE  continue_button_4
		XOR  R2 %01000
	continue_button_4:
		LOAD R1 [GB+leds_timers+4]
		CMP  R1 R0
		BLE  continue_button_5
		XOR  R2 %010000
	continue_button_5:
		LOAD R1 [GB+leds_timers+5]
		CMP  R1 R0
		BLE  continue_button_6
		XOR  R2 %0100000
	continue_button_6:
		LOAD R1 [GB+leds_timers+6]
		CMP  R1 R0
		BLE  continue_button_7
		XOR  R2 %01000000
	continue_button_7:
		LOAD R1 [GB+leds_timers+7]
		CMP  R1 R0
		BLE  continue_end
		XOR  R2 %010000000
	continue_end:
		STOR R2 [R5+OUTPUT]
		LOAD R0 1000
		STOR R0 [R5+TIMER]
		SETI 8
		RTE
			