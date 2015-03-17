@DATA
    abort                   DW 0;boolean, true if abort has been pressed
    startStop               DW 0;boolean, true if start/stop is currently pressed
    stopPressed             DW 0;boolean, true if start/stop has been 
								;pressed during current cycle
    colorWhite              DW 0;boolean, true if white disk has been detected during 
								;current cycle
    conveyorBelt            DW 0;current strength of conveyor belt output
    rotatingBuckets         DW 0;current strength of rotating buckets output
    loadingArm              DW 0;current strength of loadingArm output
    colorLED                DW 0;current strength of color detector led
    positionDetectorLED     DW 0;current strength of position detector lED 
	rotatingBucketsLED      DW 0;current strength of rotating buckets LED
    whiteBucketFront        DW 0;boolean, true if white disk bucket is in front
    black                   DW 0;amount of black chips detected so far
    white                   DW 0;amount of white chips detected so far
    stateDisplay            DW 0;number tracking current state
    loadingArmPS            DW 0;boolean, true if loading arm sensor is high
    positionDetectorSensor  DW 0;boolean, true if position detector sensor is high
    rotatingBucketsSensor   DW 0;boolean, true if rotating buckets sensor is high
    colorSensor             DW 0;boolean, true if color sensor 
    clock                   DW 0;an integer counting up once every interrupt
    previousInput           DW 0;variable containing previous input
    counter                 DW 0;counter tracking PWM cycles
    displayCounter          DW 0;counter used in tracking previous display segment activated
	
@CODE
    IOAREA           EQU  -16   ;  address of the I/O-Area, modulo 2^18
    INPUT            EQU    7   ;  position of the input buttons (relative to IOAREA)
    OUTPUT           EQU   11   ;  relative position of the power outputs
    DSPDIG           EQU    9   ;  relative position of the 7-segment display's digit 
                                ;  selector
    DSPSEG           EQU    8   ;  relative position of the 7-segment display's 
                                ;  segments
    TIMER            EQU   13   ;  rel pos of timer in I/O area
	ADCONV           EQU    6   ;  rel pos of ad converter values
	CONVEYORSTRENGTH EQU   80   ;
	BUCKETSSTRENGTH  EQU   80   ;
	ARMSTRENGTH      EQU   80   ;
	COLORSTRENGTH    EQU   80   ;
    POSITIONSTRENGTH EQU   80   ;
	TIMER_INTR_ADDR  EQU   16   ;internal address of timer interrupt
    TIMER_DELTA      EQU   10   ;Wait time of timer interrupt
 
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
	
	resting_state :               ;begin resting state 
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_00_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_00_end :             ;
		LOAD R0 [GB+startStop]    ;Load the startStop boolean
		BEQ if_guard_00_end       ;If false, do nothing
		LOAD R0 ARMSTRENGTH       ;                  
		STOR R0 [GB+loadingArm]   ;Set loadingArm to ARMSTRENGTH 
		LOAD R0 0                 ;
		STOR R0 [GB+stopPressed]  ;Set stopPressed to false
		LOAD R0 1                  
		STOR R0 [GB+stateDisplay] ;Update the stateDisplay
		BRA running_01            ;Branch to the next state
	if_guard_00_end :
	    BRA resting_state             ;endlessly loop
	
	
	
	running_01:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_01_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_01_end :             ;
		LOAD R0 [GB+loadingArmPS]
		BEQ  if_guard_01_end
		LOAD R0 2
		STOR R0 [GB+stateDisplay] ;display lost when R0 is used, maybe use another reg
		BRA running_02
	if_guard_01_end:
		BRA running_01
	
    running_02:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_02_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_02_end :             ;
		LOAD R0 [GB+loadingArmPS] 
		BNE  if_guard_02_end      ;If true, loop, if false execute body
		LOAD R0 0
		STOR R0 [GB+clock]
		LOAD R0	CONVEYORSTRENGTH
		STOR R0 [GB+conveyorBelt]
		LOAD R0	COLORSTRENGTH
		STOR R0 [GB+colorLED]
	    LOAD R0	POSITIONSTRENGTH
		STOR R0 [GB+positionDetectorLED]
		LOAD R0	0
		STOR R0 [GB+loadingArm]
		STOR R0 [GB+colorWhite]
	    LOAD R0	3
		STOR R0 s[GB+stateDisplay]
		BRA running_03
	if_guard_02_end:
		BRA running_02	
    
	running_03:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_03_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_03_end :             ;
		LOAD R0 [GB+colorSensor]
		BEQ  if_guard_03_01_end
		LOAD R0 1
		STOR R0 [GB+colorWhite]
	if_guard_03_01_end:
		LOAD R0 [GB+clock]
		CMP  R0 500
		BLT  if_guard_03_02_end    ;not completely sure of this, revise later
		LOAD R0	0
		STOR R0 [GB+conveyorBelt]
		STOR R0 [GB+colorLED]
		STOR R0 [GB+positionDetectorLED]
		STOR R0 [GB+stateDisplay]
		BRA  resting_state
    if_guard_03_02_end:
		LOAD R0	[GB+positionDetectorSensor]
		BEQ  if_guard_03_03_end
		LOAD R0	0
		STOR R0 [GB+conveyorBelt]
		STOR R0 [GB+colorLED]
		STOR R0 [GB+positionDetectorLED]
		LOAD R0 4
		STOR R0 [GB+stateDisplay]
		BRA  running_04
	if_guard_03_03_end:
		BRA running_03
		
	running_04:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_04_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_04_end:
		LOAD R0 [GB+colorWhite]   ;if statement with an AND operator
		BEQ  if_guard_04_01_end   ;if one condition is not true, branch to next if 
		LOAD R0 [GB+whiteBucketFront]
		BNE  if_guard_04_01_end
		LOAD R0 POSITIONSTRENGTH
		STOR R0 [GB+rotatingBucketsLED]
        LOAD R0 0
		STOR R0 [GB+clock]
		LOAD R0 5
		STOR R0 [GB+stateDisplay]
		BRA  running_05
	if_guard_04_01_end:
		LOAD R0 [GB+colorWhite]   ;if statement with an AND operator
		BEQ  if_guard_04_02_end   ;if one condition is not true, branch to next if 
		LOAD R0 [GB+whiteBucketFront]
		BEQ  if_guard_04_02_end
		LOAD R0 [GB+white]
		ADD	 R0 1
		STOR R0 [GB+white]
		LOAD R0 8
		STOR R0 [GB+stateDisplay]
		BRA  running_08
	if_guard_04_02_end:
		LOAD R0 [GB+colorWhite]   ;if statement with an AND operator
		BNE  if_guard_04_03_end   ;if one condition is not true, branch to next if 
		LOAD R0 [GB+whiteBucketFront]
		BNE  if_guard_04_03_end
		LOAD R0 [GB+black]
		ADD	 R0 1
		STOR R0 [GB+black]
		LOAD R0 8
		STOR R0 [GB+stateDisplay]
		BRA  running_08
	if_guard_04_03_end:
		LOAD R0 [GB+colorWhite]   ;if statement with an AND operator
		BNE  if_guard_04_04_end   ;if one condition is not true, branch to next if 
		LOAD R0 [GB+whiteBucketFront]
		BEQ  if_guard_04_04_end
		LOAD R0 BUCKETSSTRENGTH
		STOR R0 [GB+rotatingBuckets]
        LOAD R0 0
		STOR R0 [GB+clock]
		LOAD R0 7
		STOR R0 [GB+stateDisplay]
		BRA  running_07
	if_guard_04_04_end:
	    BRA  running_04
		
	running_05:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_05_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_05_end:
		LOAD R0 [GB+clock]
		CMP  R0 1
		BLT  if_guard_05_end
		LOAD R0 BUCKETSSTRENGTH
		STOR R0 [GB+rotatingBuckets]
	   	LOAD R0 6
		STOR R0 [GB+stateDisplay]
		BRA  running_06
	if_guard_05_end:
		BRA	 running_05
	
	running_06:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_06_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_06_end:
		LOAD R0 [GB+rotatingBucketsSensor]
		BNE  if_guard_06_end
		LOAD R0 0
		STOR R0 [GB+rotatingBuckets]
		STOR R0 [GB+rotatingBucketsLED]
		LOAD R0 1
		STOR R0 [GB+whiteBucketFront]
		LOAD R0 [GB+white]
		ADD  R0 1
		STOR R0 [GB+white]
		LOAD R0 8
		STOR R0 [GB+stateDisplay]
		BRA  running_08
	if_guard_06_end:
		BRA  running_06
	
	running_07:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_07_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_07_end:
		LOAD R0 [GB+clock]
		CMP  R0 40
		BLT  if_guard_07_end
		LOAD R0 0
		STOR R0 [GB+whiteBucketFront]
		STOR R0 [GB+rotatingBuckets]
		LOAD R0 [GB+black]
		ADD  R0 1
		STOR R0 [GB+black]
	    LOAD R0 8
		STOR R0 [GB+stateDisplay]
		BRA  running_08
	if_guard_07_end:
		BRA  running_07
		
	running_08:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_08_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_08_end:
		LOAD R0 0
		STOR R0 [GB+clock]
		LOAD R0 CONVEYORSTRENGTH
		STOR R0 [GB+conveyorBelt]
		LOAD R0 POSITIONSTRENGTH
		STOR R0 [GB+positionDetectorLED]
		LOAD R0 9
		STOR R0 [GB+stateDisplay]
		BRA  running_09
	
	running_09:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_09_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_09_end:
		LOAD R0 [GB+stopPressed]
		BEQ  if_guard_09_01_end
		LOAD R0 0
		STOR R0 [GB+conveyorBelt]
		STOR R0 [GB+positionDetectorLED]
		STOR R0 [GB+stateDisplay]
		BRA  resting_state
	if_guard_09_01_end:
		LOAD R0 [GB+stopPressed]   ;may be redundant, not sure
        BNE  if_guard_09_02_end    ;again may be redundant, since the first check
		                           ;says it cant be true at this point
	    LOAD R0 0
		STOR R0 [GB+conveyorBelt]
		STOR R0 [GB+positionDetectorLED]
		LOAD R0 ARMSTRENGTH
		STOR R0 [GB+loadingArm]
		LOAD R0 1
		STOR R0 [GB+stateDisplay]
        BRA  running_01
    if_guard_09_02_end:
		BRA running_09
		
	abort_99:
		LOAD R0 0
		STOR R0 [GB+loadingArm]
		STOR R0 [rotatingBuckets]
		STOR R0 [GB+rotatingBucketsLED]
v		STOR R0 [GB+conveyorBelt]
   		STOR R0 [GB+colorLED]
		STOR R0 [GB+positionDetectorLED]
		LOAD R0 98
		STOR R0 [GB+stateDisplay]
		LOAD R0 0
		STOR R0 [GB+abort]
		BRA  abort_98
		
	abort_98:
		LOAD R0 [GB+startStop] 
		BEQ  if_guard_98_end
		LOAD R0 97
		STOR R0 [GB+stateDisplay]
		BRA  initialize_97
	if_guard_98_end:
		BRA  abort_98
		
	initialize_97:
	    LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_97_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_97_end:
		LOAD R0 [GB+loadingArm]
		CMP R0 0
		BNE if_guard_97_01_end
		LOAD R0 ARMSTRENGTH
		STOR R0 [GB+loadingArm]
	if_guard_97_01_end:
		LOAD R0 [GB+loadingArm]
		CMP  R0 ARMSTRENGTH
		BNE  if_guard_97_02_end
		LOAD R0 [GB+loadingArmPS]
		BEQ  if_guard_97_02_end
		LOAD R0 96
		STOR R0 [GB+stateDisplay]
		BRA  initialize_96
	if_guard_97_02_end:
		BRA  initialize_97
		
	initialize_96:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_96_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_96_end:
		LOAD R0 [GB+loadingArmPS]
		BNE  if_guard_96_end
		LOAD R0 0
		STOR R0 [GB+loadingArm]
		STOR R0 [GB+clock]
		LOAD R0 POSITIONSTRENGTH
		STOR R0 [GB+rotatingBuckets]
		LOAD R0 95
		STOR R0 [GB+stateDisplay]
		BRA  initialize_95
    if_guard_96_endZ:
	    BRA  initialize_96
		
	initialize_95:
	    LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_95_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_95_end:	
		LOAD R0 [GB+clock]
		CMP  R0 1
		BLT  if_guard_95_end
		LOAD R0 BUCKETSSTRENGTH
		STOR R0 [GB+rotatingBuckets]
		LOAD R0 94
		STOR R0 [G+stateDisplay]
		BRA  initialize_94
	if_guard_95_end:
		BRA initialize_95
		
	initialize_94:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_94_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_94_end:
		LOAD R0 [GB+rotatingBucketsSensor]
		BNE  if_guard_94_end
		LOAD R0 0
		STOR R0 [GB+rotatingBuckets]
		STOR R0 [GB+rotatingBucketsLED]
		STOR R0 [GB+stateDisplay]
		LOAD R0 1
		STOR R0 [GB+whiteBucketFront]
		BRA  resting_state
	if_abort_94_end:
		BRA initialize_94


				
	
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
		BRS set_outputs_pwm
		BRS read_inputs
		BRS activate_display
		LOAD R0 1000            ;Schedule new interrupt
		STOR R0 [R5+TIMER]      ;
		SETI 8                  ;Enable interrupt
		RTE
	
	
	
	
	set_outputs_pwm:
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

			