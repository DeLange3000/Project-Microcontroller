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
	rjmp main



main:
	SBI PORTC, 2
	CBI PORTC, 3
	LDI R18, 0x0F
	OOLoop1:
		LDI R17, 0xFF
		OLoop1:
			LDI R16, 0xFF
			Loop1:
				DEC R16
				BRNE Loop1
			dec r17
			BRNE OLoop1
		dec r18
		BRNE OOLoop1


	CBI PORTC, 2
	SBI PORTC, 3
	LDI R18, 0x0F
	OOLoop2:
		LDI R17, 0xFF
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





