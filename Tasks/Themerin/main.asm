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
.org 0x002A rjmp ADC_COMPLETE 


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

	SBI DDRB, 1 ; activate buzzer
	SBI PORTB, 1

	CBI DDRB, 2 ; set up joystick button
	SBI PORTB, 2

/*	CBI DDRC, 0 ; set ADC input
	CBI PORTC, 0

	CBI DDRC, 1
	CBI PORTC, 1*/

	SBI DDRC, 2
	SBI PORTC, 2

	SBI DDRC, 3
	SBI PORTC, 3

	LDI R31, 185 ; register 31 controls frequency
	out TCNT0, R31

	ldi r16,1<<CS02
	out TCCR0B,r16 ; Timer clock = system clock / 256
	ldi r16,1<<TOV0
	out TIFR0,r16 ; Clear TOV0/ Clear pending interrupts
	ldi r16,1<<TOIE0
	sts TIMSK0,r16 ; Enable Timer/Counter0 Overflow Interrupt

	ldi r16, 0b00000011
	sts didr0, r16

	ldi r16, 0b00000000
	sts PRR, r16

	ldi r16, 0b11101111
	sts ADCSRA, r16

	ldi r16, 0b00100001
	sts ADMUX, r16
	
	ldi r16, 0b00000000
	sts ADCSRB, r16



	SEI


	rjmp main



main:

    rjmp main


TIM0_OVF_ISR:
	CBI PORTD, 0 //check row 0
	SBI PORTD, 1
	SBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4
		rjmp output_C

	reti

	output_C:
	out TCNT0, R31
	SBI PINB, 1
	reti



ADC_COMPLETE:
	CBI PORTC, 3 ;led 3 on
	CBI PORTC, 2 ; led 2 on
	;ldi r31, ADCL
	ldi r31, ADCH
	
	


	reti