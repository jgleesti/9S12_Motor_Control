                ORG $1000

CR:             EQU   $0D        ;Return carrier in ascii
LF:             EQU   $0A        ;Linefeed in ascii

DEBUG              FCC     'Debug' ;A string to put to the screen for debug
                   DB      CR,LF,0 ;purposes
PRINT1             FCC     'The total running time is ' ;First part of the string
NUM_SECS           FCB     $30     ;A place in memory to track number of seconds
PRINT2             FCC     ' sec.'  ;2nd part of string to print
                   DB      CR,LF,0
                   
                   ORG         $2000
LOOP               LDD     NUM_SECS
                   ADDD    #01
                   STD     NUM_SECS
                   BRA     LOOP
                   
                   END