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
.org 0x000 rjmp init
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
	LDI R16, 0x14
    in R0, PINB
	BST R0, 2

	BRTC JoyPressed

	JoyNotPressed:
		SBI PORTC,2
		CBI PORTC, 3
		RJMP main

	JoyPressed:
		CBI PORTC, 2
		SBI PORTC, 3
		RJMP main

    rjmp main


