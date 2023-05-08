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

	/*SBI DDRB, 1 ; activate buzzer
	SBI PORTB, 1*/

	CBI DDRB, 2 
	SBI PORTB, 2

	CBI DDRC, 0 ; set ADC input
	SBI PORTC, 0

	CBI DDRC, 1
	SBI PORTC, 1

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

	ldi r16, 0b11111000
	sts ADCSRA, r16

	ldi r16, 0b00100000
	sts ADMUX, r16
	
	ldi r16, 0b00000000
	sts ADCSRB, r16

	SEI


	rjmp main



main:
	CBI DDRC, 2 
	CBI DDRC, 3


    rjmp main


TIM0_OVF_ISR: 
	in R1, PINB
	BST R1, 2

	BRTC JoyPressed
	out TCNT0, R0
	SBI PINB, 1
	reti

	JoyPressed:
		
		reti


ADC_COMPLETE:
	ldi r16, ADCH
	
	cpi r16, 0b00100000
	brlo left
	rjmp led_off
	reti



	left:
		SBI DDRC, 3
		SBI DDRC, 2
		SBI PORTC, 2 ;led 2 off
		CBI PORTC, 3 ; led 3 on
		reti

	up:
		SBI DDRC, 3
		SBI DDRC, 2
		SBI PORTC, 3 ;led 3 off
		CBI PORTC, 2 ; led 2 on
		reti

	down:
		SBI DDRC, 3
		SBI DDRC, 2
		CBI PORTC, 3 ;led 3 on
		CBI PORTC, 2 ; led 2 on
		reti
	

	led_off:
		SBI DDRC, 3
		SBI DDRC, 2
		SBI PORTC, 3 ;led 2 off
		SBI PORTC, 2 ; led 3 off
		reti


	reti