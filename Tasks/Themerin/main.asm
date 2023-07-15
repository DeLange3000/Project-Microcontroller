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
// - load screen using character buffer (buzzer does not work in loading screen)
// - Press A to start game press 0 to go to menu
// - move joystick up/down to select frequency in scale (position regions of joystick mapped to different frequencies)
// - point on screen indicates position of joystick
// - press C to make a sound (play a note). Point on screen gets tail
// - game where you try to stay within bounds. Play notes when bounds are visible on point
// - receive score based on how well you did
// - generate bounds by programming a song in memory

// TO DO
// - generation of bounds (17/07 -> 18/07) (create song and save in memory and implement randomizer)
// - implementation of score (19/07 -> 21/07) (not in bounds or playing too long or not -> substract from score (lower limit it to zero!))

// BOUNDS
// - upper bound defines also lower bound (-2)
// - store in memory bound height and length (max height is 14, max length is 40)


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
// registers for borders: r10 -> r16, r19
// register for border counter: r25
// used registers for load menu: r20, r21, r22, r18, r24
// used register to indicate end of the game: r5

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
ldi yh, high(0x010F) // last char should be send first on screen
ldi yl, low(0x010F)
ldi r20, 16
ldi r18, 8 ;select row
ldi r24, 120 // block offset initial value
ldi r22, 0

Blockloop:
	ldi r17, 8
	ld r21, -y //predecrement Y and load char value pointed to by Y
	ldi zh, high(CharTable<<1) // load adress table of char into Z
	ldi zl, low(CharTable<<1)
	//calculate offset in tavle for char
	add zl, r22 // line offset
	brcc next_addition
	inc zh
	next_addition:
	add zl, r24 // block offset
	brcc load_data
	inc zh
	load_data:
	// load column data
	lpm r21, z
	ldi r23, 5
	// send bits to shift register
	BlockColloop:
	cbi portb, 3
	clc // clear carry flag
	ror r21
	brcc CarryIs1 //skip line if C = 0
	sbi portb, 3
	CarryIs1:
	cbi portb, 5
	sbi portb, 5
	dec r23
	brne BlockColloop

	subi r24, 8 //increase blockoffset with 8
	dec r20
	brne blockloop

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

	ldi r20, 16 //reset r20 back to 16
	ldi r24, 120
	sbi portb, 4
	cbi portb, 4
	inc r22
	dec r18
	brne Blockloop

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
ldi r20, 0
ldi r25, 0
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

		SBI PORTB, 4 // enable each row
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
	brne check_border
	cp r17, r23
	breq pixel
	rjmp check_border

	top_row: //(7->11)
	subi r22, 7
	cp r18, r22
	brne check_border
	cp r17, r24
	breq pixel
	rjmp check_border


	check_border:
	ldi zh, high(Level<<1) // load adress table of char into Z
	ldi zl, low(Level<<1)
	ldi r19, 0
	mov r6, r19
	next_border:
	ldi r19, 0
	ldi r16, 1
	lpm r10, z // x position of border
	cp r10, r19
	breq no_pixel // end of sequence reached when r10 = 0
	adiw zl, 1
	lpm r11, z // y position of border
	adiw zl, 1
	lpm r12, z // length of border
	mov r13, r10
	sub r10, r25
	cp r13, r10 //see of number got negative
	brlo negative //brge is signed! (workaround)
	rjmp not_negative

	negative:
	dec r12
	breq skip_border
	inc r10
	cp r10, r16
	breq not_negative
	rjmp negative

	not_negative:
	inc r6 // keeps track of how many borders are visible
	cp r10, r19
	brne next_
	increase:
	inc r10
	next_:
	cp r10, r16
	brlo skip_border
	
	cp r18, r11
	brne bottom_border
	cp r17, r10
	brlo skip_border
	add r10, r12
	cp r17, r10
	brlo pixel
	
	bottom_border:
	ldi r19, 2
	add r11, r19
	cp r18, r11
	brne skip_border
	cp r17, r10
	brlo skip_border
	add r10, r12
	cp r17, r10
	brlo pixel

	skip_border:
	adiw z, 6 //only 6 since +2 to get all the data
	rjmp next_border

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

	ldi r19, 0
	cp r6, r19
	brne not_end_of_game
	rjmp load_menu_setup // game has ended
	not_end_of_game:
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

	//--------------- BORDER SHIFTING-------------------

/*	shift_borders:
	ldi r19, 0
	push r0
	push r1
	mov r0, r19
	mov r1, r19
	ldi zh, high(Level<<1) // load adress table of char into Z
	ldi zl, low(Level<<1)
	shift_next_border:
	lpm r1, z // x position of border
	cp r1, r19
	breq skip_border
	//dec r10
	spm
	adiw z, 2
	lpm r10, z
	cp r10, r19
	breq stop_shifting
	adiw z, 6
	rjmp shift_next_border

	stop_shifting:
	ret*/


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
	inc r25
	push r22
	ldi r22, 0x6F
	sts TCNT1H, r22
	ldi r22, 0xFF
	sts TCNT1L, r22
	mov r0, r1
	mov r1, r2
	mov r2, r3
	//call shift_borders
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



	




	//------------ PREDEFINED CHARACTERS --------------------

	CharTable: // bottom => top
	.db 0b00000000, 0b00001000, 0b00001000, 0b00001000, 0b00001111, 0b00001001, 0b00001001, 0b00001111  //P adress 0x0100
	.db 0b00000000, 0b00001001, 0b00001001, 0b00001010, 0b00001110, 0b00001001, 0b00001001, 0b00001110  //R
	.db 0b00000000, 0b00001111, 0b00001000, 0b00001000, 0b00001110, 0b00001000, 0b00001000, 0b00001111  //E
	.db 0b00000000, 0b00001111, 0b00000001, 0b00000001, 0b00001111, 0b00001000, 0b00001000, 0b00001111  //S
	.db 0b00000000, 0b00001111, 0b00000001, 0b00000001, 0b00001111, 0b00001000, 0b00001000, 0b00001111  //S
	.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000  // space
	.db 0b00000000, 0b00001001, 0b00001001, 0b00001001, 0b00001111, 0b00001001, 0b00001001, 0b00000110  //A
	.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000  // space
	.db 0b00000000, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00001111  //T
	.db 0b00000000, 0b00000110, 0b00001001, 0b00001001, 0b00001001, 0b00001001, 0b00001001, 0b00000110  //O
	.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000  // space
	.db 0b00000000, 0b00001111, 0b00000001, 0b00000001, 0b00001111, 0b00001000, 0b00001000, 0b00001111  //S
	.db 0b00000000, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00001111  //T
	.db 0b00000000, 0b00001001, 0b00001001, 0b00001001, 0b00001111, 0b00001001, 0b00001001, 0b00000110  //A
	.db 0b00000000, 0b00001001, 0b00001001, 0b00001010, 0b00001110, 0b00001001, 0b00001001, 0b00001110  //R
	.db 0b00000000, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00001111  //T adress 0x010F


	Level:
	.db 1, 3, 10, 0, 0, 0, 0, 0 // x, y, length
	.db 13, 5, 5, 0, 0, 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0

