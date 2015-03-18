@DATA
    stopPressed             DW 0;boolean, true if start/stop has been 
								;pressed during current cycle
    colorWhite              DW 0;boolean, true if white disk has been detected during 
								;current cycle
    outputs		            DW 0;A bitmask in which each output that is currently activated has it's corresponding bit set to 1
    whiteBucketFront        DW 0;boolean, true if white disk bucket is in front
    black                   DW 0;amount of black chips detected so far
    white                   DW 0;amount of white chips detected so far
    stateDisplay            DW 0;number tracking current state
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
	CONVEYORSTRENGTH EQU   30   ;
	BUCKETSSTRENGTH  EQU   40   ;
	ARMSTRENGTH      EQU   30   ;
	COLORSTRENGTH    EQU   80   ;
    POSITIONSTRENGTH EQU   100   ;
	TIMER_INTR_ADDR  EQU   16   ;internal address of timer interrupt
    TIMER_DELTA      EQU   10   ;Wait time of timer interrupt
	TIMERBUCKETS	 EQU   1500
	TIMERLED		 EQU   500
	TIMERFIN		 EQU   2000
	
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
			BRA initialize_97		
	;Main loop, checks if each button is pressed and updates leds_timers 
	;appropriately.
	
	resting_state:               ;begin resting state
		LOAD R1 [R5+INPUT]		  ;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  ;Select second bit of input
		BEQ if_abort_00_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_00_end:             
		LOAD R0 [GB+stopPressed]	  ;Check if start/stop is pressed
		BEQ if_guard_00_end       ;If false, do nothing
		LOAD R0 [GB+outputs]
		OR   R0 %01
		STOR R0 [GB+outputs]     ;Set bit corresponding to loadingArm to true in outputs word
		LOAD R0 0                 ;
		STOR R0 [GB+stopPressed]  ;Set stopPressed to false
		LOAD R0 1                  
		STOR R0 [GB+stateDisplay] ;Update the stateDisplay
		BRA running_01            ;Branch to the next state
	if_guard_00_end:
	    BRA resting_state         ;endlessly loop
	
	
	
	running_01:
		LOAD R1 [R5+INPUT]		  ;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  ;Select second bit of input
		BEQ if_abort_01_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_01_end :             
		LOAD R0 %0100000			
		AND  R0 R1				  ;check if loading arm pressure sensor is pressed
		BEQ  if_guard_01_end	  ;if not do nothing
		LOAD R0 2					
		STOR R0 [GB+stateDisplay] ;Set state to 2
		BRA running_02			  ;Jump to state 2
	if_guard_01_end:
		BRA running_01
	
    running_02:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_02_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_02_end :             
		LOAD R0 %0100000
		AND  R0 R1
		BNE  if_guard_02_end      	;If true, loop, if false execute body
		LOAD R0 0
		STOR R0 [GB+clock]			;Reset clock
		LOAD R0 [GB+outputs]		;Load inputs
		OR   R0  %011010		  	;Set outputs corresponding to conveyor belt, color detector and position detector to true
		AND  R0  %10			  	;Set output corresponding to loading arm to false 
		STOR R0  [GB+outputs]
		LOAD R0 0
		STOR R0 [GB+colorWhite]	  	;Set colorWhite to false
	    LOAD R0	3
		STOR R0 [GB+stateDisplay] 	;Set statedisplay to 3
		BRA running_03			  	;Jump to state 3
	if_guard_02_end:
		BRA running_02	
    
	running_03:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_03_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_03_end :             	
		LOAD R0 %0100
		AND  R0 R1					;Check if input bit corresponding to colorsensor is true
		BEQ  if_guard_03_01_end		;If not, continue
		LOAD R0 1					
		STOR R0 [GB+colorWhite]		;If true, set colorWhite to true
	if_guard_03_01_end:
		LOAD R0 [GB+clock]
		CMP  R0 TIMERFIN			;Check if clock passed the TIMERFIN time
		BLT  if_guard_03_02_end    ;If not, do nothing
		LOAD R0	0
		STOR R0 [GB+outputs]		;If so, set outputs to 0 and go to resting state
		STOR R0 [GB+stopPressed]	;Set stopPressed to false
		BRA  resting_state
    if_guard_03_02_end:
		CMP  R0 250					
		BLT  if_guard_03_03_end		;Inbuilt delay hack to make sure machine waits short time for LED to fire up, TODO! (note R0 holds clock still)
		LOAD R0 %01000				;
		AND  R0 R1
		BNE  if_guard_03_03_end		;Check positiondetector to see if disk arrived, if not do nothing
		LOAD R0	0
		STOR R0 [GB+outputs]		;Turn off all outputs
		LOAD R0 4				
		STOR R0 [GB+stateDisplay]	;Set stateDisplay to 4
		BRA  running_04				;Branch to state 4
	if_guard_03_03_end:
		BRA running_03
		
	running_04:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_04_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_04_end:
		LOAD R0 [GB+colorWhite]   ;if statement with an AND operator
		BEQ  if_guard_04_01_end   ;if one condition is not true, branch to next if 
		LOAD R0 [GB+whiteBucketFront]
		BNE  if_guard_04_01_end		;If second condition is true, branch to next if
		LOAD R0 [GB+outputs]
		OR   R0 %0100000
		STOR R0 [GB+outputs]		;Set output corresponding with bucket position LED to true
        LOAD R0 0					
		STOR R0 [GB+clock]			;Reset clock to 0
		LOAD R0 5					
		STOR R0 [GB+stateDisplay]	;Set state display to 5
		BRA  running_05				;Go to state 5
	if_guard_04_01_end:
		LOAD R0 [GB+colorWhite]   ;if statement with an AND operator
		BEQ  if_guard_04_02_end   ;if one condition is not true, branch to next if 
		LOAD R0 [GB+whiteBucketFront]
		BEQ  if_guard_04_02_end		;If second condition also not true, branch to next if
		LOAD R0 [GB+white]			
		ADD	 R0 1					
		STOR R0 [GB+white]			;Increase white disks by 1
		LOAD R0 8
		STOR R0 [GB+stateDisplay]	
		BRA  running_08				;Set state display to 8 and branch to running_08
	if_guard_04_02_end:
		LOAD R0 [GB+colorWhite]   ;if statement with an AND operator
		BNE  if_guard_04_03_end   ;if one condition is not true, branch to next if 
		LOAD R0 [GB+whiteBucketFront]
		BNE  if_guard_04_03_end		;If second condition also not true, branch to next if
		LOAD R0 [GB+black]
		ADD	 R0 1					
		STOR R0 [GB+black]			;Increment black disks by 1
		LOAD R0 8
		STOR R0 [GB+stateDisplay]
		BRA  running_08				;Set state display to 8 and go to running_08
	if_guard_04_03_end:
		LOAD R0 [GB+colorWhite]   ;if statement with an AND operator
		BNE  if_guard_04_04_end   ;if one condition is not true, branch to end
		LOAD R0 [GB+whiteBucketFront]
		BEQ  if_guard_04_04_end	  ;If second condition is also not true, branch to end
		LOAD R0 [GB+outputs]
		OR   R0 %0100
		STOR R0 [GB+outputs]	 	;Set bit corresponding to rotating buckets motor to true
        LOAD R0 0
		STOR R0 [GB+clock]			;Reset clock
		LOAD R0 7
		STOR R0 [GB+stateDisplay]
		BRA  running_07				;Set state display to 7 and go to state running_07
	if_guard_04_04_end:
	    BRA  running_04
		
	running_05:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_05_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_05_end:
		LOAD R0 [GB+clock]
		CMP  R0 TIMERLED
		BLT  if_guard_05_end		;If not enough time has passed do nothing
		LOAD R0 [GB+outputs]
		OR   R0 %0100
		STOR R0 [GB+outputs]		;In outputs set bit corresponding to rotating buckets to true
	   	LOAD R0 6
		STOR R0 [GB+stateDisplay]
		BRA  running_06				;Set statedisplay to 6 and go to state 6
	if_guard_05_end:
		BRA	 running_05
	
	running_06:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_06_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_06_end:
		LOAD R0 %010000
		AND  R1 R0
		BNE  if_guard_06_end		;Select in input bit corresponding to bucket sensor. If true, go to end.
		LOAD R0 0				
		STOR R0 [GB+outputs]		;When in position turn off outputs
		LOAD R0 1
		STOR R0 [GB+whiteBucketFront]	;Set whiteBucketFront to true
		LOAD R0 [GB+white]
		ADD  R0 1
		STOR R0 [GB+white]				;Increment white disks by 1
		LOAD R0 8
		STOR R0 [GB+stateDisplay]		
		BRA  running_08					;Set state display to 8 and go to running_08 state.
	if_guard_06_end:
		BRA  running_06
	
	running_07:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_07_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_07_end:
		LOAD R0 [GB+clock]
		CMP  R0 TIMERBUCKETS
		BLT  if_guard_07_end
		LOAD R0 0
		STOR R0 [GB+whiteBucketFront]
		STOR R0 [GB+outputs]			;Set all outputs to 0
		LOAD R0 [GB+black]
		ADD  R0 1
		STOR R0 [GB+black]
	    LOAD R0 8
		STOR R0 [GB+stateDisplay]
		BRA  running_08
	if_guard_07_end:
		BRA  running_07
		
	running_08:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_08_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_08_end:
		LOAD R0 0
		STOR R0 [GB+clock]
		LOAD R0 %010010			;Turn on conveyor belt and position detector light
		STOR R0 [GB+outputs]
		LOAD R0 9
		STOR R0 [GB+stateDisplay]	;Set state display to 9 and go to state running_09
		BRA  running_09
	
	running_09:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_09_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_09_end:
		LOAD R0 %01000
		AND  R0 R1
		BEQ  if_guard_09_02_end		;Check if position detector detects light again, if not do nothing.
		LOAD R0 [GB+stopPressed]	
		BEQ  if_guard_09_01_end		;If stop not pressed skip
		LOAD R0 0
		STOR R0 [GB+outputs]		;Turn all outputs off
		STOR R0 [GB+stopPressed]	;Set stopPressed back to 0
		STOR R0 [GB+stateDisplay]	;Set stateDisplay back to 0
		BRA  resting_state			;Jump to resting state
	if_guard_09_01_end:
	    LOAD R0 %01
		STOR R0 [GB+outputs]		;Turn on only loading arm
		LOAD R0 1
		STOR R0 [GB+stateDisplay]	;Set stateDisplay to 1
        BRA  running_01				;Go to running_01
    if_guard_09_02_end:	
		BRA running_09
		
	abort_99:
		LOAD R0 0
		STOR R0 [GB+outputs]	;Turn off all outputs
		LOAD R0 98				
		STOR R0 [GB+stateDisplay]	;Set stateDisplay to 98
		LOAD R0 0					
		STOR R0 [GB+stopPressed]	;set stopPressed to false
		BRA  abort_98
		
	abort_98:
		LOAD R0 [GB+stopPressed] 	
		BEQ  if_guard_98_end		;If stopPressed is false, do nothing
		LOAD R0 97
		STOR R0 [GB+stateDisplay]	;set statedisplay to 97
		BRA  initialize_97			;go to state 97
	if_guard_98_end:
		BRA  abort_98
		
	initialize_97:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_97_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_97_end:
	 	LOAD R0 %01
		STOR R0 [GB+outputs]
	if_guard_97_02_end:
		BRA  initialize_97_B
		
	initialize_97_B:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_97_B_end       ;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99	
	if_abort_97_B_end:
		LOAD R0 %0100000
		AND  R0 R1
		BEQ  initialize_97_B_end
		LOAD R0 96
		STOR R0 [GB+stateDisplay]
	initialize_97_B_end:
		BRA  initialize_96
		
	initialize_96:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_96_end       ;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99	
	if_abort_96_end:
		LOAD R0 %0100000
		AND  R0 R1
		BNE  if_guard_96_end		;If in input bit corresponding to loading arm pressure sensor is 1, skip
		LOAD R0 0
		STOR R0 [GB+clock]			;Reset clock to 0
		LOAD R0 %0100000			;Set outputs with only the rotating bucket LED bit 1
		STOR R0 [GB+outputs]		;Store this in outputs
		LOAD R0 95
		STOR R0 [GB+stateDisplay]
		BRA  initialize_95			;Set stateDisplay to 95 and continue to state 96
    if_guard_96_end:
	    BRA  initialize_96
		
	initialize_95:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_95_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99	
	if_abort_95_end:	
		LOAD R0 [GB+clock]			
		CMP  R0 TIMERLED
		BLT  if_guard_95_end		;If clock is not passed TIMERLED yet, do nothing
		LOAD R0 %0100100			;Set bucket LED and bucket motor to 1
		STOR R0 [GB+outputs]		;Store this in outputs
		LOAD R0 94
		STOR R0 [GB+stateDisplay]
		BRA  initialize_94			;Set stateDisplay to 94 and continue to state 94
	if_guard_95_end:
		BRA initialize_95
		
	initialize_94:
		LOAD R1 [R5+INPUT]		  	;Read inputs and store in R1
		LOAD R0 %010			  
		AND  R0 R1				  	;Select second bit of input
		BEQ if_abort_94_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99	
	if_abort_94_end:
		LOAD R0 %010000
		AND  R0 R1
		BNE  if_guard_94_end
		LOAD R0 0
		STOR R0 [GB+outputs]		;Set all outputs off
		STOR R0 [GB+stateDisplay]	;Set state display to zero
		STOR R0 [GB+stopPressed]	;set stopPressed to false
		LOAD R0 1
		STOR R0 [GB+whiteBucketFront]	;Set whitebucket front to true
		BRA  resting_state			;Branch to resting state
	if_guard_94_end:
		BRA initialize_94
	
		
    ;Timer interrupt service routine	
	timer_interrupt:
		BRS set_outputs_pwm
		BRS read_inputs
		BRS activate_display
		LOAD R0 10            ;Schedule new interrupt
		STOR R0 [R5+TIMER]     
		LOAD R0 [GB+clock]	  ;Update clock
		ADD  R0 1
		STOR R0 [GB+clock]
		SETI 8                 ;Enable interrupt
		RTE					;Return to state machine
	
	read_inputs:		
		LOAD R1 [R5+INPUT]					;Load input bits into R1
		LOAD R2 [GB+previousInput]			;Load previous input bits into R2
	update_stopPressed:
		LOAD R0 %01                         ;Read input of the Start/Stop button										
		AND  R0 R1							;Select the relevant input bit	
		BEQ  input_end			        	;If 0, jump to 
		                                    ;update_button_set_zero, to 
											;store the state
		AND  R0 R2							;Select the relevant bit of the
                                            ;previous state
		BNE  input_end						;If previous state already pressed, do nothing
		LOAD R0 1							;Set stopPressed to true
		STOR R0 [GB+stopPressed]		
	input_end:
		STOR R2 [GB+previousInput]			;Store previous inputs
		RTS
	
	;Counter in R3, R2 is the output word that we are building, R1 has the outputs word, R0 used
	;as temporary variable for computations and comparisons.
	set_outputs_pwm:
		LOAD R3 [GB+counter]		;Load the counter into R0
		ADD  R3 10                  ;Increment counter by 10
		CMP  R3 100                 ;Check if counter is equal to 100
		BNE  set_outputs_pwm_con
		LOAD R3 0                   ;If counter is 100 reset to 0
	set_outputs_pwm_con:
		STOR R3 [GB+counter]        ;Store new counter value
		LOAD R2 0                   ;Set R2 initially to 0
		LOAD R1 [GB+outputs]		;Load outputs array in R1
		LOAD R0 %01					
		AND  R0 R1					;Check if first bit of outputs is set
		BEQ  set_outputs_pwm_2		;If not continue to next
		CMP  R3 ARMSTRENGTH			;Compare strength to counter
		BLE  set_outputs_pwm_2      ;If strength <= counter do nothing
		OR   R2 %01                 ;If strength > counter set corresponding output bit
	set_outputs_pwm_2:
		LOAD R0 %010
		AND  R0 R1					;Check if second bit of outputs array is set
		BEQ  set_outputs_pwm_3		;If not, continue to next
		CMP  R3 CONVEYORSTRENGTH	;Compare strength to counter
		BLE  set_outputs_pwm_3		;If strength <= counter do nothing
		OR   R2 %010				;If strength > counter set corresponding output bit
	set_outputs_pwm_3:
		LOAD R0 %0100
		AND  R0 R1
		BEQ  set_outputs_pwm_4
		CMP  R3 BUCKETSSTRENGTH		;compare strength to counter
		BLE  set_outputs_pwm_4		;If strength <= counter do nothing
		OR   R2 %0100				;if strength > counter set corresponding output bit
	set_outputs_pwm_4:
		LOAD R0 %01000
		AND  R0 R1
		BEQ  set_outputs_pwm_5
		CMP  R3 COLORSTRENGTH		;Compare brightness to counter
		BLE  set_outputs_pwm_5		;If brightness <= counter do nothing
		OR   R2 %01000				;If brightness > counter set corresponding output bit
	set_outputs_pwm_5:
		LOAD R0 %010000
		AND  R0 R1
		BEQ  set_outputs_pwm_6
		CMP  R3 POSITIONSTRENGTH	;Compare brightness to counter
		BLE  set_outputs_pwm_6		;If brightness <= counter do nothing
		OR   R2 %010000				;If brightness > counter set corresponding output bit
	set_outputs_pwm_6:
		LOAD R0 %0100000
		AND  R0 R1
		BEQ  set_outputs_pwm_end
		CMP  R3 POSITIONSTRENGTH	;Compare brightness to counter
		BLE  set_outputs_pwm_end	;If brightness <= counter do nothing
		OR   R2 %0100000			;If brightness > counter set corresponding output bit
	set_outputs_pwm_end:
		STOR R2 [R5+OUTPUT]		;Update the LEDS and motors
		RTS
		
	activate_display:
		LOAD R2 [GB+displayCounter]	;Load the display counter into R1
		CMP  R2 0					;Compare display counter to zero
		BNE  activate_display_d2	;If display counter is not zero, branch away
		LOAD R0 [GB+black]			;Load number of black disks sorted in R0
		MOD  R0 10					;Take that number modulo ten (to get rightmost digit)
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01					;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d2 :
		CMP R2 1					;Compare display counter to 1
		BNE activate_display_d3		;If display counter is not 1, branch away
		LOAD R0 [GB+black]			;Load number of black disks sorted in R0
		DIV R0 10					;Divide number of black disks sorted by ten (to get second digit)
		BRS Hex7Seg					;Convert to corresponding segment code
		STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d3 :
		CMP R2 2					;Compare display counter to 2
		BNE activate_display_d4		;If display counter is not 2, branch away
		LOAD R0 [GB+stateDisplay]	;Load state display in R0
		MOD R0 10					;Take that number modulo ten (to get rightmost digit)
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d4 :
		CMP R2 3					;Compare display counter to 3
		BNE activate_display_d5		;If display counter is not 3, branch away
		LOAD R0 [GB+stateDisplay]	;Load state display in R0
		DIV R0 10					;Divide that number by 10
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d5 :
		CMP R2 4					;Compare display counter to 4
		BNE activate_display_d6		;If display counter is not 4, branch away
		LOAD R0 [GB+white]			;Load number of white disks sorted in R0
		MOD R0 10					;Take that number modulo ten (to get rightmost digit)
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01000000			;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d6 :
		LOAD R0 [GB+white]			;Load number of white disks sorted in R0
		DIV R0 10					;Divide that number by 10
		BRS  Hex7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010000000			;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
	activate_display_end :
		ADD  R2 1					;Increment it
		MOD  R2 6					;Take it modulo six
		STOR R2 [GB+displayCounter]	;Store the updated display counter
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
			