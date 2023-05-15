    ;
; Labs.asm
;
; Created: 8/14/2016 7:34:43 AM
; Author : Dario
;


; Replace with your application code
    .include "M328PDEF.INC"
    .org 0x0000
	.org 0x0020 rjmp TIM0_OVF_ISR
start:
    ;ddrx controls the if a pin is in/out, if the pins corresponding bit in the ddr is 1 it's an out, if it's 0 its an in
    ldi r16, 0x00 ; set r16 = 0000 0000
    SBI ddrc, 0 ;set all c pins as input
	SBI ddrc, 1

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
	rjmp prog


    ldi r16, HIGH(RAMEND)
    out SPH, r16
    ldi r16, LOW(RAMEND)
    out SPL, r16



prog:
    ;----------------initialise adc

setADC:

    lds r16,0x00
    STS ADCSRA,R16

    ldi r16,0xC3
    sts ADCSRA,r16
    ldi r16,0x20    ;the 2 sets the bits to be left justified
    sts admux,r16

keepPolling:
    lds R16,ADCSRA
    sbrs R16,4 ;wait for conversion to complete, when conversion is complete the 4th bit in the ADCSRA is set to true therefor skipping the r jump because of sbrs
    jmp keepPolling

    lds r31,ADCL    
    lds r16,ADCH
	rjmp prog


	TIM0_OVF_ISR:
	out TCNT0, R31
	SBI PINB, 1
	reti

    rjmp prog


