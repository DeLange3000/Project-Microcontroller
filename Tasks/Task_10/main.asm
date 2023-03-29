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

	// line of 80 bits runs through height of 2 panels:     --->
	//														<---
	// r18 =0 is highest line of bottom and top panels

main:
	ldi r18, 8
	outer_loop:
		ldi r17, 80
		loop1:
			rjmp draw_YEET
			done_drawing:
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


draw_YEET:
	cpi r17, 21
	brge no_pixel
	cpi r18, 7
	breq line_7n
	cpi r18, 6
	breq line_6n
	cpi r18, 5
	breq line_5
	cpi r18, 4
	breq line_4
	cpi r18, 3
	breq line_3
	cpi r18, 2
	breq line_2
	cpi r18, 1
	breq line_1

	line_1:
	cpi r17, 5
	brge pixel
	cpi r17, 1
	breq pixel
	rjmp no_pixel
	rjmp done_drawing

	line_2:
	cpi r17, 1
	breq pixel
	cpi r17, 5
	breq pixel
	cpi r17, 6
	breq pixel
	cpi r17, 11
	breq pixel
	cpi r17, 18
	breq pixel
	rjmp no_pixel

	line_3:
	cpi r17, 2
	breq pixel
	cpi r17, 4
	breq pixel
	cpi r17, 6
	breq pixel
	cpi r17, 11
	breq pixel
	cpi r17, 18
	breq pixel
	rjmp no_pixel

	line_4:
	cpi r17, 3
	breq pixel
	cpi r17, 18
	breq pixel
	cpi r17, 6
	brlo no_pixel
	cpi r17, 10
	breq no_pixel
	cpi r17, 15
	brge no_pixel
	rjmp pixel

	line_6n: rjmp line_6
	line_7n: rjmp line_7

	pixel:
	sbi PORTB, 3
	cbi PORTB, 5
	sbi PORTB, 5
	dec r17
	rjmp done_drawing

	no_pixel:
	cbi PORTB, 3
	cbi PORTB, 5
	sbi PORTB, 5
	dec r17
	rjmp done_drawing

	line_5:
	cpi r17, 3
	breq pixel
	cpi r17, 6
	breq pixel
	cpi r17, 11
	breq pixel
	cpi r17, 18
	breq pixel
	rjmp no_pixel

	line_6:
	cpi r17, 3
	breq pixel
	cpi r17, 6
	breq pixel
	cpi r17, 11
	breq pixel
	cpi r17, 18
	breq pixel
	rjmp no_pixel

	line_7:
	cpi r17, 3
	breq pixel
	cpi r17, 18
	breq pixel
	cpi r17, 6
	brlo no_pixel
	cpi r17, 16
	brge no_pixel
	rjmp pixel

