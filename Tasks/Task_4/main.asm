;
; Task_1.asm
;
; Created: 15/02/2023 14:14:20
; Author : warre
;

; Definition file of the ATmega328P
.include "m328pdef.inc"

;register definitions

; constants

;Boot code
.org 0x000
	rjmp init

; Interrupt address vectors

init:
	CBI DDRB,2
	SBI PORTB, 2

	SBI DDRC, 3
	SBI PORTC, 3

	SBI DDRC, 2
	SBI PORTC, 2

	SBI DDRB, 1
	SBI PORTB, 1
	rjmp main



main:
	SBI PINB, 1
	LDI R18, 0x01
	OOLoop1:
		LDI R17, 0x0F
		OLoop1:
			LDI R16, 0xFF
			Loop1:
				DEC R16
				BRNE Loop1
			dec r17
			BRNE OLoop1
		dec r18
		BRNE OOLoop1


	CBI PINB, 1
	LDI R18, 0x01
	OOLoop2:
		LDI R17, 0x0F
			OLoop2:
			LDI R16, 0xFF
			Loop2:
				DEC R16
				BRNE Loop2
			dec r17	
			brne OLoop2
		dec r18
		brne OOLoop2

	rjmp main





;
; Task_4.asm
;
; Created: 15/02/2023 16:09:36
; Author : warre
;


; Replace with your application code
start:
    inc r16
    rjmp start
