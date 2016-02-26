;===============================================================================
; Jordan Lee, Logan Barnes
; Group 1
; ECE 4730
; 02.11.2016
; Description: This program generates PWM signals to control dc motors. We are
;   completing part one of lab 7.11 in "Microcontroller Theory and Applications
;   HC12 & S12". The learning lessons from this lab are to understand and use
;   the input capture and output compare systems to create the PWM signals. We
;   will be using a 12V DC motor and a SN774410NE driver.
;===============================================================================

;-------------------------------------------------------------------------------
;Set constant variables
;-------------------------------------------------------------------------------
            ORG         $1000
; ---- LOCATIONS ----
TIOS        EQU         $0040   ; TIMER I/O SELECT. BITS CORRESPOND TO CHANNELS. I.E. [7:0]
CFORC       EQU         $0041   ; TIMER OC FORCE REG. BASICALLY FORCES AN OUPUT SIGNAL!

OC7M        EQU         $0042   ; FORCES PORT T PIN TO BE OUTPUT. REGARDLESS OF DDRT SETTINGS.
OC7D        EQU         $0043   ; SEND BITS CORRESPONDING TO SET BITS OF OC7M TO TIMER PORT PINS.

TCNT        EQU         $0044   ; SAME AS TCNTH, WE CAN JUST USE THIS FOR FETCHING ALL 16 BITS.
TCNTH       EQU         $0044   ; TIMER COUNTER HIGH (UPPER 8 BITS)
TCNTL       EQU         $0045   ; TIMER COUNTER LOW (LOWER 8 BITS)

TSCR1       EQU         $0046   ; BIT 7 IS TEN (TIMER ENABLE) 1000 0000 TO ENABLE.
TSCR2       EQU         $004D   ; DON'T MESS WITH BIT 3 ($08) IT RESETS THE FRC!
                                ; BITS [2:0] ARE THE PRESCALER BITS.
TCTL1       EQU         $0048   ; TIMER CONTROL REG 1 (UPPER 8 MODE/LEVEL) <- IN ORDER [7 TO 4]
TCTL2       EQU         $0049   ; TIMER CONTROL REG 2 (LOWER 8 M/L) [3 TO 0]
TCTL4       EQU         $004B   ;
TIE         EQU         $004C   ; ENABLES INTERRUPTS ON THE SPECIFIED CHANNEL.

TFLG1       EQU         $004E    ; BITS CORRESPOND TO CHANNELS. [7:0]
TFLG2       EQU         $004F    ; BIT [7] IS THE TOF

PRINTF      EQU         $EE88   ;The 9S12 subroutine for printing to screen

TC2H        EQU         $0054   ; WILL USE TC2/TC3 TO TURN CH 2,3 TO LOGIC LOW, EVERYTIME
TC2L        EQU         $0055   ;   THE FRC ROLLS OVER. ?
TC3H        EQU         $0056   ; -THESE REGISTERS CAN EITHER LATCH THE VALUE OF THE FRC,-
TC3L        EQU         $0057   ; -OR BE USED TO TRIGGER AN OC EVENT WHEN FRC REACHES THIS VALUE!- :)
TC7H        EQU         $005E   ; WILL USE TC7 TO TURN CH 2,3 TO LOGIC LOW, AFTER
TC7L        EQU         $005F   ;   THE FRC COUNTS TO NUMBER STORED HERE.

; ---- VALUES TO USE ----
CR:         EQU         $0D     ;ASCII Return character
LF:         EQU         $0A     ;ASCII linefeed character

; ----- MASKS -----
TIOS_IN     EQU         $8C     ;Sets 0 and 1 to IC and sets 2, 3, and 7 to OC
OC7M_MSK    EQU         $0C     ; SETS BITS 0000 1100 (CHANNELS 2/3) FOR SIMULTANEOUS OUTPUT TO PORT T PINS.
                                ; [7:0] == [CH3M, CH3L, CH2M, CH2L, CH1M, CH1L, CH0M, CH0L]
OC7D_MSK    EQU         $0C     ; EACH BIT CORRESPONDS TO PORT T BITS. THESE VALUES ARE WRITTEN OUT
                                ; TO PORT T ON A SUCCESSFUL 0C7 COMPARE ACTION. (WILL SET THEM LOW)
TEN         EQU         $80     ; TEN is bit 7 of TSCR1
TIE_MSK     EQU         $01     ; ENABLE INTERRUPTS ON IC0
TSCR2_IN    EQU         $03     ; OVF INTERRUPT DISABLED. PRESCALAR SET TO 8.
TCTL2_ON    EQU         $A0     ; 1010 0000, SETTING CHANNELS 2 & 3 TO "ON". (LOGIC LEVEL HIGH)
TCTL4_IN    EQU         $01     ; Initialize IC0 to rising edge
IC_EN       EQU         $01     ; ENABLE IC0 INTERRUPTS.
CLR_FLG1    EQU         $FF     ; WRITE TO FLAG REG TO CLEAR ALL THE FLAGS.
TC2_MSK     EQU         $0CCD   ; WHEN THE FRC EQUALS THIS VALUE,
TC3_MSK     EQU         $0CCD   ;  O2,O3 SET TO VALUES SPECIFIED IN TCTL2 (OFF).

;DEBUG       FCC         'Debug' ;A string to put to the screen for debug
;            DB          CR,LF,0 ;purposes

;Memory spots reserved for keeping track of the number of seconds that have
;passed and the characters to print to the screen.
PRINT1      FCC         'The total running time is ' ;First part of the string
SEC_TEN     FCB         $02     ;A place in memory to keep track of the tens
                                ;position when counting seconds
SEC_ONE     FCB         $30     ;Keep track of the ones right after the tens
PRINT2      FCC         ' sec.' ;End of the print statement
            DB          CR,LF,0 ;Carriage return, line feed and end of string
                                ;marker
NUM_PULSES  FDB         $0000   ;Keep track of the number of pulses received
PPS         FDB         $0030   ;Keep two bytes for pulses per second
                                ; THERE WILL BE 2E OVERFLOWS/SECOND (46)
DUTY        FDB         $0CCD   ; INITIAL VALUE OF 3,277 'TICKS' = 5% DUTY CYCLE. This value goes in TC7
STEP        FDB         $002B     ; AMOUNT TO STEP UP/DOWN EACH PERIOD.

;-------------------------------------------------------------------------------
; Main Program
; a. Use the output compare system to modify the duty cycle of the rectangular
;             output waveform
; b. Use the input capture funtion to monitor the number of pulses arriving at
;        an input capture pin and modify the output waveform accordingly
; c. Change the speed of the motor by adjusting the duty cycle of the output
;        waveform according to a specified speed profile
; d. Interface the S12 with 2 DC motors using the SN754410NE chip
;-------------------------------------------------------------------------------
            ORG         $2000
            LDS         #$4000               ;Initialize the stack

;  a.Pins PT2 and PT3 are used to generate ouput signals
;    The TCNT takes 21.85 ms to count from 0000 to FFFF. For a 15 second time
; period we need 687 pulses (ROLLOVERS). 5 seconds will be sent for acceleration, 5
; seconds for constant speed and 5 seconds for deceleration. Each 5 second
; period will consist of 229 pulses (ROLLOVERS) of the FRC (TCNT?). Acceleration starts at 5%
; duty cycle and goes until 20% duty cycle. A 5% duty cycle will have 3,277 TICKS,
; and a 20% duty cycle will have a count of 13,107 TICKS.
; Step Two - Generate PWM signals
;  b.Pins PT0 and PT1 are used to monitor input signals generated by the OC2 and
; OC3 output compare systems
; c.The OC2 and OC3 output compare systems will control the left and right motors
            BSR         TIMERINIT       ;Initialize timer system
RUNNING     BRA         RUNNING         ;Just letting it run now.
                                        ;Duty cycle is modified every cycle, during IC event.
                                        ;OC channels set high/low using OC2/OC3 and OC7, without ISRs,
                                        ;So they just keep going.

;-------------------------------------------------------------------------------
; TIMERINIT subroutine: Initializes the Output compare AND INPUT CAPTURE SYSTEMS.
;-------------------------------------------------------------------------------
TIMERINIT   ;CLR         TIE                ;Disable channel interrupts.
            MOVB        #TEN, TSCR1         ;Enable timer system with TEN bit
            MOVB        #TSCR2_IN, TSCR2    ;DISABLE OVF INTERRUPTS, PRESCALAR = 8.
            MOVB        #TCTL2_ON, TCTL2    ;Set OC2 and OC3 to LOW ON-COMPARE. (WHEN FRC == $0000)
            MOVB        #TCTL4_IN, TCTL4    ;Set IC0 and IC1 to rising edge
            MOVB        #OC7M_MSK, OC7M     ;SET OC2,OC3 TO OUTPUT TO PORT T 2,3.
            MOVB        #OC7D_MSK, OC7D     ;LOGIC TO WRITE OUT TO PORT T 2,3 A HIGH SIGNAL. (0000 1100)
            MOVB        #TIOS_IN, TIOS      ;TC7 NEEDS TO BE SET TO OC FOR OC7 SYSTEM TO WORK.
            MOVW        DUTY, TC2H        ;WHEN FRC == DUTY CYCLE, OC2
            MOVW        DUTY, TC3H        ; AND OC3 WILL GO HIGH.
            MOVW        #IC0_INT, $3E6E     ;Set vector for IC0, with DBUG12
                                            ;interrupt vector map address. -TC0
            MOVW        #$0000, TC7H       ;WHEN FRC MATCHES 'DUTY', GO HIGH.
            MOVB        #TIE_MSK, TIE          ;THIS WILL ENABLE INTERRUPTS FROM IC0
            CLI

            RTS

;-------------------------------------------------------------------------------
; IC0_INT subroutine: The ISR for an IC event on ch0 (rising edge)
;-------------------------------------------------------------------------------
IC0_INT    LDAA         TFLG1          ;Clear the IC0 and IC1 Flags
           ORAA         #$83
           STAA         TFLG1
           LDAA         SEC_TEN        ;Check the ten's spot to see if we are
           CMPA         #$02           ;in the first ten seconds. If we aren't
           BNE          DCL            ;then we have to be decelerating
           LDAA         SEC_ONE        ;We are in the first ten seconds. Check
           CMPA         #$35           ;if we are in the first five seconds and
           BLT          ACC            ;accelerate if we are.
           BRA          CONST          ;5-10 second range means constant speed
DCL        JSR          MTR_DEC        ;Decelerate the motors
           BRA          CHCK_SEC
ACC        JSR          MTR_ACC        ;Accelerate the motors
           BRA          CHCK_SEC
CONST      JSR          MTR_CONST      ;Keep motors constant
CHCK_SEC   LDD          NUM_PULSES     ;Check the number of pulses received so
           ADDD         #0001            ;far and add 1 to it
           STD          NUM_PULSES     ;Store the new number of pulses
           LDX          PPS            ;Get the number of pulses in a second and
           IDIV                        ;divide total pulses by that number
           CPD          #0000          ;If there is no remainder, then we are at
           BEQ          IS_SEC         ;the second mark
           RTI                         ;if there is a remainder continue program
IS_SEC     JSR          PRINT          ;Call the print subroutine to print out
           RTI                         ;the number of seconds and return from
                                       ;the interrupt

;-------------------------------------------------------------------------------
; PRINT subroutine: Prints the values to the computer monitor
;-------------------------------------------------------------------------------
PRINT       LDAA        SEC_ONE       ;Get current number of seconds in ones position
            ADDA        #$01           ;Add a second to the ones position
            CMPA        #$3A          ;Check to see if it is the character above '9'
            BEQ         ADD_TEN       ;and if it is go to the ADD_TEN section
            STAA        SEC_ONE       ;If not store the new added second to ones
            BRA         PRNT_SEC      ;position and continue to print
ADD_TEN     LDAA        #$31          ;Put a '1' in the tens position
            STAA        SEC_TEN
            LDAA        #$30          ;Put a '0' in the ones position
            STAA        SEC_ONE
PRNT_SEC    LDD         #PRINT1       ;Display the message that tracks how many seconds
            LDX         PRINTF        ;have passed based on the number of pulses
            JSR         0,X
            LDAA        SEC_ONE       ;Check one's and ten's place to see if we have
            CMPA        #$35          ;reached 15 seconds. When we have then the
            BNE         GO            ;program can stop executing. Otherwise, continue
            LDAA        SEC_TEN       ;running the program
            CMPA        #$31
            BNE         GO
            LDD         #$0001
            STD         TC2H
            STD         TC3H
DONE        BRA         DONE
GO          RTS

;-------------------------------------------------------------------------------
; MTR_ACC subroutine: Gets called every TCNT pulse for seconds 0 - 5. Every time
;                     this subroutine is called it increases the motor duty
;                     cycle by a specified amount.
;-------------------------------------------------------------------------------
MTR_ACC     LDD         TC2H
                                    ;Get the current Duty cycle and add 2B to it to
            ADDD        STEP        ;increase from 5% to 20% over five seconds
            STD         TC2H
            STD         TC3H
            RTS

;-------------------------------------------------------------------------------
; MTR_CONST subroutine: Gets called every TCNT pulse for seconds 5-10. This
;                      subroutine keeps the motor's duty cycle at the same rate.
;-------------------------------------------------------------------------------
MTR_CONST   RTS

;-------------------------------------------------------------------------------
; MTR_DEC subroutine: Gets called every TCNT pulse for seconds 10-15. This
;                     subroutine decreases the motor's duty cycle by a specified
;                     amount.
;-------------------------------------------------------------------------------
MTR_DEC     LDD         TC2H       ;Get the current Duty cycle, add 2B to it to
            SUBD        STEP       ;decrease from 20% to 5% over five seconds
            STD         TC2H
            STD         TC3H
            RTS

            END
