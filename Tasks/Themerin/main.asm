;
; Themerin.asm
;
; Created: 8/05/2023 14:05:11
; Author : warre
;

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
.org 0x0020 rjmp TIM0_OVF_ISR


; Interrupt address vectors

init:
// ------------------ SETUP ---------------------------
	//keyboard
	SBI DDRD, 0
	SBI PORTD, 0

	SBI DDRD, 1
	SBI PORTD, 1

	SBI DDRD, 2
	SBI PORTD, 2

	SBI DDRD, 3
	SBI PORTD, 3

	CBI DDRD, 4
	SBI PORTD, 4

	CBI DDRD, 5
	SBI PORTD, 5

	CBI DDRD, 6
	SBI PORTD, 6

	CBI DDRD, 7
	SBI PORTD, 7

	// buzzer
	SBI DDRB, 1
	SBI PORTB, 1

	// joystick button
/*	CBI DDRB, 2
	SBI PORTB, 2*/

	// display
	sbi DDRB, 3
	sbi PORTB, 3

	sbi DDRB, 5
	sbi PORTB, 5

	sbi DDRB, 4
	sbi PORTB, 4

	// adc input
/*	CBI DDRC, 0
	CBI PORTC, 0

	CBI DDRC, 1
	CBI PORTC, 1*/

	// leds
	SBI DDRC, 2
	SBI PORTC, 2

	SBI DDRC, 3
	SBI PORTC, 3

	//set c pins as input
	cbi ddrc, 1
	cbi ddrc ,0


	// buzzer setup
	LDI R20, 185 ; register 20 controls frequency
	out TCNT0, R20

	ldi r16, 0b00000011
	out TCCR0B,r16 ; Timer clock = system clock / 256
	ldi r16,1<<TOV0
	out TIFR0,r16 ; Clear TOV0/ Clear pending interrupts
	ldi r16,1<<TOIE0
	sts TIMSK0,r16 ; Enable Timer/Counter0 Overflow Interrupt

	// ADC setup
	ldi r16, 0b11111111
	sts didr0, r16

	ldi r16, 0b11111111
	sts didr1, r16

	ldi r16, 0b00000000
	sts prr, r16

	ldi r16, 0b11100010
	sts ADCSRA, r16

	ldi r16, 0b01100000 ; last 0000 for adc0
	sts ADMUX, r16
	
	ldi r16, 0b00000000
	sts ADCSRB, r16


	SEI ; enable interrupts
	ldi r20, 0
	rjmp main

main:
// ------------------ DISPLAY --------------------------

; runs through all lines of display and checks wether a pixel should be on
	ldi r18, 8 ;select row
	outer_loop:
		ldi r17, 80 ;select column
		SBI PORTB, 3
		loop:
			sbi PINB, 3
			dec r19
			brne loop
		loop1:
			call drawing ; function draws numbers and "Hz" on display
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

		CBI PORTB, 4 // enable each row
		SBI PORTB, 4
		CBI PORTB, 4
		dec r18
	brne outer_loop
    rjmp main


	drawing: // IS CALLED FOR EVERY PIXEL

	cp r18, r20
	brne next_row
	cpi r17, 40
	brlo pixel
	rjmp no_pixel

	next_row:
	subi r20, 8
	cp r18, r20
	brne no_pixel
	cpi r17, 40
	brge pixel
	rjmp no_pixel

	pixel: // turn pixel on
	sbi portb, 3
	rjmp set_pixel_value
	no_pixel: // turn pixel off
	cbi portb, 3
	set_pixel_value: // push pixel on stack
	cbi PORTB, 5
	sbi PORTB, 5
	dec r17 // decrease column counter
	ret

// ------------ TIMER INTERRUPT ----------------------------
TIM0_OVF_ISR:
	// checks just row 0 since only button C is used
	CBI PORTD, 0 //check row 0
	SBI PORTD, 1
	SBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4 // if C is pressed, jump to output_C
		rjmp output_C
		sbi portc, 3 // turn led off if C is not pressed
		ldi r20, 0
	reti

	output_C:
	CBI portc, 3 // turn led on if C is pressed
	lds r20, ADCH // MSB stored in ADCH due to values set in ADC setup
	cpi r20, 22
	brlo note_C
	cpi r20, 44
	brlo note_Csharp
	cpi r20, 66
	brlo note_D
	cpi r20, 88
	brlo note_Dsharp
	cpi r20, 110
	brlo note_E
	cpi r20, 132
	brlo note_F
	cpi r20, 154
	brlo note_Fsharp
	cpi r20, 176
	brlo note_G
	cpi r20, 198
	brlo note_Gsharp
	cpi r20, 220
	brlo note_A
	cpi r20, 242
	brlo note_Asharp

	// note B
	lds r21, 129
	lds r20, 13
	rjmp buzzz

	note_C:
	lds r21, 17
	lds r20, 2
	rjmp buzzz

	note_Csharp:
	lds r21, 30
	lds r20, 3
	rjmp buzzz

	note_D:
	lds r21, 43
	lds r20, 4
	rjmp buzzz

	note_Dsharp:
	lds r21, 55
	lds r20, 5
	rjmp buzzz

	note_E:
	lds r21, 66
	lds r20, 6
	rjmp buzzz

	note_F:
	lds r21, 77
	lds r20, 7
	rjmp buzzz

	note_Fsharp:
	lds r21, 87
	lds r20, 8
	rjmp buzzz

	note_G:
	lds r21, 97
	lds r20, 9
	rjmp buzzz

	note_Gsharp:
	lds r21, 106
	lds r20, 10
	rjmp buzzz

	note_A:
	lds r21, 114
	lds r20, 11
	rjmp buzzz

	note_Asharp:
	lds r21, 122
	lds r20, 12
	rjmp buzzz

	buzzz:
	out TCNT0, R20 // set value of buzzer
	SBI PINB, 1 // make buzzer go bzzzzzzzzzzzz
	reti
