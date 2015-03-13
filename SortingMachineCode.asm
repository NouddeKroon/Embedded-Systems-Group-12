@DATA
    abort DW 0         ;boolean, true if abort has been pressed
    startStop DW 0     ;boolean, true if start/stop is currently pressed
    stopPressed DW 0   ;boolean, true if start/stop has been 
	                   ;pressed during current cycle
    colorWhite DW 0    ;boolean, true if white disk has been detected during 
	                   ;current cycle
    conveyorBelt DW 0  ;current strength of conveyor belt output
    rotatingBuckets DW 0  ;current strength of rotating buckets output
    loadingArm DW 0    ;current strength of loadingArm output
    colorLED DW 0      ;current strength of color detector led
    positionDetectorLED DW 0  ;current strength of position detector lED 
	rotatingBucketsLED DW 0  ;current strength of rotating buckets LED
    whiteBucketFront DW 0  ;boolean, true if white disk bucket is infront
    black DW 0         ;amount of black chips detected so far
    white DW 0         ;amount of white chips detected so far
    stateDisplay DW 0  ;number tracking current state
    loadingArmPS DW 0  ;boolean, true if loading arm sensor is high
    positionDetectorSensor DW 0 ;boolean, true if position detector sensor is high
    rotatingBucketsSensor DW 0  ;boolean, true if rotating buckets sensor is high
    colorSensor DW 0   ;boolean, true if color sensor 
    clock DW 0         ;an integer counting up once every interrupt
    previousInput DW 0 ;variable containing previous input
    counter DW 0       ;counter tracking PWM cycles
    displayCounter DW 0  ;counter used in tracking previous display segment activated
	
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
	CONVEYORSTRENGTH EQU 80 ;
	BUCKETSSTRENGTH EQU 80 ;
	ARMSTRENGTH EQU 80 ;
	COLORSTRENGTH EQU 80;
    POSITIONSTRENGTH EQU 80;
	TIMER_INTR_ADDR  EQU  16    ;internal adddress of timer interrupt
    TIMER_DELTA  EQU  10        ;Wait time of timer interrupt

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
			