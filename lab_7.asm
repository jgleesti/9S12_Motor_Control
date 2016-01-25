;===============================================================================
; Jordan Lee, Logan Barnes
; ECE 4730
; 12.14.2015
; Description: This program generates PWM signals to control dc motors. We are
; 		completing part one of lab 7.11 in "Microcontroller Theory and
;		Applications HC12 & S12". The learning lessons from this lab are
; 		to understand and use the input capture and output compare
;		systems to create the PWM signals.
;===============================================================================

;-------------------------------------------------------------------------------
;Set constant variables
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; Main Program
; a. Use the output compare system to modify the duty cycle of the rectangular
;	output waveform
; b. Use the input capture funtion to monitor the number of pulses arriving at
;	an input capture pin and modify the output waveform accordingly
; c. Change the speed of the motor by adjusting the duty cycle of the output
;	waveform according to a specified speed profile
; d. Interface the S12 with 2 DC motors using the SN754410NE chip
;--------------------------------------------------------------------------------------

; a -----------------------------------------------------------------------------------

; b -----------------------------------------------------------------------------------

; c -----------------------------------------------------------------------------------

; d -----------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------
; OCINIT function: Initializes the Output compare system
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
; GETDUTY function: Gets desired duty cycle value and stores it in Accumulator A
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
; SETDUTY function: Sets the duty cycle according to value in Accumulator A
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
; ICINIT function: Initializes the Input Compare System
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
; GETIC function: Gets the values the Input Capture system should get
;--------------------------------------------------------------------------------------


;--------------------------------------------------------------------------------------
; PRINT function: Prints the values to the computer monitor
;--------------------------------------------------------------------------------------