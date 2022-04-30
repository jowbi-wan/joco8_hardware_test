COPY MACRO SRC,DEST,LEN 
    LDA #<SRC 
    STA R0 
    LDA #>SRC 
    STA R0+1 
    LDA #<DEST 
    STA R1 
    LDA #>DEST
    STA R1+1 
    LDX #LEN 
    JSR COPY_MEM 
     ENDM

FILL MACRO VAL,DEST,LEN 
    LDY #LEN 
    LDA #<DEST 
    STA R0 
    LDA #>DEST 
    STA R0+1 
    LDA #VAL
FL# STA (R0),Y 
    DEY 
    BNE FL#   
    ENDM

; Print a null-terminated string to the serial output
PRINT MACRO STRING
    LDA #<STRING 
    STA R0 
    LDA #>STRING 
    STA R0+1
    JSR PRINT_STRING
    ENDM

LPRINT MACRO STRING
LST# .string STRING
     .byte 0
    LDA #<LST# 
    STA R0 
    LDA #>LST# 
    STA R0+1
    JSR PRINT_STRING

    ENDM