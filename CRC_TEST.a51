;Program to demonstrate the use of the CRC routines
;                   				        ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                   				        ;
                        ORG 00E0H                       ;Place the version info here
;                   	    0123456789ABCDEF            ;
VEREK:                  DB 'E:1.001 20200329'           ;
;                   	    0123456789ABCDEF            ;
                        DB '_'                          ;
;                   	    0123456789ABCDEF            ;
DEVICE:                 DB 'CRC EXAMPLE__',0             ;The string must be 0 terminated.
;                   				        ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                   				        ;
; 20200329: Program to demonstrate the use of the CRC subroutines
;             A byte and the previous CRC8 and CRC16 values are sent to the MCU.  CRC8 and CRC16 routines are
;             calculated and reported to the PC via the serial port.
;           Incoming message is expected to be:  
;           '!C' + New data byte in hex + ',' + Previous CRC8 in hex + ',' + Previous CRC16 in hex + CR (character code 13)
;           Hex numbers are sent MS nibble first, LS nibble last
;           Response message is expected to be:
;           '!C' + Previous CRC8 in hex + ',' + Previous CRC16 in hex + ',' + Next CRC8 in hex + ',' + Next CRC16 in hex + CR (character code 13)  
;
;                   				        ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
$INCLUDE (CRD89C51AD1T.MCU)
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;* DEFINITION OF CONSTANTS
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
STARTCHR                EQU 33                   	;Messages start with the "!" character.
CR                      EQU 13                          ;Carriage return character.
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;* DEFINITION OF VARIABLES   
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
NewByte                 EQU 030H                        ;Incoming byte to be used to calculate the new CRC values
NewByte_MSnibble        EQU 031H                        ;Incoming byte MS nibble in HEX
NewByte_LSnibble        EQU 032H                        ;Incoming byte LS nibble in HEX
;                                                       ;
CRC8_MSnibble           EQU 033H                        ;CRC8 MS nibble hex character
CRC8_LSnibble           EQU 034H                        ;CRC8 LS nibble hex character
;                                                       ;
CRC16_MSB_MSnibble      EQU 035H                        ;CRC16 MSB MS nibble hex character
CRC16_MSB_LSnibble      EQU 036H                        ;CRC16 MSB LS nibble hex character
CRC16_LSB_MSnibble      EQU 037H                        ;CRC16 LSB MS nibble hex character
CRC16_LSB_LSnibble      EQU 038H                        ;CRC16 LSB LS nibble hex character
;                                                       ;
CRC8_MSnibble_Next      EQU 039H                        ;CRC8 MS nibble hex character_Next
CRC8_LSnibble_Next      EQU 03AH                        ;CRC8 LS nibble hex character_Next
;                                                       ;
CRC16_MSB_MSnibble_Next EQU 03BH                        ;CRC16 MSB MS nibble hex character_Next
CRC16_MSB_LSnibble_Next EQU 03CH                        ;CRC16 MSB LS nibble hex character_Next
CRC16_LSB_MSnibble_Next EQU 03DH                        ;CRC16 LSB MS nibble hex character_Next
CRC16_LSB_LSnibble_Next EQU 03EH                        ;CRC16 LSB LS nibble hex character_Next
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;* Programme starts here 
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
                        ORG 0000H                       ;Place the version info here
                        LJMP START                      ;Jump to the start of the main programme
;                                                       ;
                        ORG 0100H                       ;Main programme starts here
;                                                       ;
START:                                                  ;
INISER: 						;Initialise the serial port
                        ANL TMOD,#00001111B		;Clear the top 4 bits
                        ORL TMOD,#00100000B		;Set bit 5 (in the same way as loading TMOD with 20h)
;                                                       ;
                        MOV A,#0FAH                     ;Serial reload byte if system XTAL = 11.0592 MHz
                        MOV A,#0F4H                     ;Serial reload byte if system XTAL = 22.1184 MHz
                        MOV A,#0F3H                     ;Serial reload byte if system XTAL = 24.5760 MHz
;                                                       ;
                        MOV TH1,A           		;Load TH1 (low and high) with the reload byte
                        MOV TL1,A			;
                        ORL PCON,#80H      		;
                        MOV SCON,#52H			;
;                                                       ;
                        ANL TCON,#00110011B		;Clear all bits related to Timer1
                        ORL TCON,#01000000B		;Set bit 6
			             			;These two commands provide the equivalent  of loading TCON with 40h
                        CLR TI				;Release the serial port
                        CLR RI                  	;
;                                                       ;
;           Incoming message is expected to be:  
;           '!C' + New data byte in hex + ',' + Previous CRC8 in hex + ',' + Previous CRC16 in hex + CR (character code 13)
;           Hex numbers are sent MS nibble first, LS nibble last
;                                                       ;
WAIT_FOR_STARTCHR:      JNB RI,$        		;Wait for a character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        CJNE A,#STARTCHR,WAIT_FOR_STARTCHR ;Keep on waiting until the "!" character is received.
;                                                       ;
WAIT_FOR_C:             JNB RI,$        		;Wait for a character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        CJNE A,#'C',WAIT_FOR_STARTCHR   ;It is not a 'C', go back to start again
;                                                       ;
                        MOV R0,#NewByte_MSnibble        ;Point to the bottom of the HEX characters' table
                        JNB RI,$        		;Wait for the NewByte_MSnibble hex character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        MOV @R0,A                       ;Store the hex character at the location pointed by R0
                        INC R0                          ;Increase the pointer by one location
;                                                       ;
                        JNB RI,$        		;Wait for the NewByte_LSnibble hex character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        MOV @R0,A                       ;Store the hex character at the location pointed by R0
                        INC R0                          ;Increase the pointer by one location
;                                                       ;
;                                                       ;We now have the hex characters of the byte to be used for the new CRC calculation
;                                                       ;
                        JNB RI,$        		;Wait for the ',' separator
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        CJNE A,#',',WAIT_FOR_STARTCHR   ;It is not a ',', go back to start again as some sort of framing error has occurred
;                                                       ;
                        JNB RI,$        		;Wait for the CRC8_MSnibble hex character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        MOV @R0,A                       ;Store the hex character at the location pointed by R0
                        INC R0                          ;Increase the pointer by one location
;                                                       ;
                        JNB RI,$        		;Wait for the CRC8_LSnibble hex character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        MOV @R0,A                       ;Store the hex character at the location pointed by R0
                        INC R0                          ;Increase the pointer by one location
;                                                       ;
;                                                       ;We now have the hex characters of the current CRC8 byte
;                                                       ;
                        JNB RI,$        		;Wait for the ',' separator
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        CJNE A,#',',WAIT_FOR_STARTCHR   ;It is not a ',', go back to start again as some sort of framing error has occurred
;                                                       ;
                        JNB RI,$        		;Wait for the CRC16_MSB_MSnibble hex character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        MOV @R0,A                       ;Store the hex character at the location pointed by R0
                        INC R0                          ;Increase the pointer by one location
;                                                       ;
                        JNB RI,$        		;Wait for the CRC16_MSB_LSnibble hex character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        MOV @R0,A                       ;Store the hex character at the location pointed by R0
                        INC R0                          ;Increase the pointer by one location
;                                                       ;
                        JNB RI,$        		;Wait for the CRC16_LSB_MSnibble hex character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        MOV @R0,A                       ;Store the hex character at the location pointed by R0
                        INC R0                          ;Increase the pointer by one location
;                                                       ;
                        JNB RI,$        		;Wait for the CRC16_LSB_LSnibble hex character to arrive
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        MOV @R0,A                       ;Store the hex character at the location pointed by R0
                        INC R0                          ;Increase the pointer by one location
;                                                       ;
;                                                       ;We now have the hex characters of the current CRC16 byte
;                                                       ;
                        JNB RI,$        		;Wait for the CR terminator
        		MOV A,SBUF			;Read the incoming char
	               	CLR RI				;and allow the serial port to Rx the next one.
                        CJNE A,#CR,WAIT_FOR_STARTCHR    ;It is not a CR, go back to start again as some sort of framing error has occurred
;                                                       ;
;                                                       ;We now have all the parameters to calculate the binary values
                                                        ;  of the incoming byte, the current CRC8 and the current CRC16
;                                                       ;
                        MOV R0,#NewByte_MSnibble        ;Point R0 the bottom of the received characters, NewByte is first
                        LCALL HEX_CHRS_IN_IRAM_2_BYTE   ;Convert the two ASCII chars pointed to by R0 into a single byte
                        MOV NewByte,A                   ;Store the binary result in IRAM.
                                                        ;R0 is now pointing to CRC8_MSnibble
                        LCALL HEX_CHRS_IN_IRAM_2_BYTE   ;Convert the two ASCII chars pointed to by R0 into a single byte
                        MOV CRC,A                       ;Store the binary result in IRAM.
                                                        ;R0 is now pointing to CRC16_MSB_MSnibble
                        LCALL HEX_CHRS_IN_IRAM_2_BYTE   ;Convert the two ASCII chars pointed to by R0 into a single byte
                        MOV CRC_HI,A                    ;Store the binary result in IRAM.
                                                        ;R0 is now pointing to CRC16_LSB_MSnibble
                        LCALL HEX_CHRS_IN_IRAM_2_BYTE   ;Convert the two ASCII chars pointed to by R0 into a single byte
                        MOV CRC_LO,A                    ;Store the binary result in IRAM.
;                                                       ;
;                                                       ;We now have all the variables ready to process
                        MOV A,NewByte                   ;Load the incoming byte onto A
                        LCALL CRC8                      ;Calculate the new value of CRC8
;                                                       ;
                        MOV A,NewByte                   ;Load the incoming byte onto A
                        LCALL CRC16                     ;Calculate the new value of CRC16
;                                                       ;Both CRC8 and CRC16 are now calculated
;                                                       ;
;                                                       ;Prepare the response message
;           Response message is expected to be:
;           '!C' + Previous CRC8 in hex + ',' + Previous CRC16 in hex + ',' + Next CRC8 in hex + ',' + Next CRC16 in hex + CR (character code 13)  
;           Hex numbers are sent MS nibble first, LS nibble last
;                                                       ;
                        MOV R0,#CRC8_MSnibble_Next      ;The HEX characters to be reported will be stored in IRAM starting from location CRC8_MSnibble_Next
;                                                       ;
                        MOV A,CRC                       ;First prepare the HEX characters of CRC8                        
                        LCALL STORE_HEX_BYTE_IN_IRAM_WITH_TWO_CHR ;Translate the byte in A in two chars stored in IRAM pointed to R0
;                                                       ;
                        MOV A,CRC_HI                    ;Next prepare the MS HEX characters of CRC16                        
                        LCALL STORE_HEX_BYTE_IN_IRAM_WITH_TWO_CHR ;Translate the byte in A in two chars stored in IRAM pointed to R0
                                                        ;R0 is now pointing to CRC16_LSB_MSnibble_Next
                        MOV A,CRC_LO                    ;Next prepare the LS HEX characters of CRC16                        
                        LCALL STORE_HEX_BYTE_IN_IRAM_WITH_TWO_CHR ;Translate the byte in A in two chars stored in IRAM pointed to R0
;                                                       ;
;                                                       ;We are now ready to send the response back to the PC.
;                                                       ;Send the header out first !C
                        MOV A,#'!'                      ;
                        LCALL TX_CHAR                   ;Tx the character
                        MOV A,#'C'                      ;
                        LCALL TX_CHAR                   ;Tx the character
                        MOV R0,#CRC8_MSnibble           ;The data starts at CRC8_MSnibble IRAM location.
                        LCALL TX_TWO_CHARS              ;Tx two characters corresponding to the original CRC8 value
                                                        ;R0 now points to CRC16_MSB_MSnibble
                        LCALL TX_COMMA                  ;Tx a comma to separate the reported values.
                        LCALL TX_FOUR_CHARS             ;Tx four characters corresponding to the original CRC16 value
                                                        ;R0 now points to CRC8_MSnibble_Next
                        LCALL TX_COMMA                  ;Tx a comma to separate the reported values.
                        LCALL TX_TWO_CHARS              ;Tx two characters corresponding to the original CRC8 value
                                                        ;R0 now points to CRC16_MSB_MSnibble_Next
                        LCALL TX_COMMA                  ;Tx a comma to separate the reported values.
                        LCALL TX_FOUR_CHARS             ;Tx four characters corresponding to the original CRC16 value
;                                                       ;
;                                                       ;All data have now been reported, terminate the report with a CR
                        MOV A,#CR                       ;
                        LCALL TX_CHAR                   ;Tx the character
;                                                       ;
;                                                       ;We are done now, go back to wait for another start of message character
                        LJMP WAIT_FOR_STARTCHR          ;
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;* Subroutines start here 
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
TX_COMMA:                                               ;Tx a ',' character through the serial port
                        MOV A,#','                      ;
                        LCALL TX_CHAR                   ;Tx the char through the serial port.
                        RET                             ;Return to caller  
;                                                       ;
TX_FOUR_CHARS:                                          ;Send four characters through the serial port - non interrupt.
                                                        ;  stored in IRAM, pointed by R0
                        PUSH B                          ;B will be used as a counter
                        MOV B,#2                        ;2 characters will be transmitted
TX_FOUR_CHARS_LOOP:     LCALL TX_TWO_CHARS              ;Tx 2 chars
                        DJNZ B,TX_FOUR_CHARS_LOOP       ;Repeat till all chars have been Tx'd
                        POP B                           ;Restore B
                        RET                             ;Return to caller  
;                                                       ;
TX_TWO_CHARS:                                           ;Send two characters through the serial port - non interrupt.
                                                        ;  stored in IRAM, pointed by R0
                        PUSH B                          ;B will be used as a counter
                        MOV B,#2                        ;2 characters will be transmitted
TX_TWO_CHARS_LOOP:      MOV A,@R0                       ;Read the character in from IRAM as pointed by R0
                        INC R0                          ;Increase R0 to point to the next location
                        LCALL TX_CHAR                   ;Tx the char through the serial port.
                        DJNZ B,TX_TWO_CHARS_LOOP        ;
                        POP B                           ;Restore B
                        RET                             ;Return to the caller
;                                                       ;
TX_CHAR:                                                ;Send the character through the serial port - non interrupt.
                        MOV SBUF,A                      ;Move the character into the serial buffer,
                        JNB TI,$			;and wait for the transmission process to be completed.
                        CLR TI				;Release the serial transmission cct.
                        RET				;Return to the caller.
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;* External subroutines are included here 
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
$INCLUDE (CRC_Utilities.a51)
$INCLUDE (HEX_CONVERSION_UTILITIES.a51)
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
                END        
