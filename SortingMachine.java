
/**
 * @author s137910
 */
public class SortingMachine {
    boolean Abort;          //Stores the current value of the abort button.
    boolean StartStop;      //Stores the current value of the Start/stop button.
    boolean StopPressed;    //Remembers whether start/stop has been pressed so
                            //the program will halt on the next cycle.
    boolean ColorWhite;     //Remembers if the color white has been detected.

    /**
     * For each motor, store the current strength of output for the 
     * motor in an int.                       
     */
    final int CONVEYORSTRENGTH = 50;
    final int BUCKETSSTRENGTH = 80;
    final int ARMSTRENGTH = 40;

    int ConveyorBelt;
    int RotatingBuckets;   
    int LoadingArm;         
    /**
     *Stores an int for the current strength of output for the LED.
     */


    final int POSITIONSTRENGTH = 80;

    int ColorLED;          
    int PositionDetectorLED;
    int RotatingBucketsLED;
    
    boolean WhiteBucketFront;     //Holds the current position of the panel in.
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
    int Clock;        //Clock regulating timed actions in the program.
    int previousInput; //Holds the previous input.
    int counter;       //Counter used in the interrupt.
    int DisplayCounter; //Counter used in setting the display LEDs,

    /**
     * The following variables are used for the extra feature:
     */
    //Index counting what first letter of the array containing the
    //letters of our message we are displaying on the first segment.
    int index;
    int counter2;      //Counter for deciding when the message moves to the next spot.
    //Array containing the numbers corresponding to the letters of our congrats message.
    int[] arrayGrats = new {0, 0, 0, 0, 0, 0, 3, 15, 14, 7, 18, 1, 20, 21, 12, 1, 20,
            9, 15, 14, 19, 0, 25, 15, 21, 0, 8, 1, 22, 5, 0, 19, 15, 18, 20, 5, 4, 0,
            27, 28, 0, 4, 9, 19, 3, 19, 0, 0, 0, 0, 0, 0};
    //Array containing the numbers corresponding to the letters of our loading message.
    int[] arrayLoad = new {0, 0, 0, 0, 0, 0, 19, 20, 1, 18, 20, 0, 12, 15, 1, 4, 9, 14, 7,
            0, 4, 9, 19, 3, 19, 0, 0, 0, 0, 0, 0};
    boolean showCongrats;   //Boolean which is true if the Congrats message is to be displayed.
    boolean showLoad;       //Boolean which is true if the Loading message is to be displayed.


    /**
     * Every method represents a state the machine can be in, and will under 
     * certain conditions update different variables and jump to another state
     * by calling the method corresponding to that state. 
     */
    void RestingState(){
        while(true){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            if(StartStop == true){
                LoadingArm = ARMSTRENGTH;
                StopPressed = false;

                //When we start running, we show normal display
                showCongrats = false;
                showLoad = false;

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
        showCongrats = false;
        showLoad = false;
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
                LoadingArm = ARMSTRENGTH;
            }
            if(LoadingArm ==ARMSTRENGTH && LoadingArmPS == true){
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
                RotatingBucketsLED =POSITIONSTRENGTH;
                Clock = 0;
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
            if(Clock >= 1){
                RotatingBuckets =BUCKETSSTRENGTH;
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
                showLoad = true;
                index = 0;
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
                Clock = 0;
                ConveyorBelt = CONVEYORSTRENGTH;
                ColorLED = POSITIONSTRENGTH;
                PositionDetectorLED = POSITIONSTRENGTH;
                LoadingArm = 0;
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
            if(ColorSensor == true){
                ColorWhite = true;
            }
            if(Clock >= 500){
                ConveyorBelt = 0;
                ColorLED = 0;
                PositionDetectorLED = 0;
                StateDisplay = 0;

                //Enable the congrats message
                index = 0;
                showCongrats = true;

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
                RotatingBucketsLED =POSITIONSTRENGTH;
                Clock = 0;
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
                RotatingBuckets = BUCKETSSTRENGTH;
                Clock = 0;
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
            if(Clock >= 1){
                RotatingBuckets = BUCKETSSTRENGTH;
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
            if(Clock >= 40){
                WhiteBucketFront = false;
                RotatingBuckets = 00;
                Black++;
                StateDisplay = 8;
                Running08State();
            }
        }
       }
       void Running08State(){
            if(Abort == true){
                StateDisplay = 99;
                Abort99State();
            }
            Clock =0;
            ConveyorBelt = CONVEYORSTRENGTH;
            PositionDetectorLED = POSITIONSTRENGTH;
            StateDisplay = 9;
            Running09State();
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

                //Enable congrats message.
                showCongrats = true;
                index = 0;

                RestingState();
            }
            if(StopPressed == false) {
                ConveyorBelt = 00;
                LoadingArm = ARMSTRENGTH;
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

            //Isolates the seventh bit of the input and checks if it moved
            //from an unpressed to a pressed state.
            if ((previousInput & (1 << 7)) == 0) {
                if ((input &  (1 << 7)) != 0) {
                   Black = 0;
                   White = 0;
                }
            }

             //Isolates the second bit of the input and checks if it moved 
            //from an unpressed to a pressed state.
            if ((previousInput & 1) == 0) {      
                if ((input & 1) != 0) {
                    StopPressed = true;
                }
            }

            if (input & 1 != 0) {
                StartStop = true;
            } else {
                StartStop = false;
            }
            //Isolates the second bit of the input and checks if it moved
            //from an unpressed to a pressed state.
            if ((previousInput & (1 << 1)) == 0) {  
                if ((input & (1 << 1)) != 0) {
                    Abort = true;
                }
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

            Clock++;
            Set_Output_PWM();
            if (showCongrats) {
                showCongratsMessage();
            } else if (showLoad) {
                showLoadMessage();
            } else {
                SetDisplayLED();
            }
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
     * The method SetDisplay(int displaySegement, int number) sets the numbers
     * to the LEDs on the PP2, but can not be replicated in Java.
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

    /**
     * Dummy method that converts a letter to a corresponding 7-segment code. If the number passed
     * is 27 it will return the segment code of the first digit of the total number of disks, if the
     * passed number is 28 it will return the second digit.
     */
    void showLetter();

    /**
     * Method that lights up each segment in succesion every time it's called, and shows the loading message.
     */
    void showLoadMessage(){
        if(DisplayCounter == 0){
            SetDisplay(0, showLetter(arrayLoad[0+index]));
        }
        if(DisplayCounter == 1){
            SetDisplay(1, showLetter(arrayLoad[1+index]));
        }
        if(DisplayCounter == 2){
            SetDisplay(2, showLetter(arrayLoad[2+index]));
        }
        if(DisplayCounter == 3){
            SetDisplay(3, showLetter(arrayLoad[3+index]));
        }
        if(DisplayCounter == 4){
            SetDisplay(4, showLetter(arrayLoad[4+index]));
        }
        if(DisplayCounter == 5){
            SetDisplay(5, showLetter(arrayLoad[5+index]));
        }

        DisplayCounter++;
        DisplayCounter = DisplayCounter % 6;

        if (index > (arrayLoad.length - 6) {
            showLoad = false;
        }
    }

    /**
     * Method that lights up each segment in succesion every time it's called, and shows the congrats message.
     */
    void showCongratsMessage(){
        if(DisplayCounter == 0){
            SetDisplay(0, showLetter(arrayCongrats[0+index]));
        }
        if(DisplayCounter == 1){
            SetDisplay(1, showLetter(arrayCongrats[1+index]));
        }
        if(DisplayCounter == 2){
            SetDisplay(2, showLetter(arrayCongrats[2+index]));
        }
        if(DisplayCounter == 3){
            SetDisplay(3, showLetter(arrayCongrats[3+index]));
        }
        if(DisplayCounter == 4){
            SetDisplay(4, showLetter(arrayCongrats[4+index]));
        }
        if(DisplayCounter == 5){
            SetDisplay(5, showLetter(arrayCongrats[5+index]));
        }

        DisplayCounter++;
        DisplayCounter = DisplayCounter % 6;

        if (index > (arrayCongrats.length - 6) {
            showCongrats = false;
        }
    }
       
    void storeOutput(int output) {
        //Simulates storing a word in the output position of PP2 storage (there
        // is no java equivalent).
    }
    public static void main(String[] args) {
      new  SortingMachine().Initialize97State();
    }
    
}
