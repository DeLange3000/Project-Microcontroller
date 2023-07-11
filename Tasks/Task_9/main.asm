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
	sbi DDRB, 3
	sbi PORTB, 3

	sbi DDRB, 5
	sbi PORTB, 5

	sbi DDRB, 4
	sbi PORTB, 4

	// line of 80 bits runs through height of 2 panels!!!
	// r18 =0 is highest line of bottom and top panels

	// CHECKERS
	.
main:
	ldi r18, 8
	outer_loop:
		ldi r17, 80
		SBI PORTB, 3
		mov r19, r18
/*		loop:
			sbi PINB, 3
			dec r19
			brne loop*/

		loop1:
			cbi PortB, 3
			cbi PORTB, 5
			sbi PORTB, 5
			cpi r17, 41
			brne continue
			sbi PINB, 3
			continue:
			dec r17
			brne loop1
		next_loop:
		ldi r17, 8
		loop2:
			cp r17, r18
			brne skip
			sbi PORTB, 3
			rjmp setrow
			skip:
			cbi PORTB, 3
			setrow:
			cbi PORTB, 5
			sbi PORTB, 5
			dec r17
			brne loop2

		CBI PORTB, 4
		SBI PORTB, 4
		CBI PORTB, 4
		dec r18
	brne outer_loop
rjmp main
