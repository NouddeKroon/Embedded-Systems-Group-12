/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author s137910
 */
public class SortingMachine {
    boolean Abort;
    boolean StartStop;
    boolean StopPressed;
    boolean ColorWhite;
    int ConveyorBelt;
    int RotatingBuckets;
    int LoadingArm;
    int ColorLED;
    int PositionDetectorLED;
    int RotatingBucketsLED;
    boolean WhiteBucketFront;
    int Black;
    int White;
    int StateDisplay;
    boolean LoadingArmPS;
    boolean PositionDetectorSensor;
    boolean RotatingBucketsSensor;
    boolean ColorSensor;
    int Clock1;
    
    
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
               Read_Input();
               for(int i = 0; i <= 8; i++){
                   Set_variables();
               }
           
           if(StartStop == true){
               StopPressed = true;
           }
           Clock1++;
           Set_Output_PWM();
           Sleep(1);
         }
       }
    public static void main(String[] args) {
      new  SortingMachine().Initialize97State();
    }
    
}
