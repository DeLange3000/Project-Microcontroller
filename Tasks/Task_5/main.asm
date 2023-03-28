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
	SBI DDRC,2
	SBI PORTC, 2

	rjmp main



main:
	

    rjmp main


TIM0_OVF_ISR: 
	;CBI PORTC,2
	out TCNT0, R31
	SBI PINB, 1
	reti
