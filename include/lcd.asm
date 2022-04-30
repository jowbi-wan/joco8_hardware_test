; LCD Stuff...
LCD_DATA        EQU $D000
LCD_STATUS      EQU $D001
LCD_DDRB        EQU $D002
LCD_DDRA        EQU $D003

; LCD Control Signals
E               EQU %10000000
RW              EQU %01000000
RS              EQU %00100000

WAIT            EQU %00010000
; End of LCD Stuff
