@DATA
	leds_timers DS 8
	button_prev_state DW 0
	counter DW 90
	
@CODE
   IOAREA      EQU  -16  ;  address of the I/O-Area, modulo 2^18
    INPUT      EQU    7  ;  position of the input buttons (relative to IOAREA)
   OUTPUT      EQU   11  ;  relative position of the power outputs
   DSPDIG      EQU    9  ;  relative position of the 7-segment display's digit 
                         ;  selector
   DSPSEG      EQU    8  ;  relative position of the 7-segment display's 
                         ;  segments
    TIMER      EQU   13  ;  rel pos of timer in I/O area
	ADCONV     EQU    6  ;  rel pos of ad converter values
    
    ; ARRAYS

	TIMER_INTR_ADDR  EQU  16
    TIMER_DELTA  EQU  10

   main :
			LOAD R0  timer_interrupt         ;Retrieve relative interrupt  
			                                 ;location
			ADD  R0  R5                      ;Add to address of program
			LOAD R1  TIMER_INTR_ADDR         ;Load address of the timer into R1
			STOR R0  [R1]                    ;Store the interrupt location 
			                                 ;at the timer interrupt location
			LOAD R5  IOAREA                  ;Load address of IOAREA into R5
			LOAD R0  0	                     
			SUB  R0  [R5+TIMER]              ;Calculate delta time
			STOR R0  [R5+TIMER]              ;Set timer to 0
			SETI 8                           ;Enable timer interrupt
				
	;Main loop, checks if each button is pressed and updates leds_timers 
	;appropriately.
		
	update_buttons_loop:
		;Call the update_button subroutine for buttons 1 to 7
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
;
			BRS  update_ad_button    			;Call subroutine for updating 
			                                    ;LED0           
			BRA  update_buttons_loop			;Restart loop
			
	;Subroutine that checks if button in R0 is pressed, and updates stored value
	update_button:
			LOAD R2 [R5+INPUT]					;Load input bits into R2
			LOAD R3 R2							;Save the values of the bits in 
			                                    ;R3 as well
			LOAD R1 R0							;Load the button to be pressed 
			                                    ;in R1
			LOAD R0 1							;Load the number 1 in R0 in 
			                                    ;preparation of bit shift
			BRS  shift_bits						;Shift bits
			AND  R2 R0							;Select the relevant input bit	
			BEQ  update_button_set_zero			;If 0, jump to 
			                                    ;update_button_set_zero, to 
												;store the state
			LOAD R4 [GB+button_prev_state]		;Load previous state in R4
			AND  R4 R0							;Select the relevant bit of the
                                                ;previous state
			BNE  update_button_end				;If previous state has relevant 
			                                    ;bit already pressed, jump to 
												;end
			ADD  R1 leds_timers					;Load the address of the 
			                                    ;relevant timer in R1
			AND  R3 1							;Select only the first bit of 
			                                    ;the input
			BEQ  increment						;If this is 0, we increment the 
			                                    ;counter
			LOAD R4 [GB+R1]						;Load the previous led timer 
			                                    ;in R0
			BEQ  update_state					;If this is already 0, we jump 
			                                    ;to update_state
			SUB  R4 10							;If not already 0, substract 10
			STOR R4 [GB+R1]						;Store the new found value at 
			                                    ;the led timer
			BRA  update_state					;Branch to update state
	increment:
			LOAD R4 [GB+R1]						;Load the previous led timer 
			                                    ;in R0
			CMP  R4 100							
			BEQ  update_state					;If previous timer is already 
			                                    ;100, skip to update_button_end
			ADD  R4 10							;Increment the timer by 10
			STOR R4 [GB+R1]						;Store the new timer in the 
			                                    ;array
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
;
	;Subroutine to update leds_timers for LED0 according to the analogue slider.
	update_ad_button:
			LOAD R0 [R5+ADCONV]
			MULS R0 100
			DIV  R0 255
			STOR R0 [GB+leds_timers]
			
	; R0 is value to be shifted (right) and R1 number of bits to be shifted
	shift_bits:
        PUSH R1                   ;push R1 to prevent mutation
        CMP  R1  0
		BEQ  shift_bits_end
	shift_bits_cond:
        MULS R0  2 ; shift left
        SUB  R1  1
		BEQ  shift_bits_end
        BRA shift_bits_cond
	shift_bits_end:
        PULL R1                   ;Return original value for R1
        RTS
	
;R0 holds the counter
;R1 holds the LED to be set
;R2 holds the word in which the bit corresponding to the LED will be set to 1,
;if the LED is supposed to be on at this time. The routine assumes that the
;corresponding bit is 0 at time of calling. The rest of the word is not mutated.
;R3 holds a word in which the bit representing the LED is 1 
    set_led:
		PUSH R0                          ;Save the value of R0
		LOAD R0  1                       
		BRS  shift_bits                  ;Shift the bits to the right place for 
		                                 ;the current LED
		LOAD R3	R0                       ;Save this word
		PULL R0                          ;Retrieve R0
		;Add to address of the leds_timers array to R1 to obtain the address 
		;of the correct timer.
		ADD  R1 leds_timers              
		LOAD R4	[GB+R1]                  ;Load the LED timer into R4
		CMP  R4 R0                       ;Compare the timer to the counter
		BLE  set_led_end                 ;If timer is less than counter, 
		                                 ;led is not on.
		XOR  R2  R3                      ;Flip the bit for the current LED
	set_led_end:
		RTS	
		
    ;Timer interrupt service routine	
	timer_interrupt:
		LOAD R0 [GB+counter]		;Load the counter into R0
		ADD  R0 10                  ;Increment counter by 10
		CMP  R0 100                 ;Check if counter is equal to 100
		BNE  timer_interrupt_continue
		LOAD R0 0                   ;If counter is 100 reset to 0
	timer_interrupt_continue:
		STOR R0 [GB+counter]        ;Store new counter value 
		LOAD R2 0                   ;Set R2 initially to 0
		;
		;For each led, call set_led routine, which sets the appropriate bit in 
		;R2 to 1 if the led is supposed to be on at this point in time.
		LOAD R1 0
		BRS  set_led             
		LOAD R1 1
		BRS  set_led
		LOAD R1 2
		BRS  set_led
		LOAD R1 3
		BRS  set_led
		LOAD R1 4
		BRS  set_led
		LOAD R1 5
		BRS  set_led
		LOAD R1 6
		BRS  set_led
		LOAD R1 7
		BRS  set_led
		;
	continue_end:
		STOR R2 [R5+OUTPUT]		;Update the LEDS
		LOAD R0 1000            ;Schedule new interrupt
		STOR R0 [R5+TIMER]      ;
		SETI 8                  ;Enable interrupt
		RTE
			