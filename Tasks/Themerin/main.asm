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


// FEATURE OVERVIEW
// - load screen using character buffer
// - Press A to start game press 0 to go to menu
// - move joystick up/down to select frequency in scale (position regions of joystick mapped to different frequencies)
// - point on screen indicates position of joystick
// - press C to make a sound (play a note). Point on screen gets tail
// - game where you try to stay within bounds. Play notes when bounds are visible on point
// - receive score based on how well you did
// - generate bounds with randomizer? or program song? (both?)

// TO DO
// - load screen using character buffer (13/07)
// - generation of bounds (15/07 -> 18/07) (create song and save in memory and implement randomizer)
// - implementation of score (19/07 -> 21/07) (not in bounds or playing too long or not -> substract from score (lower limit it to zero!))


; Definition file of the ATmega328P
.include "m328pdef.inc"

;register definitions

; constants

;Boot code
.org 0x0000 rjmp init //ORDER IS IMPORTANT (smallest adress first)	A
.org 0x001A rjmp TIM1_OVF
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
	LDI R21, 185 ; register 21 controls frequency
	out TCNT0, R21

	ldi r16, 0b00000011
	out TCCR0B,r16 ; Timer clock = system clock / 64
	ldi r16,1<<TOV0
	out TIFR0,r16 ; Clear TOV0/ Clear pending interrupts
	ldi r16,1<<TOIE0
	sts TIMSK0,r16 ; Enable Timer/Counter0 Overflow Interrupt

	// timer1 setup (used to refresh screen)
	// only overflow is used
	ldi r16, 0xEF; register 21 controls frequency
	sts TCNT1H, r16
	ldi r16, 0xFF
	sts TCNT1L, r16
	ldi r16, 0b00000011
	sts TCCR1B,r16 ; Timer clock = system clock / 1024
	ldi r16,1<<TOV1
	sts TIFR1,r16 ; Clear TOV1/ Clear pending interrupts
	ldi r16,1<<TOIE1
	sts TIMSK1,r16 ; Enable Timer/Counter1 Overflow Interrupt



	// ADC setup
	ldi r16, 0b11111111
	sts didr0, r16

	ldi r16, 0b11111111
	sts didr1, r16

	ldi r16, 0b00000000
	sts prr, r16

	ldi r16, 0b11100010
	sts ADCSRA, r16

	ldi r16, 0b01100001 ; last 0000 for adc0
	sts ADMUX, r16
	
	ldi r16, 0b00000000
	sts ADCSRB, r16


	//SEI ; enable interrupts
	

	rjmp load_menu

// used global registers: r20 (height of note on screen), r21 (buzzer frequency)
// used registers for tail chase r0, r1, r2, r3, r4

// ------------------- LOAD MENU ------------------------------
load_menu_setup:
CLI //disable interrupts so that buzzer does not work in load menu
ldi r20, 0
mov r0, r20 // initialize tail (placed here so tail is gone after reloading)
mov r1, r20
mov r2, r20
mov r3, r20
mov r4, r20
load_menu:
; runs through all lines of display and checks wether a pixel should be on
	ldi r18, 8 ;select row
	outer_loop_menu:
		ldi r17, 80 ;select column
		loop1_menu:
			call drawing_loading_screen //screen buffer (PRESS A TO START)
			dec r17 // decrease column counter
			brne loop1_menu

		next_loop_menu:
		ldi r17, 8
		loop2_menu:
			cp r17, r18
			brne skip_menu
			sbi PORTB, 3
			rjmp setrow_menu
			skip_menu:
			cbi PORTB, 3
			setrow_menu:
			cbi PORTB, 5
			sbi PORTB, 5
			dec r17
			brne loop2_menu

		CBI PORTB, 4 // enable each row
		SBI PORTB, 4
		CBI PORTB, 4
		dec r18
	brne outer_loop_menu

	// PRESS A TO START
	SBI PORTD, 0 //check row 3
	SBI PORTD, 1
	SBI PORTD, 2
	CBI PORTD, 3
		SBIS PIND, 4 // if A is pressed, jump to main
		rjmp setup_main
    rjmp load_menu


// ------------------ DISPLAY --------------------------
setup_main:
SEI
SBI PORTD, 3

main:
; runs through all lines of display and checks wether a pixel should be on
	ldi r18, 8 ;select row
	outer_loop:
		ldi r17, 80 ;select column
		loop1:
			cpi r18, 8
			brne continue
			call get_tone
			continue:
			call drawing 
			dec r17 // decrease column counter
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

	SBI PORTD, 0 //check row 3
	SBI PORTD, 1
	CBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4 // if 0 is pressed, jump to loadscreen
		rjmp load_menu_setup
		SBI PORTD, 2
    rjmp main


//------------------------------ GET TONE ----------------------------------

//converts regions of the ADC value of the joysytick into tones
//also gets the height of the tone for the display
	get_tone:

	lds r20, ADCH // MSB stored in ADCH due to values set in ADC setup
	cpi r20, 230
	brsh note_C
	cpi r20, 220
	brsh note_Csharp
	cpi r20, 198
	brsh note_D
	cpi r20, 176
	brsh note_Dsharp
	cpi r20, 154
	brsh note_E
	cpi r20, 132
	brsh note_F
	cpi r20, 110
	brsh note_Fsharp
	cpi r20, 88
	brsh note_G
	cpi r20, 66
	brsh note_Gsharp
	cpi r20, 44
	brsh note_A
	cpi r20, 30
	brsh note_Asharp

	//display: top is 1 bottom is 7 (0 is not on display)

	// note B
	ldi r21, 129
	ldi r20, 2
	ret

	note_C:
	ldi r21, 17
	ldi r20, 13
    ret

	note_Csharp:
	ldi r21, 30
	ldi r20, 12
	ret

	note_D:
	ldi r21, 43
	ldi r20, 11
	ret

	note_Dsharp:
	ldi r21, 55
	ldi r20, 10
	ret

	note_E:
	ldi r21, 66
	ldi r20, 9
	ret

	note_F:
	ldi r21, 77
	ldi r20, 8
	ret

	note_Fsharp:
	ldi r21, 87
	ldi r20, 7
	ret

	note_G:
	ldi r21, 97
	ldi r20, 6
	ret

	note_Gsharp:
	ldi r21, 106
	ldi r20, 5
	ret

	note_A:
	ldi r21, 114
	ldi r20, 4
	ret

	note_Asharp:
	ldi r21, 122
	ldi r20, 3
	ret

//-------------------------- DRAWING ---------------------------------

// decides where a pixel should be on or off

	drawing: // IS CALLED FOR EVERY PIXEL
	mov r4, r20 // for speed (so pointer is faster correct)
	ldi r23, 1 //upper screen index
	ldi r24, 41 // lower screen index
	ldi r27, 0 // address of first pixel
	ldi r26, 0
	continue_drawing:
	ld r22, X+ // load data from r0 -> r4 using adress X and increase adress X
	cpi r22, 8
	brsh top_row
	cp r18, r22
	brne no_pixel
	cp r17, r23
	breq pixel
	rjmp no_pixel

	top_row: //(7->11)
	subi r22, 7
	cp r18, r22
	brne no_pixel
	cp r17, r24
	breq pixel
	rjmp no_pixel

	pixel: // turn pixel on
	sbi portb, 3
	rjmp set_pixel_value
	no_pixel: // turn pixel off	
	cpi r23, 5
	breq stop_drawing
	inc r24
	inc r23
	rjmp continue_drawing
	stop_drawing:
	cbi portb, 3
	set_pixel_value: // push pixel on stack
	cbi PORTB, 5
	sbi PORTB, 5
	ret


	// ------------------ DRAWING LOADING SCREEN ----------------------

	drawing_loading_screen:

	pixel_menu: // turn pixel on
	sbi portb, 3
	rjmp set_pixel_value_menu
	no_pixel_menu: // turn pixel off	
	cbi portb, 3
	set_pixel_value_menu: // push pixel on stack
	cbi PORTB, 5
	sbi PORTB, 5
	ret

// ------------ TIMER INTERRUPT ----------------------------
TIM0_OVF_ISR:
	// checks just row 0 since only button C is used
	CBI PORTD, 0 //check row 0
	SBI PORTD, 1
	SBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4 // if C is pressed, jump to output_C
		rjmp buzzz
		sbi portc, 3 // turn led off if C is not pressed
		SBI PORTD, 0 // avoids return to menu unwanted
	reti

	buzzz:
	cbi portc, 3
	out TCNT0, R21 // set value of buzzer
	SBI PINB, 1 // make buzzer go bzzzzzzzzzzzz
	SBI PORTD, 0 // avoids return to menu unwanted
	reti

TIM1_OVF: // higher r22 => faster
	push r22
	ldi r22, 0x6F
	sts TCNT1H, r22
	ldi r22, 0xFF
	sts TCNT1L, r22
	mov r0, r1
	mov r1, r2
	mov r2, r3
	CBI PORTD, 0 //check row 0
	SBI PORTD, 1
	SBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4 // if C is pressed, jump to output_C
		rjmp sound
		ldi r22, 0
		mov r3, r22
		pop r22
		SBI PORTD, 0 // avoids return to menu unwanted
		reti
	sound:
	mov r3, r4
	pop r22
	SBI PORTD, 0 // avoids return to menu unwanted
	reti