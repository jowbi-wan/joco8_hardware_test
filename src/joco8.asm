    CHIP 65C02
    INCLUDE .\include\macros.asm
    INCLUDE .\include\memory.asm
    INCLUDE .\include\lcd.asm

IO_IN           EQU $D030   ; PORTA
IO_OUT          EQU $D031   ; PORTB
IO_DDRB         EQU $D032 
IO_DDRA         EQU $D033
IO_PCR          EQU $D03C 
IO_IFR          EQU $D03D
IO_IER          EQU $D03E

SCREEN_BUFFER   EQU $0200   ; 80 bytes - $250 next address
BUFF_IND        EQU $0300
IO_BUFF         EQU $0400 

CONSOLE_LINE1   EQU $0250
CONSOLE_LINE2   EQU CONSOLE_LINE1+20
CONSOLE_LINE3   EQU CONSOLE_LINE2+20
CONSOLE_LINE4   EQU CONSOLE_LINE3+20

    .org $E000
; Kernal Function Table    
    .word PUTC
    .word GETC
START:
    CLD
    LDX #$FF
    TXS
    TXA
    STA IO_DDRB 
    STX IO_DDRA

    LDA #0
    STA BUFF_IND
    STA BUFF_IND+1
    STA BUFF_IND+2

    JSR INIT_LCD
    JSR INIT_SERIAL
    ;PRINT HELLO_MESSAGE

    JSR COPY_BUFFER
MAIN_LOOP:
    JSR COPY_BUFFER
    JSR REFRESH_LCD

    LDY #$ff
    LDA #$00
    STA R0
    LDA #$80
    STA R0+1
DRAW_LOOP
    TYA
    STA (R0),y
    INC R0
    DEY 
    BNE DRAW_LOOP

    INC BUFF_IND
    BCC MAIN_LOOP
    INC BUFF_IND+1
    LDA BUFF_IND+1
    JMP MAIN_LOOP

COPY_BUFFER:
    LDA BUFF_IND+1
    CMP #$80
    BEQ copy_odd_buffer
    CMP #$0
    BNE done_copy
    COPY SCREEN_TEMPLATE,SCREEN_BUFFER,80
    BRA done_copy
copy_odd_buffer:    
    COPY SCREEN_TEMPLATE_2,SCREEN_BUFFER,80
done_copy:
    RTS

clear_lcd:
    LDA #%10000000
    JSR lcd_instruction
    RTS

REFRESH_LCD:
    LDY #$0
    LDA #<SCREEN_BUFFER
    STA R1
    LDA #>SCREEN_BUFFER
    STA R1+1
refresh_loop
    CPY #80
    BEQ exit_refresh
    LDA (R1),y
    JSR print_char
    INY
    JMP refresh_loop
exit_refresh
    RTS

INIT_LCD:
    LDA #%11111111 ; Set all pins on port B to output
    STA LCD_DDRB
    LDA #%11110000 ; Set top 3 pins on port A to output
    STA LCD_DDRA

    LDA #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
    JSR lcd_instruction
    LDA #%00001100 ; Display on; cursor on; blink off
    JSR lcd_instruction
    LDA #%00000110 ; Increment and shift cursor; don't shift display
    JSR lcd_instruction
    LDA #$00000001 ; Clear display
    JSR lcd_instruction
    RTS

lcd_wait:
    PHA
    LDA #%00000000  ; Port B is input
    STA LCD_DDRB
lcdbusy:
    LDA #RW
    STA LCD_STATUS
    LDA #(RW|E)
    STA LCD_STATUS
    LDA LCD_DATA
    AND #%10000000
    BNE lcdbusy

    LDA #RW
    STA LCD_STATUS
    LDA #%11111111  ; Port B is output
    STA LCD_DDRB
    PLA
    RTS

lcd_instruction:
    JSR lcd_wait
    STA LCD_DATA
    LDA #0         ; Clear RS/RW/E bits
    STA LCD_STATUS
    LDA #E         ; Set E bit to send instruction
    STA LCD_STATUS
    LDA #0         ; Clear RS/RW/E bits
    STA LCD_STATUS
    RTS

print_char:
    JSR lcd_wait
    STA LCD_DATA
    LDA #RS         ; Set RS; Clear RW/E bits
    STA LCD_STATUS
    LDA #(RS|E)   ; Set E bit to send instruction
    STA LCD_STATUS
    LDA #RS         ; Clear E bits
    STA LCD_STATUS
    RTS



show_wait:
    PHA
    LDA #WAIT
    STA LCD_STATUS
    PLA
    RTS

end_wait:
    PHA
    LDA #0
    STA LCD_STATUS
    PLA
    RTS

; Copy from R0 to R1, for a length of X
COPY_MEM:
    LDY #$0
COPY_LOOP
    LDA (R0),y
    STA (R1),y
    DEX
    beq EXIT_COPY
    INY
    JMP COPY_LOOP
EXIT_COPY:
    RTS

scroll_console:
    COPY CONSOLE_LINE2,CONSOLE_LINE1,60
    FILL 20,CONSOLE_LINE4,20
    RTS

SCREEN_TEMPLATE:
    .string ' JoCo8-SX  SBC v1.0 '
    .string '  2021 by jowbiwan  '
    .string ' Developed December '
    .string '  Stable at 10MHz   '
    
SCREEN_TEMPLATE_2:
    .string ' +----------------+ '
    .string ' |     Screen     | '
    .string ' |     Second     | '
    .string ' +----------------+ '


char_rom:
; 256 x 15 byte character data
; Character code 00
    .byte %00000000         ; row 0
    .byte %00000000         ; row 1
    .byte %00000000         ; row 2
    .byte %00000000         ; row 3
    .byte %00000000         ; row 4
    .byte %00000000         ; row 5
    .byte %00000000         ; row 6
    .byte %00000000         ; row 7
    .byte %00000000         ; row 8
    .byte %00000000         ; row 9
    .byte %00000000         ; row 10
    .byte %00000000         ; row 11
    .byte %00000000         ; row 12
    .byte %00000000         ; row 13
    .byte %00000000         ; row 14

HELLO_MESSAGE: 
    .string 'Hello from JOCO-8SX!'
    .byte   0


INIT_SERIAL:
    STZ IO_DDRA         ; PORTA input
    LDA #$FF            ; PORTB output
    STA IO_DDRB         
    LDA #%10001000      ; CB2 = Handshake (100), CB1 Negative Edge (0)
    STA IO_PCR          ; CA2 = Handshake (100), CA1 Negative Edge (0)
    LDA #%00010100      ; Enable CB1/CA1 Interrupts
    STA IO_IER
    RTS

; Carry set if key available, return character in A
GETC:
    LDA IO_READ_PTR     ; Get read pointer
    CMP IO_WRITE_PTR    ; Compare to write pointer
    BEQ NO_CHAR_AVAIL   ; If equal, no character available
    TAY                 ; Increment read pointer
    INY                 
    STY IO_READ_PTR     ; store new read pointer
    LDA IO_BUFF,Y     ; return character at read pointer
    SEC                 ; Set Carry for data available
    RTS
NO_CHAR_AVAIL:    
    CLC                 ; Clear Carry for no data available
    RTS 

; Serial print string at address in R0
PRINT_STRING:
    LDY #0
PRINT_LOOP:
    LDA (R0),Y
    BEQ END_PRINT       ; Don't print the terminator
    JSR PUTC
    INC R0
    BCC PRINT_LOOP 
    INC R0+1
    BRA PRINT_LOOP
END_PRINT
    RTS

; Put a character out, wait for data taken signal, character in A
PUTC:
    STA IO_OUT          ; Character to print is in A
    LDA #PUTWAIT
    TRB OPFLAGS
PUT_WAIT:
    WAI                 ; Wait for Data Taken signal from Arduino
    LDA #PUTWAIT
    BIT OPFLAGS 
    BNE PUT_WAIT        ; Z=0 if bit set, Z=1 if bit not set
    RTS 

; IRQ Handler
IRQ:
; Check for Data Taken signal
    LDA #%00010000      ; Bit 4 = CB1
    TRB IO_IFR
    BNE NO_DATA_TAKEN   ; Z=0 if bit set, Z=1 if bit not set
    LDA #PUTWAIT 
    TSB OPFLAGS 
NO_DATA_TAKEN:
; Check for serial input
    LDA #%0000010       ; Bit 1 = CA1
    TRB IO_IFR
    BNE NO_DATA_AVAIL   ; Z=0 if bit set, Z=1 if bit not set
    LDY IO_WRITE_PTR    ; Get IO Buffer Offset
    INY                 ; And increment it to the next
    STY IO_WRITE_PTR    ; Available position
    LDA IO_IN           ; Read new character
    STA IO_BUFF,Y     ; Store character in new buffer position
NO_DATA_AVAIL:
; Other interrupts
    RTI

; NMI Handler
NMI:
    RTI
    
    .org $FFFA
    .word NMI
    .word START
    .word IRQ


