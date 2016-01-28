;===============================================================================
; Jordan Lee, Logan Barnes
; Group 1
; ECE 4730
; 12.14.2015
; Description: This program generates PWM signals to control dc motors. We are
;   completing part one of lab 7.11 in "Microcontroller Theory and Applications
;   HC12 & S12". The learning lessons from this lab are to understand and use
;   the input capture and output compare systems to create the PWM signals. We
;   will be using a 12V DC motor and a SN774410NE driver.
;===============================================================================

;-------------------------------------------------------------------------------
;Set constant variables
;-------------------------------------------------------------------------------
TSCR1      EQU          $0046   ;Address for the TSCR1 register
TEN        EQU          $80     ;TEN is bit 7 of TSCR1
TIE        EQU          $004c   ;Address for the TIE register
TCTL2      EQU          $0049   ;Address for the TCTL2 register
TCTL2_IN   EQU          $50     ;Initialize OC2 and OC3 toggle

;-------------------------------------------------------------------------------
; Main Program
; a. Use the output compare system to modify the duty cycle of the rectangular
;        output waveform
; b. Use the input capture funtion to monitor the number of pulses arriving at
;        an input capture pin and modify the output waveform accordingly
; c. Change the speed of the motor by adjusting the duty cycle of the output
;        waveform according to a specified speed profile
; d. Interface the S12 with 2 DC motors using the SN754410NE chip
;-------------------------------------------------------------------------------

           ORG          $2000
; a ----------------------------------------------------------------------------
;    Pins PT2 and PT3 are used to generate ouput signals
;    The TCNT takes 2.62144 ms to count from 0000 to FFFF. For a 15 second time
; period we need 5,722 pulses. 5 seconds will be sent for acceleration, 5
; seconds for constant speed and 5 seconds for deceleration. Each 5 second
; period will consist of 1,907 pulses of the TCNT. Acceleration starts at 5%
; duty cycle and goes until 20% duty cycle. A 5% duty cycle will have a count
; of 1.25x10^6 and a 20% duty cycle will have a count of 5.0x10^6.
; Step One - Enable TEN bit in TSCR register
           MOVB         #TEN, TSCR1
; Step Two - Generate PWM signals
           BSR          OCINIT          ;Initialize output compare system
; b ----------------------------------------------------------------------------
;    Pins PT0 and PT1 are used to monitor input signals generated by the OC2 and
; OC3 output compare systems

; c ----------------------------------------------------------------------------
; The OC2 and OC3 output compare systems will control the left and right motors

; d ----------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; OCINIT subroutine: Initializes the Output compare system
;-------------------------------------------------------------------------------
OCINIT     CLR          TIE             ;Disable interrupts
           MOVB         TCTL2_IN, TCTL2 ;OC2 toggle on Compare channel 2
           RTS

;-------------------------------------------------------------------------------
; GETDUTY subroutine: Gets desired duty cycle value and stores it in
;                     Accumulator A
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SETDUTY subroutine: Sets the duty cycle according to value in Accumulator A
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; ICINIT subroutine: Initializes the Input Compare System
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; GETIC subroutine: Gets the values the Input Capture system should get
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; PRINT subroutine: Prints the values to the computer monitor
;-------------------------------------------------------------------------------