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
    black                   DW 0;number of black disks detected so far
    white                   DW 0;number of white disks detected so far
    stateDisplay            DW 0;number tracking current state
    loadingArmPS            DW 0;boolean, true if loading arm sensor is high
    positionDetectorSensor  DW 0;boolean, true if position detector sensor is high
    rotatingBucketsSensor   DW 0;boolean, true if rotating buckets sensor is high
    colorSensor             DW 0;boolean, true if color sensor 
    clock                   DW 0;an integer counting up once every interrupt
    previousInput           DW 0;variable containing previous input
    counter                 DW 0;counter tracking PWM cycles
    displayCounter          DW 0;counter used in tracking previous display segment activated
	index					DW 0;counter deciding which index a display digit should present
	counter2 				DW 0;counter tracking message movement cycles
	arrayGrats				DW 0, 0, 0, 0, 0, 0, 3, 15, 14, 7, 18, 1, 20, 21, 12, 1, 20, 9, 15, 14, 19, 0, 25, 15, 21, 0, 8, 1, 22, 5, 0, 19, 15, 18, 20, 5, 4, 0, 27, 28, 0, 4, 9, 19, 3, 19, 0, 0, 0, 0, 0, 0;
							;array containing all number values of the letters in our congratulations message.
    arrayLoad				DW 0, 0, 0, 0, 0, 0, 19, 20, 1, 18, 20, 0, 12, 15, 1, 4, 9, 14, 7, 0, 4, 9, 19, 3, 19, 0, 0, 0, 0, 0, 0;
							;array containing all number values of the letters in our ready to load message.
	showCongrats            DW 0;boolean, true if congratulations-message should be shown
	showLoad				DW 0;boolean, true if start-loading-message should be shown
	
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
	CONVEYORSTRENGTH EQU   40   ;  PWM strength of the conveyor belt motor when it's on
	BUCKETSSTRENGTH  EQU   80   ;  PWM strength of the rotating buckets motor when it's on
	ARMSTRENGTH      EQU   30   ;  PWM strength of the loading arm motor when it's on
	LEDSTRENGTH      EQU   100  ;  brightness of the a LED when it's on
	TIMER_INTR_ADDR  EQU   16   ;  internal address of timer interrupt
    TIMER_DELTA      EQU   10   ;  wait time of timer interrupt
	TIMERBUCKETS	 EQU   420  ;  time it takes for a 180 degree turn of the buckets
	TIMERLED		 EQU   200  ;  time the LED will be on before we expect the corresponding sensor to show high output
	TIMERFIN		 EQU   750  ;  time within which a disk needs to be detected, if not, the machine will halt
	GRATSLENGTH		 EQU   52   ;  length of gratsArray
	LOADLENGTH       EQU   31   ;  length of loadArray
	
   program_initialization :
			LOAD R0  timer_interrupt         ;Retrieve relative interrupt  
			                                 ;location
			ADD  R0  R5                      ;Add the address of program
			LOAD R1  TIMER_INTR_ADDR         ;Load address of the timer into R1
			STOR R0  [R1]                    ;Store the interrupt location 
			                                 ;at the timer interrupt location
			LOAD R5  IOAREA                  ;Load address of IOAREA into R5
			LOAD R0  0	                     
			SUB  R0  [R5+TIMER]              ;Calculate delta time
			STOR R0  [R5+TIMER]              ;Set timer to 0
			SETI 8                           ;Enable timer interrupt
			BRA initialize_97	
	
	resting_state :               ;Begin resting state 
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_00_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_00_end :             ;
		LOAD R0 [GB+startStop]    ;Load the startStop boolean
		BEQ if_guard_00_end       ;If false, do nothing
		LOAD R0 ARMSTRENGTH       ;                  
		STOR R0 [GB+loadingArm]   ;Set loadingArm to ARMSTRENGTH 
		LOAD R0 0                 ;
		STOR R0 [GB+showLoad]	  ;Set showLoad to false
		STOR R0 [GB+showCongrats] ;Set showCongrats to false
		STOR R0 [GB+stopPressed]  ;Set stopPressed to false
		LOAD R0 1                  
		STOR R0 [GB+stateDisplay] ;Update the stateDisplay to 1
		BRA running_01            ;Branch to the next state
	if_guard_00_end :
	    BRA resting_state         ;Loop until a guard is true
	
	running_01:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_01_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_01_end :             ;
		LOAD R0 [GB+loadingArmPS] ;Load the Loading Arm Pressure Sensor boolean
		BEQ  if_guard_01_end	  ;If false, do nothing
		LOAD R0 2				  ;
		STOR R0 [GB+stateDisplay] ;Update stateDisplay to 2
		BRA running_02			  ;Branch to the next state
	if_guard_01_end:
		BRA running_01			  ;Loop until a guard is true
	
    running_02:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_02_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_02_end :             ;
		LOAD R0 [GB+loadingArmPS] ;Load Loading Arm Pressure Sensor boolean
		BNE  if_guard_02_end      ;If true, branch away, if false execute body
		LOAD R0 0
		STOR R0 [GB+loadingArm]	  ;Turn off Loading Arm motor
		STOR R0 [GB+colorWhite]   ;Set colorWhite to false
		STOR R0 [GB+clock]		  ;Reset clock
		LOAD R0	CONVEYORSTRENGTH  ;
		STOR R0 [GB+conveyorBelt] ;Turn on the conveyor belt motor
		LOAD R0	LEDSTRENGTH
		STOR R0 [GB+colorLED]	  ;Turn on the colorLED
		STOR R0 [GB+positionDetectorLED] ;Turn on the position detector LED
	    LOAD R0	3
		STOR R0 [GB+stateDisplay] ;Update stateDisplay to 3
		BRA running_03			  ;Branch to next state
	if_guard_02_end:
		BRA running_02			  ;Loop until a guard is true
    
	running_03:
		LOAD R0 [GB+abort]        ;Load the abort boolean
		BEQ if_abort_03_end       ;If false, do nothing
		BRA abort_99              ;If true, branch to abort_99
	if_abort_03_end :             ;
		LOAD R0 [GB+colorSensor]  ;Load colorSensor boolean
		BEQ  if_guard_03_01_end   ;If false, go to next guard
		LOAD R0 1
		STOR R0 [GB+colorWhite]   ;If true, set colorWhite to true
	if_guard_03_01_end:
		LOAD R0 [GB+clock]		  ;Load the value of the clock
		CMP  R0 TIMERFIN		  ;Compare it to TIMERFIN
		BLT  if_guard_03_02_end   ;Branch if clock is less than TIMERFIN
		LOAD R0	0				  ;If no disk has been detected before TIMERFIN:
		STOR R0 [GB+conveyorBelt] ;Turn off conveyor belt motor
		STOR R0 [GB+colorLED]     ;Turn off color LED
		STOR R0 [GB+positionDetectorLED] ;Turn off position detector LED
		STOR R0 [GB+stateDisplay] ;Update stateDisplay to zero
		STOR R0 [GB+index]		  ;Reset index
		LOAD R0 1
		STOR R0 [GB+showCongrats] ;Set congratulations-message boolean to true
		BRA  resting_state		  ;Branch to Resting state
    if_guard_03_02_end:			  ;
		CMP  R0 TIMERLED		  ;Compare clock to TIMERLED
		BLT  if_guard_03_03_end   ;If clock is smaller than TIMERLED, stay in State 3
		LOAD R0	[GB+positionDetectorSensor] ;If not, Load Position Detector Sensor boolean
		BNE  if_guard_03_03_end	  ;If false, execute body, if true, stay in State 3
		LOAD R0	0
		STOR R0 [GB+conveyorBelt] ;Turn off conveyor belt motor
		STOR R0 [GB+colorLED]	  ;Turn off color LED
		STOR R0 [GB+positionDetectorLED] ;Turn off Position Detector LED
		LOAD R0 4
		STOR R0 [GB+stateDisplay] ;Update stateDisplay to 4
		BRA  running_04			  ;Branch to next state
	if_guard_03_03_end:
		BRA running_03			  ;Loop until a guard is true
		
	running_04:
		LOAD R0 [GB+abort]        	;Load the abort boolean
		BEQ if_abort_04_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_04_end:
		LOAD R0 [GB+colorWhite]   	;Load colorWhite
		BEQ  if_guard_04_02_end   	;If false, branch to  next guard 
		LOAD R0 [GB+whiteBucketFront] ;Load WhiteBucketFront
		BNE  if_guard_04_01_end 	;If true, branch to next guard
		LOAD R0 LEDSTRENGTH  		;So when the color is white and the black bucket is up front:
		STOR R0 [GB+rotatingBucketsLED] ;Turn on the Rotating Buckets LED
		LOAD R0 BUCKETSSTRENGTH
		STOR R0 [GB+rotatingBuckets] ;Turn on the Rotating Buckets motor
        LOAD R0 0
		STOR R0 [GB+clock]			;Reset clock
		LOAD R0 5
		STOR R0 [GB+stateDisplay]	;Update stateDisplay to 5
		BRA  running_05				;Branch to state 5
	if_guard_04_01_end:				;You end up here when the color is white and the white bucket is up front		
		LOAD R0 [GB+white]			;Load white
		ADD	 R0 1					;Increment it
		STOR R0 [GB+white]			;Store white
		LOAD R0 8
		STOR R0 [GB+stateDisplay]	;Update stateDisplay to 8
		BRA  running_08				;Branch to state 8
	if_guard_04_02_end:				;Here you know that the disk is black
		LOAD R0 [GB+whiteBucketFront] ;Load WhiteBucketFront
		BNE  if_guard_04_03_end		;If true, branch to next guard
		LOAD R0 [GB+black]			;Load black
		ADD	 R0 1					;Increment it
		STOR R0 [GB+black]			;Store black
		LOAD R0 8
		STOR R0 [GB+stateDisplay]	;Update stateDisplay to 8
		BRA  running_08				;Branch to state 8
	if_guard_04_03_end:				;Here you know that the color is black, but the white bucket is up front
		LOAD R0 BUCKETSSTRENGTH
		STOR R0 [GB+rotatingBuckets] ;Turn on the Rotating Buckets motor
        LOAD R0 0
		STOR R0 [GB+clock]			;Reset clock
		LOAD R0 7					
		STOR R0 [GB+stateDisplay]	;Update stateDisplay to 7
		BRA  running_07				;Branch to state 7
	;For this state we do not have an infinite loop, since one of the guards is always true
	
	running_05:
		LOAD R0 [GB+abort]        	;Load the abort boolean
		BEQ if_abort_05_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_05_end:
		LOAD R0 [GB+clock]			;Load clock
		CMP  R0 TIMERLED			;Compare it to TIMERLED
		BLT  if_guard_05_end		;If the clock is less than TIMERLED, stay in state 5
	   	LOAD R0 6
		STOR R0 [GB+stateDisplay]   ;If not, update stateDisplay
		BRA  running_06				;And branch to state 6
	if_guard_05_end:
		BRA	 running_05				;Loop until a guard is true
	
	running_06:
		LOAD R0 [GB+abort]        	;Load the abort boolean
		BEQ if_abort_06_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_06_end:
		LOAD R0 [GB+rotatingBucketsSensor] ;Load Rotating Buckets Sensor boolean
		BNE  if_guard_06_end		;If false, execute body
		LOAD R0 0
		STOR R0 [GB+rotatingBuckets] 	;Turn off Rotating Buckets motor
		STOR R0 [GB+rotatingBucketsLED] ;Turn off Rotating Buckets LED
		LOAD R0 1
		STOR R0 [GB+whiteBucketFront]	;Set whiteBucketFront to true
		LOAD R0 [GB+white]				;Load white
		ADD  R0 1						;Increment it
		STOR R0 [GB+white]				;Store white
		LOAD R0 8
		STOR R0 [GB+stateDisplay]		;Update stateDisplay to 8
		BRA  running_08					;Branch to state 8
	if_guard_06_end:
		BRA  running_06					;Loop until a guard is true
	
	running_07:
		LOAD R0 [GB+abort]        	;Load the abort boolean
		BEQ if_abort_07_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_07_end:
		LOAD R0 [GB+clock]			;Load clock
		CMP  R0 TIMERBUCKETS		;Compare it to TIMERBUCKETS
		BLT  if_guard_07_end		;If clock is less than TIMERBUCKETS, branch to end of state 7
		LOAD R0 0
		STOR R0 [GB+whiteBucketFront] ;Else, set WhiteBucketFront to false
		STOR R0 [GB+rotatingBuckets]  ;Turn off the Rotating Buckets motor
		LOAD R0 [GB+black]			;Load black
		ADD  R0 1					;Increment it
		STOR R0 [GB+black]			;Store black
	    LOAD R0 8
		STOR R0 [GB+stateDisplay]	;Update stateDisplay to 8
		BRA  running_08				;Branch to state 8
	if_guard_07_end:
		BRA  running_07				;Loop until a guard is true
		
	running_08:
		LOAD R0 [GB+abort]        	;Load the abort boolean
		BEQ if_abort_08_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_08_end:
		LOAD R0 0					
		STOR R0 [GB+clock]			;Reset clock
		LOAD R0 CONVEYORSTRENGTH
		STOR R0 [GB+conveyorBelt]	;Turn on the conveyor belt motor
		LOAD R0 LEDSTRENGTH
		STOR R0 [GB+positionDetectorLED] ;Turn on the position detector LED
		LOAD R0 9
		STOR R0 [GB+stateDisplay]	;Update stateDisplay to 9
		BRA  running_09				;Branch to state 9
	;This state also does not have an infinite loop, because it doesn't have any guards
	
	running_09:
		LOAD R0 [GB+abort]        	;Load the abort boolean
		BEQ if_abort_09_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_09_end:
		LOAD R0 [GB+positionDetectorSensor] ;Load the Position Detector Sensor
		BEQ  running_09_02_end		;If false, go to the far end of state 9
		LOAD R0 [GB+stopPressed] 	;Load the StopPressed boolean
		BEQ  if_guard_09_01_end		;If false, branch to next guard
		LOAD R0 0
		STOR R0 [GB+conveyorBelt] 	;Turn off the conveyor belt motor
		STOR R0 [GB+positionDetectorLED] ;Turn off the Position Detector LED
		STOR R0 [GB+stateDisplay]	;Update the stateDisplay to 0.
		STOR R0 [GB+index]			;Reset index
		LOAD R0 1
		STOR R0 [GB+showCongrats]	;Set congratulations-message boolean to true
		BRA  resting_state			;Branch to the resting state
	if_guard_09_01_end:				;When Position Detector Sensor is true and
	    LOAD R0 0					;stopPressed is false, do:
		STOR R0 [GB+conveyorBelt]	;Turn off the conveyor belt motor
		STOR R0 [GB+positionDetectorLED] ;Turn off the Position Detector LED
		LOAD R0 ARMSTRENGTH
		STOR R0 [GB+loadingArm]		;Turn on Loading Arm motor
		LOAD R0 1
		STOR R0 [GB+stateDisplay]	;Update the stateDisplay to 1
        BRA  running_01				;Branch to state 1, start a new cycle
    if_guard_09_02_end:
		BRA running_09				;Loop until a guard is true
	
	;The Abort state 99 turns off all motors and LEDs
	;It also sets abort and both message booleans to false
	abort_99:
		LOAD R0 0
		STOR R0 [GB+loadingArm]
		STOR R0 [GB+rotatingBuckets]
		STOR R0 [GB+conveyorBelt]
   		STOR R0 [GB+colorLED]
		STOR R0 [GB+positionDetectorLED]
		STOR R0 [GB+rotatingBucketsLED]
		STOR R0 [GB+showLoad]
		STOR R0 [GB+showCongrats]
		STOR R0 [GB+abort]
		LOAD R0 98					
		STOR R0 [GB+stateDisplay]	;Update stateDisplay to 98
		BRA  abort_98				;Branch to state 98
		
	abort_98:
		LOAD R0 [GB+startStop] 		;Load startStop
		BEQ  if_guard_98_end		;If false, stay in state 98
		LOAD R0 97					;If true,
		STOR R0 [GB+stateDisplay]	;Update stateDisplay to 97
		BRA  initialize_97			;Branch to the first initialize state, state 97
	if_guard_98_end:
		BRA  abort_98				;Loop until a guard is true
		
	initialize_97:
	    LOAD R0 [GB+abort] 			;Load the abort boolean
		BEQ if_abort_97_end     	;If false, do nothing
		BRA abort_99            	;If true, branch to abort_99
	if_abort_97_end:
		LOAD R0 [GB+loadingArm]		;Load Loading Arm motor value
		CMP R0 0
		BNE if_guard_97_01_end		;If it's on, branch to next guard
		LOAD R0 ARMSTRENGTH			;If it's off,
		STOR R0 [GB+loadingArm]		;Turn it on.
	if_guard_97_01_end:
		LOAD R0 [GB+loadingArmPS] 	;Load the boolean of the Loading Arm Pressure Sensor
		BEQ  if_guard_97_02_end		;If it's false, branch to the end of the state
		LOAD R0 96					;If it's true,
		STOR R0 [GB+stateDisplay]	;Update stateDisplay to 96
		BRA  initialize_96			;Branch to state 96
	if_guard_97_02_end:
		BRA  initialize_97			;Loop until a guard is true
		
	initialize_96:
		LOAD R0 [GB+abort]        	;Load the abort boolean
		BEQ if_abort_96_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_96_end:
		LOAD R0 [GB+loadingArmPS]	;Load the Loading Arm Pressure Sensor boolean
		BNE  if_guard_96_end		;If it's still true, branch to the end of this state
		LOAD R0 0					;If it's now false:
		STOR R0 [GB+loadingArm]		;Turn off the Loading Arm motor
		STOR R0 [GB+clock]			;Reset the clock
		LOAD R0 LEDSTRENGTH
		STOR R0 [GB+rotatingBucketsLED] ;Turn on the Rotating Buckets LED
		LOAD R0 95
		STOR R0 [GB+stateDisplay]	;Update the stateDisplay to 95
		BRA  initialize_95			;Branch to state 95
    if_guard_96_end:
	    BRA  initialize_96			;Loop until a guard is true
		
	initialize_95:
	    LOAD R0 [GB+abort]        	;Load the abort boolean
		BEQ if_abort_95_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_95_end:	
		LOAD R0 [GB+clock]			;Load the clock
		CMP  R0 TIMERLED			;Compare it to TIMERLED
		BLT  if_guard_95_end		;If it's less than TIMERLED, branch to the end of this state
		LOAD R0 BUCKETSSTRENGTH		;Else:
		STOR R0 [GB+rotatingBuckets] ;Turn on the Rotating Buckets motor
		LOAD R0 94
		STOR R0 [GB+stateDisplay]	;Update the stateDisplay to 94
		BRA  initialize_94			;Branch to state 94
	if_guard_95_end:
		BRA initialize_95			;Loop until a guard is true
		
	initialize_94:
		LOAD R0 [GB+abort]        	;Load the abort boolean
		BEQ if_abort_94_end       	;If false, do nothing
		BRA abort_99              	;If true, branch to abort_99
	if_abort_94_end:
		LOAD R0 [GB+rotatingBucketsSensor] ;Load the Rotating Buckets Sensor boolean
		BNE  if_guard_94_end		;If it's true, branch to the end of the state
		LOAD R0 0					;If it's false:
		STOR R0 [GB+index]			;Reset index
		STOR R0 [GB+rotatingBuckets]	;Turn off the Rotating Buckets motor
		STOR R0 [GB+rotatingBucketsLED]	;Turn off the Rotating Buckets LED
		STOR R0 [GB+stateDisplay]	;Update the stateDisplay to 0
		LOAD R0 1
		STOR R0 [GB+showLoad]			;Set the showLoad boolean to true
		STOR R0 [GB+whiteBucketFront] 	;Set the WhiteBucketFront boolean to true
		BRA  resting_state				;Branch to the Resting State
	if_guard_94_end:
		BRA initialize_94			;Loop until a guard is true
	
		
    ;Timer interrupt service routine	
	timer_interrupt:
		BRS set_outputs_pwm			;Set the outputs via the subroutine
		BRS read_inputs				;Read the inputs via the subroutine
		LOAD R0 [GB+showCongrats]	;Load the showCongrats boolean
		BEQ dont_show_congrats		;If it's false, skip next two lines
		BRS activate_congrats_display ;If true, show the Congratulations message via the subroutine
		BRA dont_show_counters		;No other display message should be shown, so branch to end of interrupt
	dont_show_congrats:		
		LOAD R0 [GB+showLoad]		;Load the showLoad boolean
		BEQ dont_show_load			;If it's false, skip the next two lines
		BRS activate_load_display	;If true, show the Start-loading message via the subroutine
		BRA dont_show_counters		;No regular display should be shown, so skip next two lines.
	dont_show_load:				;When both display messages should not be displayed,
		BRS activate_display	;we should display the regular display (white, state, black), with the subroutine
	dont_show_counters:
		LOAD R0 20            ;Schedule new interrupt
		STOR R0 [R5+TIMER]    ;Add 20 to the timer
		LOAD R0 [GB+clock]	  ;Load clock
		ADD  R0 			  ;Increment it
		STOR R0 [GB+clock]	  ;Store clock
		SETI 8                ;Enable interrupt
		RTE
	
	read_inputs:
		LOAD R2 [R5+INPUT]			;Load input bits into R2
		LOAD R0 %010000000			;The 7th bit represents the clear button
		AND  R0 R2					;R0 becomes 1 if the input has a one at the 7th bit
		BEQ update_startStop		;If R0 is 0, we branch to update_startStop
		LOAD R1 [GB+previousInput]	;Load the previous input in R1
		AND  R0 R1					;See if the clear button was already pressed,
		BNE  update_startStop		;If it was true already, branch to update_startStop
		LOAD R0 0					;If it went from false to true:
		STOR R0 [GB+black]			;Reset black
		STOR R0 [GB+white]			;Reset white
	update_startStop:
		LOAD R0 %01					;We now take the 0th bit, representing the StartStop-button
		AND  R0 R2					;Compare it to the actual input
		BEQ  update_startStop_false ;If it's false, branch away
		LOAD R0 1					;If it's true,
		STOR R0 [GB+startStop]		;Then set the startStop boolean to true
		BRA  update_stopPressed		;Branch to the next button check
	update_startStop_false:			;If start/stop is not pressed,
		LOAD R0 0					
		STOR R0 [GB+startStop]		;Then set the startStop boolean to false.
		
	update_stopPressed:
		LOAD R0 %01                     ;Read input of the Start/Stop button										
		AND  R0 R2						;Select the relevant input bit	
		BEQ  update_button_abort        ;If 0, jump to update_button_abort
		LOAD R1 [GB+previousInput]		;Load previous input in R1
		AND  R0 R1						;Select the relevant bit of the previous input
		BNE  update_button_abort		;If the start/stop-button was pressed already, branch to update_button_abort
		LOAD R0 1						;If it went from not pressed to pressed:
		STOR R0 [GB+stopPressed]		;Set stopPressed to true
	
	update_button_abort:								
		LOAD R0 %010					;Select the first bit, representing the abort button
		AND  R0 R2						;Compare it to the actual input
		BEQ  colorSensor_check      	;If 0, jump to colorSensor_check
		LOAD R1 [GB+previousInput]		;Load previous input in R1
		AND  R0 R1						;Select the relevant bit of the previous input
		BNE  colorSensor_check			;If abort was pressed already, branch to colorSensor_check
		LOAD R0 1						;If abort first wasn't pressed and now is,
		STOR R0 [GB+abort]				;then set the abort boolean to true
               
	colorSensor_check:                      
		LOAD R0 %0100					;Select the second bit
		AND  R0 R2                      ;Compare with the input
		BEQ  colorSensor_false          ;If 0, branch to colorSensor_false
		LOAD R0 1                       ;If 1, then set
		STOR R0 [GB+colorSensor]		;the colorSensor boolean to true
		BRA  positionDetectorSensor_check   ;Branch to the next button check
	colorSensor_false:					;If false,
		LOAD R0 0						;then set the
		STOR R0 [GB+colorSensor]		;colorSensor boolean to false
		
	positionDetectorSensor_check:
		LOAD R0 %01000						;Select the third bit, representing the Position Detector Sensor
		AND  R0 R2                          ;Compare with the input
		BEQ  positionDetectorSensor_false   ;If 0, branch to positionDetectorSensor_false
		LOAD R0 1                           ;If 1, set the
		STOR R0 [GB+positionDetectorSensor] ;Position Detector Sensor boolean to true
		BRA  rotatingBucketsSensor_check	;Branch to the next button check
	positionDetectorSensor_false:			;If false,
		LOAD R0 0							;Set the Position Detector Sensor
		STOR R0 [GB+positionDetectorSensor] ;boolean to false
		
	rotatingBucketsSensor_check:
		LOAD R0 %010000						;Select the fourth bit, representing the Rotating Buckets Sensor
		AND  R0 R2                          ;Compare with the input
		BEQ  rotatingBucketsSensor_false    ;If 0, branch to rotatingBucketsSensor_false
		LOAD R0 1                           ;If 1, set the Rotating Buckets
		STOR R0 [GB+rotatingBucketsSensor]  ;Sensor boolean to true
		BRA  loadingArmPS_check				;Branch to the next button check
	rotatingBucketsSensor_false:			;If false,
		LOAD R0 0							;then set the Rotating Buckets
		STOR R0 [GB+rotatingBucketsSensor]  ;Sensor boolean to false
		
	loadingArmPS_check:
		LOAD R0 %0100000				;Select the fifth bit, representing the Loading Arm Pressure Sensor
		AND  R0 R2                      ;Compare with the input
		BEQ  loadingArmPS_false         ;If 0, branch to loadingArmPS_false
		LOAD R0 1                       ;If 1, set the Loading Arm 
		STOR R0 [GB+loadingArmPS]		;Pressure Sensor boolean to true
		BRA  input_end					;Branch to the end of the read_inputs subroutine
	loadingArmPS_false:					;If false, then
		LOAD R0 0						;set the Loading Arm Pressure
		STOR R0 [GB+loadingArmPS]		;Sensor boolean to false
	input_end:
		STOR R2 [GB+previousInput]		;Lastly, store the current input to previousInput
		RTS
	
	
	set_outputs_pwm:
		LOAD R0 [GB+counter]		;Load the counter into R0
		ADD  R0 20                  ;Increment counter by 10
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
		LOAD R1 [GB+rotatingBucketsLED]		;Load color LED brightness in R1
		CMP  R1 R0					;Compare brightness to counter
		BLE  set_outputs_pwm_5		;If brightness <= counter do nothing
		OR   R2 %01000				;If brightness > counter set corresponding output bit
	set_outputs_pwm_5:
		LOAD R1 [GB+positionDetectorLED] ;Load position detector LED brightness in R1
		CMP  R1 R0					;Compare brightness to counter
		BLE  set_outputs_pwm_6		;If brightness <= counter do nothing
		OR   R2 %010000				;If brightness > counter set corresponding output bit
	set_outputs_pwm_6:
		LOAD R1 [GB+colorLED]	;Load rotating bucket LED brightness in R1
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
		BRS  Dec7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01					;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d2 :
		CMP R1 1					;Compare display counter to 1
		BNE activate_display_d3		;If display counter is not 1, branch away
		LOAD R0 [GB+black]			;Load number of black disks sorted in R0
		DIV R0 10					;Divide number of black disks sorted by ten (to get second digit)
		BRS Dec7Seg					;Convert to corresponding segment code
		STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d3 :
		CMP R1 2					;Compare display counter to 2
		BNE activate_display_d4		;If display counter is not 2, branch away
		LOAD R0 [GB+stateDisplay]	;Load state display in R0
		MOD R0 10					;Take that number modulo ten (to get rightmost digit)
		BRS  Dec7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %0100				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d4 :
		CMP R1 3					;Compare display counter to 3
		BNE activate_display_d5		;If display counter is not 3, branch away
		LOAD R0 [GB+stateDisplay]	;Load state display in R0
		DIV R0 10					;Divide that number by 10
		BRS  Dec7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d5 :
		CMP R1 4					;Compare display counter to 4
		BNE activate_display_d6		;If display counter is not 4, branch away
		LOAD R0 [GB+white]			;Load number of white disks sorted in R0
		MOD R0 10					;Take that number modulo ten (to get rightmost digit)
		BRS  Dec7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_display_end	;Branch to end
	activate_display_d6 :
		CMP R1 5					;Compare display counter to 5
		BNE activate_display_end	;If display counter is not 5, branch away
		LOAD R0 [GB+white]			;Load number of white disks sorted in R0
		DIV R0 10					;Divide that number by 10
		BRS  Dec7Seg				;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %0100000			;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
	activate_display_end :
		LOAD R1 [GB+displayCounter]	;Load the display counter in R1
		ADD  R1 1					;Increment it
		MOD  R1 6					;Take it modulo six
		STOR R1 [GB+displayCounter]	;Store the updated display counter
		RTS
	
	activate_congrats_display:
		LOAD R1 [GB+displayCounter]	;Load the display counter into R1
		CMP  R1 0					;Compare display counter to zero
		BNE  activate_congrats_display_d2	;If display counter is not zero, branch away
		LOAD R2 [GB+index]			
		ADD  R2 arrayGrats			;Load index variable + arrayGrats + 5 in R2
		ADD  R2 5					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01					;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_congrats_display_end	;Branch to end
	activate_congrats_display_d2 :
		CMP R1 1					;Compare display counter to 1
		BNE activate_congrats_display_d3	;If display counter is not 1, branch away
		LOAD R2 [GB+index]			
		ADD  R2 arrayGrats			;Load index variable + arrayGrats + 4 in R2
		ADD  R2 4					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0
		BRS Alphabet7Seg			;Convert to corresponding segment code
		STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_congrats_display_end	;Branch to end
	activate_congrats_display_d3 :
		CMP R1 2					;Compare display counter to 2
		BNE activate_congrats_display_d4		;If display counter is not 2, branch away
		LOAD R2 [GB+index]
		ADD  R2 arrayGrats			;Load index variable + arrayGrats + 3 in R2
		ADD  R2 3					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %0100				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_congrats_display_end	;Branch to end
	activate_congrats_display_d4 :
		CMP R1 3					;Compare display counter to 3
		BNE activate_congrats_display_d5		;If display counter is not 3, branch away
		LOAD R2 [GB+index]
		ADD  R2 arrayGrats			;Load index variable + arrayGrats + 2 in R2
		ADD  R2 2					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_congrats_display_end	;Branch to end
	activate_congrats_display_d5 :
		CMP R1 4					;Compare display counter to 4
		BNE activate_congrats_display_d6		;If display counter is not 4, branch away
		LOAD R2 [GB+index]
		ADD  R2 arrayGrats			;Load index variable + arrayGrats + 1 in R2
		ADD  R2 1					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0, load in R0
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_congrats_display_end	;Branch to end
	activate_congrats_display_d6 :
		CMP R1 5					;Compare display counter to 5
		BNE activate_congrats_display_end		;If display counter is not 5, branch away
		LOAD R2 [GB+index]
		ADD  R2 arrayGrats			;Load index variable + arrayGrats in R2
		LOAD R0 [GB+R2]				;This corresponds to a position in the gratsArray
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %0100000			;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		
	activate_congrats_display_end :
		LOAD R1 [GB+displayCounter]	;Load the display counter in R1
		ADD  R1 1					;Increment it
		MOD  R1 6					;Take it modulo six
		STOR R1 [GB+displayCounter]	;Store the updated display counter
		LOAD R0 [GB+counter2]		;Load the counter into R0
		ADD  R0 1                   ;Increment counter by 1
		STOR R0 [GB+counter2]       ;Store the new value of counter
		CMP  R0 100                 ;Check if counter is equal to 100
		BNE  congrats_con			;If counter isn't 100 yet, branch away
		LOAD R0 0                   ;If counter is 100 reset to 0
		STOR R0 [GB+counter2]       ;And store it
		LOAD R0 [GB+index]          ;Every 100 counter steps: store index in R0
		ADD	 R0 1                   ;Increment it
		STOR R0 [GB+index]			;Store the new value of index
		LOAD R2 GRATSLENGTH			;Store the array length in R2
		SUB  R2 6					;Subtract 6 of it
		CMP  R2 R0					;Compare index with arraylength-6
		BNE  congrats_con			;If not zero, branch away
		LOAD R0 0					;If index is equal to arraylength-6
		STOR R0 [GB+showCongrats]	;Then make showCongrats false
		STOR R0 [GB+index]			;Reset index
congrats_con:					
		RTS

	activate_load_display:
		LOAD R1 [GB+displayCounter]	;Load the display counter into R1
		CMP  R1 0					;Compare display counter to zero
		BNE  activate_load_display_d2	;If display counter is not zero, branch away
		LOAD R2 [GB+index]			
		ADD  R2 arrayLoad			;Load index variable + arrayLoad + 5 in R2
		ADD  R2 5					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01					;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_load_display_end	;Branch to end
	activate_load_display_d2 :
		CMP R1 1					;Compare display counter to 1
		BNE activate_load_display_d3	;If display counter is not 1, branch away
		LOAD R2 [GB+index]			
		ADD  R2 arrayLoad			;Load index variable + arrayLoad + 4 in R2
		ADD  R2 4					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0
		BRS Alphabet7Seg			;Convert to corresponding segment code
		STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_load_display_end	;Branch to end
	activate_load_display_d3 :
		CMP R1 2					;Compare display counter to 2
		BNE activate_load_display_d4		;If display counter is not 2, branch away
		LOAD R2 [GB+index]
		ADD  R2 arrayLoad			;Load index variable + arrayLoad + 3 in R2
		ADD  R2 3					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %0100				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_load_display_end	;Branch to end
	activate_load_display_d4 :
		CMP R1 3					;Compare display counter to 3
		BNE activate_load_display_d5		;If display counter is not 3, branch away
		LOAD R2 [GB+index]
		ADD  R2 arrayLoad			;Load index variable + arrayLoad + 2 in R2
		ADD  R2 2					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %01000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_load_display_end	;Branch to end
	activate_load_display_d5 :
		CMP R1 4					;Compare display counter to 4
		BNE activate_load_display_d6		;If display counter is not 4, branch away
		LOAD R2 [GB+index]
		ADD  R2 arrayLoad			;Load index variable + arrayLoad + 1 in R2
		ADD  R2 1					;This corresponds to a position in the gratsArray
		LOAD R0 [GB+R2]				;Load the number at that position in R0, load in R0
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %010000				;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		BRA  activate_load_display_end	;Branch to end
	activate_load_display_d6 :
		CMP R1 5					;Compare display counter to 5
		BNE activate_load_display_end		;If display counter is not 5, branch away
		LOAD R2 [GB+index]
		ADD  R2 arrayLoad			;Load index variable + arrayLoad in R2
		LOAD R0 [GB+R2]				;This corresponds to a position in the gratsArray
		BRS  Alphabet7Seg			;Convert to corresponding segment code
	    STOR R1 [R5+DSPSEG]			;Store in DSPSEG
		LOAD R0 %0100000			;Load corresponding Display number in R0
		STOR R0 [R5+DSPDIG]			;Store in DSPDIG
		
	activate_load_display_end :
		LOAD R1 [GB+displayCounter]	;Load the display counter in R1
		ADD  R1 1					;Increment it
		MOD  R1 6					;Take it modulo six
		STOR R1 [GB+displayCounter]	;Store the updated display counter
		LOAD R0 [GB+counter2]		;Load the counter into R0
		ADD  R0 1                   ;Increment counter by 1
		STOR R0 [GB+counter2]       ;Store the new value of counter
		CMP  R0 100                 ;Check if counter is equal to 100
		BNE  load_con			;If counter isn't 100 yet, branch away
		LOAD R0 0                   ;If counter is 100 reset to 0
		STOR R0 [GB+counter2]       ;And store it
		LOAD R0 [GB+index]          ;Every 100 counter steps: store index in R0
		ADD	 R0 1                   ;Increment it
		STOR R0 [GB+index]			;Store the new value of index
		LOAD R2 LOADLENGTH			;Load the arraylength in R2
		SUB  R2 6					;Subtract six of it
		CMP  R2 R0					;Compare index with said length
		BNE  congrats_con			;If it's not zero, branch away
		LOAD R0 0					;If they are equal,
		STOR R0 [GB+showLoad]		;Make showLoad false
		STOR R0 [GB+index]			;Reset index
load_con:
		RTS
		
Alphabet7Seg     :  BRS  Alphabet7Seg_bgn  ;  push address(tbl) onto stack and proceed at "bgn"
Alphabet7Seg_tbl : 
			  CONS  %00000000    ;  7-segment pattern for space
			  CONS  %01110111    ;  7-segment pattern for 'A'
			  CONS  %00011111	 ;  7-segment pattern for 'B'
			  CONS  %01001110	 ;  7-segment pattern for 'C'
			  CONS  %00111101    ;  7-segment pattern for 'd'
			  CONS  %01001111	 ;  7-segment pattern for 'E'
			  CONS  %01000111	 ;  7-segment pattern for 'F'
			  CONS  %01111011	 ;  7-segment pattern for 'g'
			  CONS  %00110111	 ;  7-segment pattern for 'H'
			  CONS  %00110000	 ;  7-segment pattern for 'I'
			  CONS  %00111000	 ;  7-segment pattern for 'J'
			  CONS  %00000000	 ;  k isn't possible
			  CONS  %00001110	 ;  7-segment pattern for 'L'
			  CONS  %00000000	 ;  m isn't possible either
			  CONS  %01110110	 ;  7-segment pattern for 'n'
			  CONS  %01111110	 ;  7-segment pattern for 'O'
			  CONS  %01100111    ;  7-segment pattern for 'P'
			  CONS  %01110011	 ;  7-segment pattern for 'q'
			  CONS  %01000110    ;  7-segment pattern for 'r'
			  CONS  %01011011	 ;  7-segment pattern for 'S'
			  CONS  %00001111    ;  7-segment pattern for 't'
			  CONS  %00111110	 ;  7-segment pattern for 'U'
			  CONS	%00111110	 ;  7-segment pattern for 'V'
			  CONS  %00000000	 ;  w isn't possible
			  CONS  %00000000	 ;  nor is x
			  CONS  %00111011    ;  7-segment pattern for 'y'
			  CONS  %01101101	 ;  7-segment pattern for 'Z' 
Alphabet7Seg_bgn:
			  CMP   R0  27				;Compare input value to 27
			  BNE   Alphabet7Seg_28     ;If it's not 27, branch away
			  LOAD  R0  [GB+white]		;If it is, it means that we need to output the
			  ADD   R0  [GB+black]      ;first digit of the total number of discs sorted.
			  DIV   R0 10				;Add the number of black and white discs together,
			  BRS   Dec7Seg				;Divide it by ten and branch to Dec7Seg
			  ADD   SP 1				;Once returned, increment stackpointer
			  RTS						;Return
Alphabet7Seg_28:
			  CMP   R0  28				;Compare input value to 28
			  BNE   Alphabet7Seg_letters ;If it's not equal to 28, branch away
			  LOAD  R0  [GB+white]		;If it is, it means that we need to output the
			  ADD   R0  [GB+black]		;second digit of the total number of discs sorted.
			  MOD   R0 10				;Add the number of black and white discs together,
			  BRS   Dec7Seg				;Take it modulo ten and branch to Dec7Seg
			  ADD   SP 1				;Once returned, increment stackpointer
			  RTS						;Return
Alphabet7Seg_letters:			 ;  The program only comes here if a letter needs to be displayed
              LOAD  R1  [SP++]   ;  R1 := address(tbl) (retrieve from stack)
              LOAD  R1  [R1+R0]  ;  R1 := tbl[R0]
               RTS
			   
;Converts an integer to the corresponding 7-segment pattern. Number to be converted
;in R0, return value in R1.
Dec7Seg     :  BRS  Dec7Seg_bgn  ;  push address(tbl) onto stack and proceed at "bgn"
Dec7Seg_tbl : CONS  %01111110    ;  7-segment pattern for '0'
              CONS  %00110000    ;  7-segment pattern for '1'
              CONS  %01101101    ;  7-segment pattern for '2'
              CONS  %01111001    ;  7-segment pattern for '3'
              CONS  %00110011    ;  7-segment pattern for '4'
              CONS  %01011011    ;  7-segment pattern for '5'
              CONS  %01011111    ;  7-segment pattern for '6'
              CONS  %01110000    ;  7-segment pattern for '7'
              CONS  %01111111    ;  7-segment pattern for '8'
              CONS  %01111011    ;  7-segment pattern for '9'
Dec7Seg_bgn:   AND  R0  %01111   ;  R0 := R0 MOD 16 , just to be safe...
              LOAD  R1  [SP++]   ;  R1 := address(tbl) (retrieve from stack)
              LOAD  R1  [R1+R0]  ;  R1 := tbl[R0]
               RTS
			