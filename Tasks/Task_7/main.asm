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
	
	//LEDs
	SBI DDRC, 3
	SBI PORTC, 3

	SBI DDRC, 2
	SBI PORTC, 2

	//buzzer
	SBI DDRB, 1
	SBI PORTB, 1

	LDI R31, 185
	out TCNT0, R31

	ldi r16,1<<CS02
	out TCCR0B,r16 ; Timer clock = system clock / 256
	ldi r16,1<<TOV0
	out TIFR0,r16 ; Clear TOV0/ Clear pending interrupts
	ldi r16,1<<TOIE0
	sts TIMSK0,r16 ; Enable Timer/Counter0 Overflow Interrupt
	SEI
	rjmp main



main:
	SBI PORTC, 2 //turn of leds
	SBI PORTC, 3

	CBI PORTD, 0 //check row 0
	CBI PORTD, 1
	CBI PORTD, 2
	CBI PORTD, 3
		SBIS PIND, 4
		rjmp get_key
		SBIS PIND, 5
		rjmp get_key
		SBIS PIND, 6
		rjmp get_key
		SBIS PIND, 7
		rjmp get_key
		CLI
		rjmp main


get_key:
	CBI PORTD, 0 //check row 0
	SBI PORTD, 1
	SBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4
		rjmp output_C
		SBIS PIND, 5
		rjmp output_D
		SBIS PIND, 6
		rjmp output_E
		SBIS PIND, 7
		rjmp output_F


	SBI PORTD, 0 //check row 1
	CBI PORTD, 1
	SBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4
		rjmp output_B
		SBIS PIND, 5
		rjmp output_3
		SBIS PIND, 6
		rjmp output_6
		SBIS PIND, 7
		rjmp output_9

	SBI PORTD, 0 //check row 2
	SBI PORTD, 1
	CBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4
		rjmp output_0
		SBIS PIND, 5
		rjmp output_2
		SBIS PIND, 6
		rjmp output_5
		SBIS PIND, 7
		rjmp output_8

	SBI PORTD, 0 //check row 3
	SBI PORTD, 1
	SBI PORTD, 2
	CBI PORTD, 3
		SBIS PIND, 4
		rjmp output_A
		SBIS PIND, 5
		rjmp output_1
		SBIS PIND, 6
		rjmp output_4
		SBIS PIND, 7
		rjmp output_7
	SBI PORTD, 3

	rjmp main

	output_0:
		ldi r31, 220
		rjmp buzzer

	output_1:
		ldi r31, 210
		rjmp buzzer

	output_2:
		ldi r31, 200
		rjmp buzzer

	output_3:
		ldi r31, 190
		rjmp buzzer

	output_4:
		CBI PORTC, 2
		rjmp main

	output_5:
		ldi r31, 180
		rjmp buzzer

	output_6:
		ldi r31, 170
		rjmp buzzer

	output_7:
		CBI PORTC,2
		CBI PORTC, 3
		rjmp main

	output_8:
		CBI PORTC, 3
		rjmp main

	output_9:
		ldi r31, 160
		rjmp buzzer

	output_A:
		ldi r31, 150
		rjmp buzzer

	output_B:
		ldi r31, 140
		rjmp buzzer

	output_C:
		ldi r31, 130
		rjmp buzzer

	output_D:
		ldi r31, 120
		rjmp buzzer

	output_E:
		ldi r31, 110
		rjmp buzzer

	output_F:
		ldi r31, 100
		rjmp buzzer

	buzzer:
		SEI
		rjmp main
		

	TIM0_OVF_ISR: 
	;CBI PORTC,2
	out TCNT0, R31
	SBI PINB, 1
	reti


