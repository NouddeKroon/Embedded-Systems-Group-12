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
	TIMERBUCKETS	 EQU   2000
	TIMERLED		 EQU   100
	TIMERFIN		 EQU   5000
	
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
		STOR R0 [GB+stateDisplay] 
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
		STOR R0 [GB+stateDisplay]
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
		CMP  R0 TIMERFIN
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
		CMP  R0 TIMERLED
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
		CMP  R0 TIMERBUCKETS
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
		CMP  R0 TIMERLED
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
	
	read_inputs:
		LOAD R0 0                           ;Read input of the Start/Stop button
	update_button_startStop:
		LOAD R2 [R5+INPUT]					;Load input bits into R2
		LOAD R3 R2							;Save the values of the bits in 
		                                    ;R3 as well
		LOAD R1 R0							;Load the button to be pressed 
		                                    ;in R1
		LOAD R0 1							;Load the number 1 in R0 in 
		                                    ;preparation of bit shift
		BRS  shift_bits						;Shift bits
		AND  R2 R0							;Select the relevant input bit	
		BEQ  update_button_startStop_false	;If 0, jump to 
		                                    ;update_button_set_zero, to 
											;store the state
		LOAD R4 [GB+previousInput]			;Load previous state in R4
		AND  R4 R0							;Select the relevant bit of the
                                            ;previous state
		BNE  update_button_startStop_false				
		LOAD R0 1
		STOR R0 [GB+startStop]
		BRA  update_button_abort
			
	update_button_startStop_false:
		LOAD R0 0
		STOR R0 [GB+startStop]
	
	update_button_abort:
		LOAD R0 1							;Read input of the abort button
		LOAD R2 [R5+INPUT]					;Load input bits into R2
		LOAD R3 R2							;Save the values of the bits in 
		                                    ;R3 as well
		LOAD R1 R0							;Load the button to be pressed 
		                                    ;in R1
		LOAD R0 1							;Load the number 1 in R0 in 
		                                    ;preparation of bit shift
		BRS  shift_bits						;Shift bits
		AND  R2 R0							;Select the relevant input bit	
		BEQ  update_button_abort_false	;If 0, jump to 
		                                    ;update_button_set_zero, to 
											;store the state
		LOAD R4 [GB+previousInput]			;Load previous state in R4
		AND  R4 R0							;Select the relevant bit of the
                                            ;previous state
		BNE  update_button_abort_false				
		LOAD R0 1
		STOR R0 [GB+startStop]
		BRA  colorSensor_check
			
	update_button_abort_false:
		LOAD R0 0
		STOR R0 [GB+abort]                  
	colorSensor_check:                      
		LOAD R2 [R5+INPUT]                  ;Load the current input
		LOAD R0 1
		LOAD R1 2
		BRS  shift_bits                     ;Shift 1 to the bit you want to check
		AND  R0 R2                          ;Compare with the input
		BEQ  colorSensor_false              ;If 0, set colorSensor to false
		LOAD R0 1                           ;If 1, set to true
		STOR R0 [GB+colorSensor]
		BRA  positionDetectorSensor_check   
	colorSensor_false:
		LOAD R0 0
		STOR R0 [GB+colorSensor]
	positionDetectorSensor_check:
		LOAD R0 1
		LOAD R1 3
		BRS  shift_bits                     ;Shift 1 to the bit you want to check
		AND  R0 R2                          ;Compare with the input
		BEQ  positionDetectorSensor_false   ;If 0, set positionDetectorSensor to false
		LOAD R0 1                           ;If 1, set to true
		STOR R0 [GB+positionDetectorSensor]
		BRA  rotatingBucketsSensor_check
	positionDetectorSensor_false:
		LOAD R0 0
		STOR R0 [GB+positionDetectorSensor]
	rotatingBucketsSensor_check:
		LOAD R0 1
		LOAD R1 4
		BRS  shift_bits                     ;Shift 1 to the bit you want to check
		AND  R0 R2                          ;Compare with input
		BEQ  rotatingBucketsSensor_false    ;If 0, set rotatingBucketsSensor to false
		LOAD R0 1                           ;If 1, set to true
		STOR R0 [GB+rotatingBucketsSensor]
		BRA  loadingArmPS_check
	rotatingBucketsSensor_false:
		LOAD R0 0
		STOR R0 [GB+rotatingBucketsSensor]
	loadingArmPS_check:
		LOAD R0 1
		LOAD R1 5
		BRS  shift_bits                     ;Shift 1 to the bit you want to check
		AND  R0 R2                          ;Compare with input
		BEQ  loadingArmPS_false             ;If 0, set loadingArmPS to false
		LOAD R0 1                           ;If 1, set to true
		STOR R0 [GB+loadingArmPS]
		BRA  input_end
	loadingArmPS_false:
		LOAD R0 0
		STOR R0 [GB+loadingArmPS]
	input_end:
		STOR R2 [GB+previousInput]
		RTS
	
	
	
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
	
	set_outputs_pwm:
		LOAD R0 [GB+counter]		;Load the counter into R0
		ADD  R0 10                  ;Increment counter by 10
		CMP  R0 100                 ;Check if counter is equal to 100
		BNE  set_outputs_pwm_con
		LOAD R0 0                   ;If counter is 100 reset to 0
	set_outputs_pwm_con:
		STOR R0 [GB+counter]        ;Store new counter value 
		LOAD R2 0                   ;Set R2 initially to 0
		LOAD R1 [GB+loadingArm]		;Load loading arm strength in R1
		CMP  R1 R0					;Compare strength to counter
		BLE  set_outputs_pwm_2      ;If strength <= counter do nothing
		OR   R2 %01                 ;If strength > counter set corresponding output bit
	set_outputs_pwm_2:
		LOAD R1 [GB+conveyorBelt]	;Load conveyor belt strength in R1
		CMP  R1 R0					;Compare strength to counter
		BLE  set_outputs_pwm_3		;If strength <= counter do nothing
		OR   R2 %010				;If strength > counter set corresponding output bit
	set_outputs_pwm_3:
		LOAD R1 [GB+rotatingBuckets] ;Load rotating bucket strength in R1
		CMP  R1 R0					;compare strength to counter
		BLE  set_outputs_pwm_4		;If strength <= counter do nothing
		OR   R2 %0100				;if strength > counter set corresponding output bit
	set_outputs_pwm_4:				
		LOAD R1 [GB+colorLED]		;Load color LED brightness in R1
		CMP  R1 R0					;Compare brightness to counter
		BLE  set_outputs_pwm_5		;If brightness <= counter do nothing
		OR   R2 %01000				;If brightness > counter set corresponding output bit
	set_outputs_pwm_5:
		LOAD R1 [GB+positionDetectorLED] ;Load position detector LED brightness in R1
		CMP  R1 R0					;Compare brightness to counter
		BLE  set_outputs_pwm_6		;If brightness <= counter do nothing
		OR   R2 %010000				;If brightness > counter set corresponding output bit
	set_outputs_pwm_6:
		LOAD R1 [GB+rotatingBucketsLED]	;Load rotating bucket LED brightness in R1
		CMP  R1 R0					;Compare brightness to counter
		BLE  set_outputs_pwm_end	;If brightness <= counter do nothing
		OR   R2 %0100000			;If brightness > counter set corresponding output bit
	set_outputs_pwm_end:
		STOR R2 [R5+OUTPUT]		;Update the LEDS and motors
		RTS
		
	activate_display:
		LOAD R1 [GB+displayCounter]	;Load the display counter into R1
		CMP  R1 0					;Compare display counter to zero
		BNE  activate_display_d2	;If display counter is not zero, branch away
		LOAD R0 [GB+black]			;Load number of black disks sorted in R0
		MOD  R0 10					;Take that number modulo ten (to get rightmost digit)
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01					;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d2 :
		CMP R1 1					;Compare display counter to 1
		BNE activate_display_d3		;If display counter is not 1, branch away
		LOAD R0 [GB+black]			;Load number of black disks sorted in R0
		DIV R0 10					;Divide number of black disks sorted by ten (to get second digit)
		BRS Hex7Seg					;Convert to corresponding segment code
		STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d3 :
		CMP R1 2					;Compare display counter to 2
		BNE activate_display_d4		;If display counter is not 2, branch away
		LOAD R0 [GB+stateDisplay]	;Load state display in R0
		MOD R0 10					;Take that number modulo ten (to get rightmost digit)
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %0100				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d4 :
		CMP R1 3					;Compare display counter to 3
		BNE activate_display_d5		;If display counter is not 3, branch away
		LOAD R0 [GB+stateDisplay]	;Load state display in R0
		DIV R0 10					;Divide that number by 10
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d5 :
		CMP R1 4					;Compare display counter to 4
		BNE activate_display_d6		;If display counter is not 4, branch away
		LOAD R0 [GB+white]			;Load number of white disks sorted in R0
		MOD R0 10					;Take that number modulo ten (to get rightmost digit)
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d6 :
		CMP R1 5					;Compare display counter to 5
		BNE activate_display_end	;If display counter is not 5, branch away
		LOAD R0 [GB+white]			;Load number of white disks sorted in R0
		DIV R0 10					;Divide that number by 10
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %0100000			;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
	activate_display_end :
		LOAD R1 [GB+displayCounter]	;Load the display counter in R1
		ADD  R1 1					;Increment it
		MOD  R1 6					;Take it modulo six
		STOR R1 [GB+displayCounter]	;Store the updated display counter
		RTS

;Converts an integer to the corresponding 7-segment pattern. Number to be converted
;in R0, return value in R1.
Hex7Seg     :  BRS  Hex7Seg_bgn  ;  push address(tbl) onto stack and proceed at "bgn"
Hex7Seg_tbl : CONS  %01111110    ;  7-segment pattern for '0'
              CONS  %00110000    ;  7-segment pattern for '1'
              CONS  %01101101    ;  7-segment pattern for '2'
              CONS  %01111001    ;  7-segment pattern for '3'
              CONS  %00110011    ;  7-segment pattern for '4'
              CONS  %01011011    ;  7-segment pattern for '5'
              CONS  %01011111    ;  7-segment pattern for '6'
              CONS  %01110000    ;  7-segment pattern for '7'
              CONS  %01111111    ;  7-segment pattern for '8'
              CONS  %01111011    ;  7-segment pattern for '9'
Hex7Seg_bgn:   AND  R0  %01111   ;  R0 := R0 MOD 16 , just to be safe...
              LOAD  R1  [SP++]   ;  R1 := address(tbl) (retrieve from stack)
              LOAD  R1  [R1+R0]  ;  R1 := tbl[R0]
               RTS
			