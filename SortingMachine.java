
/**
 * @author s137910
 */
public class SortingMachine {
    boolean Abort;          //Stores the current value of the abort button.
    boolean StartStop;      //Stores the current value of the Start/stop button.
    boolean StopPressed;    //Remembers whether start/stop has been pressed so 
                            //the program will halt on the next cycle.
    boolean ColorWhite;     //Remebers if the color white has been detected.
    
    /**
     * For each motor, store the current strength of output for the 
     * motor in an int.                       
     */
    int ConveyorBelt;       
    int RotatingBuckets;   
    int LoadingArm;         
    /**
     *Stores an int for the current strength of output for the LED.
     */
    int ColorLED;          
    int PositionDetectorLED;
    int RotatingBucketsLED;
    
    boolean WhiteBucketFront;     //Holds the current position of the panel in 
                                  //front of the bucket.
    int Black;      //Holds the current amount of sorted black disks.
    int White;      //Holds the current amount of sorted white disks.
    int StateDisplay;  //Holds an int corresponding to a state.
    /**
     * Hold the current values of the different sensors in the system.
     */
    boolean LoadingArmPS;
    boolean PositionDetectorSensor;
    boolean RotatingBucketsSensor;
    boolean ColorSensor;
    int Clock1;        //Clock regulating timed actions in the program.
    int previousInput; //Holds the previous input.
    int counter;       //Counter used in the interrupt.
    int DisplayCounter; //Counter used in settinf the display LEDs.
    
    /**
     * Every method represents a state the machine can be in, and will under 
     * certain conditions update different variables and jump to another state
     * by calling the method corresponding to that state. 
     */
    void RestingState(){
        while(true){
            if(Abort == true){
                Abort99State();
            }
            if(StartStop == true){
                LoadingArm = 80;
                StateDisplay = 1;
                Running01State();
            }
    }    
    }
    
    void Abort99State(){
        LoadingArm = 0;
        RotatingBuckets = 0;
        RotatingBucketsLED =0;
        ConveyorBelt = 0;
        ColorLED = 0;
        PositionDetectorLED = 0;
        StateDisplay = 98;
        Abort = false;
        Abort98State();
        
    }
    
    void Abort98State(){
        
        while(true){
            if(StartStop==true){
                StateDisplay = 97;
                Initialize97State();
            }
        }
    }
    
    void Initialize97State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(LoadingArm == 0){
                LoadingArm = 80;
            }
            if(LoadingArm == 80 && LoadingArmPS == true){
                StateDisplay = 96;
                Initialize96State();
            }
        }
    }
    
    void Initialize96State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(LoadingArmPS == false){
                LoadingArm = 0;
                RotatingBucketsLED = 80;
                Clock1 = 0;
                StateDisplay = 95;
                Initialize95State();
                
            }
            
        }
    }
    
     void Initialize95State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(Clock1 >= 1){
                RotatingBuckets = 80;
                StateDisplay = 94;
                Initialize94State();
                
            }
            
        }
    }
     
     void Initialize94State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(RotatingBucketsSensor == false){
                RotatingBuckets = 0;
                RotatingBucketsLED = 0;
                WhiteBucketFront = true;
                StateDisplay = 0;
                RestingState();
                
            }
            
        }
    }
     void Running01State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(LoadingArmPS == true){
                StopPressed = false;
                StateDisplay = 2;
                Running02State();
            }
        }
     }
     void Running02State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(LoadingArmPS == false) {
                Clock1 = 0;
                ConveyorBelt = 80;
                ColorLED = 80;
                PositionDetectorLED = 80;
                LoadingArm = 00;
                ColorWhite = false;
                StateDisplay = 3;
                Running03State();
                        }
        }
     }
      void Running03State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(ColorSensor == true) {
                ColorWhite = true;
            }
            if(Clock1 >= 500){
                ConveyorBelt = 0;
                ColorLED = 0;
                PositionDetectorLED = 0;
                StateDisplay = 0;
                RestingState();
            }
            if(PositionDetectorSensor == true){
                ConveyorBelt = 0;
                ColorLED = 0;
                PositionDetectorLED = 0;
                StateDisplay = 4;
                Running04State();
            }
            }
      }
       void Running04State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(ColorWhite == true && WhiteBucketFront == false){
              RotatingBucketsLED = 80;
              Clock1 = 0;
              StateDisplay = 5;
              Running05State();
            }
            if(ColorWhite == true && WhiteBucketFront == true){
                White++;
                StateDisplay = 8;
                Running08State();
            }
            if(ColorWhite == false && WhiteBucketFront == false){
                Black++;
                StateDisplay = 8;
                Running08State();
            }
            if(ColorWhite == false && WhiteBucketFront == true){
                RotatingBuckets = 80;
                Clock1 = 0;
                StateDisplay = 7;
                Running07State();
            }   
        }
       }
       void Running05State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(Clock1 >= 1){
                RotatingBuckets = 80;
                StateDisplay = 6;
                Running06State();
            }
        }
       }
       void Running06State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(RotatingBucketsSensor == false){
                RotatingBuckets = 00;
                RotatingBucketsLED = 00;
                WhiteBucketFront = true;
                White++;
                StateDisplay = 8;
                Running08State();
            }
        }
       }
       void Running07State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(Clock1 >= 40){
                WhiteBucketFront = false;
                RotatingBuckets = 00;
                Black++;
                StateDisplay = 8;
                Running08State();
            }
        }
       }
       void Running08State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            Clock1 =0;
            ConveyorBelt = 80;
            PositionDetectorLED = 80;
            StateDisplay = 9;
            Running09State();
        }
       }
       void Running09State(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }

            if(StopPressed == true) {
                ConveyorBelt = 00;
                PositionDetectorLED = 00;
                StateDisplay = 0;
                RestingState();
            }
            if(StopPressed == false) {
                ConveyorBelt = 00;
                LoadingArm = 80;
                PositionDetectorLED = 00;
                StateDisplay = 1;
                Running01State();
            }
        }
       }
       // This is the interrupt service of our program.
       // The method will be called once every millisecond.
    void interrupt(){                  
        while(true){
            int input = Read_Input();  //simulates reading the input as a binary number.
            
             //Isolates the second bit of the input and checks if it moved 
            //from an unpressed to a pressed state.
            if ((previousInput & 1) == 0) {      
                if ((input & 1) != 0) {
                    StartStop = true;
                    StopPressed = true;
                }
            } else {
                StartStop = false;
            }
           
            //Isolates the second bit of the input and checks if it moved
            //from an unpressed to a pressed state.
            if ((previousInput & (1 << 1)) == 0) {  
                if ((input & (1 << 1)) != 0) {
                    Abort = true;
                }
            } else{
                Abort = false;
            }
            
            /**
             * For each input from 2 to 5, isolate the corresponding bit, and, 
             * if the signal is high, set the corresponding boolean to true, 
             * otherwise, set it to false.
             */
            if ((input & (1 << 2)) != 0) {    
                ColorSensor = true;
            }else{
                ColorSensor = false;
            }
            if ((input & (1 << 3)) != 0) {
                PositionDetectorSensor = true;
            }else{
                PositionDetectorSensor = false;
            }
            if ((input & (1 << 4)) != 0) {
                RotatingBucketsSensor = true;
            }else{
                RotatingBucketsSensor = false;
            }
            if ((input & (1 << 5)) != 0) {
               LoadingArmPS = true;
            }else{
               LoadingArmPS = false;
            }
            
            previousInput = input;
            
           Clock1++;
           Set_Output_PWM();
           SetDisplayLED();
           
           Sleep(1); //The interrupt is executed once every milisecond.
        }
    }
    
    /**
     * Controls output according to the PWM principle.
     */
    void Set_Output_PWM(){       
        int output = 0;       //This is the word that represents the output.
        counter = counter + 10;
        if (counter == 100) {  //Once counter reaches 100, reset back to 0.
            counter = 0;
        }
        
        /**
         * Check the output strength setting of each output.
         * If the current value of the counter is lower than the brightness, the
         * appropriate bit is flipped so that the corresponding output is high.
         */
        
        if (LoadingArm <= counter) {
            output = output ^ (1<<0);
        }
        if (ConveyorBelt <= counter) {
            output = output ^ (1<<1);
        }
        if (RotatingBuckets <= counter) {
            output = output ^ (1<<2);
        }
        if (ColorLED <= counter) {
            output = output ^ (1<<3);
        }
        if (PositionDetectorLED <= counter) {
            output = output ^ (1<<4);
        }
        if (RotatingBucketsLED <= counter) {
            output = output ^ (1<<5);
        }
        
        
        storeOutput(output);
    }
    /**
     * This method sets the correct numbers to the LED display on the PP2.
     * The method SetDisplay() sets the numbers to the LEDs on the PP2, but can
     * not be replicated in Java.
     */
    void SetDisplayLED(){
        if(DisplayCounter == 0){
            SetDisplay(0, Black % 10);
        }
        if(DisplayCounter == 1){
            SetDisplay(1, (Black / 10));
        }
        if(DisplayCounter == 2){
            SetDisplay(2, (StateDisplay % 10));
        }
        if(DisplayCounter == 3){
            SetDisplay(3, (StateDisplay / 10));
        }
        if(DisplayCounter == 4){
            SetDisplay(4, (White % 10));
        }
        if(DisplayCounter == 5){
            SetDisplay(5, (White / 10));
        }
        
        DisplayCounter++;
        DisplayCounter = DisplayCounter % 6;
    }
       
    void storeOutput(int output) {
        //Simulates storing a word in the output position of PP2 storage (there
        // is no java equivalent).
    }
    public static void main(String[] args) {
      new  SortingMachine().Initialize97State();
    }
    
}
