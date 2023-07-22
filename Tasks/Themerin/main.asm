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
// - generate bounds by programming a song in memory
// - receive score based on how well you did (+1 for each time you are inside the borders)

// TO DO
// - generation of bounds
// -> PROBLEMS: - working with 80 bit long screen (bottom and top are wrongly shown)
//				- flickering? 
//				- border length should adjust at edge of window
// -> SOLUTION: 1) flickering solved by redoing screen drawing function (reduced amount of memory loads)
//				2) check if bound should be drawn => OK
//				3) check if upper and lower bound should be drawn in the bottom part of the screen => OK
//				4) condition to check when next border should be drawn => OK
//				5) recalculate border length at edge of screen => OK
//
// - implementation of score (+1 for each time you are inside the borders => no danger of overflow due to border length limitations)
// -> register indicates if tone is in right position
// -> evaluate score during TIMER1 interrupt
//
// - clean up score display
// - fix score calculation

// BOUNDS
// - upper bound defines also lower bound (-2)
// - store in memory bound height and length
// - CHANGE R28 AND R6 WHEN CHANGING AMOUNT OF BOUNDS!!!!!!!!!!!!!!!!!!!!!!!

	//display: top is 1 bottom is 7 (0 is not on display)

; Definition file of the ATmega328P
.include "m328pdef.inc"

;register definitions

; constants

;Boot code
.org 0x0000 rjmp init //ORDER IS IMPORTANT (smallest adress first)
; Interrupt address vectors
.org 0x001A rjmp TIM1_OVF // timer1 interrupt
.org 0x0020 rjmp TIM0_OVF_ISR // timer2 interrupt

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

	//set c pins as input for joystick
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

	ldi r16, 0b01100001 ; last 0001 for adc1 (Joystick up/down)
	sts ADMUX, r16
	
	ldi r16, 0b00000000
	sts ADCSRB, r16

	//SEI ; enable interrupts
	rjmp load_menu

// used global registers: r20 (height of note on screen), r21 (buzzer frequency)
// used registers for tail chase r0, r1, r2, r3, r4
// registers for borders: r10 -> r16, r19
// register for border counter: r25, r28
// used registers for load menu: r20, r21, r22, r18, r24
// used register to indicate end of the game: r28
// used registers for score: r14, r15

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
ldi r20, 16 // 16 blocks fill the entire screen
ldi r18, 8 // select row
ldi r24, 120 // block offset initial value
ldi r22, 0 // offset for each seperate line in memory

Blockloop:
	ldi r17, 8 // offset for each block in memory
	ld r21, -y //predecrement Y and load char value pointed to by Y
	ldi zh, high(CharTable<<1) // load adress table of char into Z
	ldi zl, low(CharTable<<1)
	//calculate offset in table for char
	add zl, r22 // line offset
	brcc next_addition
	inc zh // carry for word
	next_addition:
	add zl, r24 // block offset
	brcc load_data
	inc zh // carry for word
	load_data:
	// load column data
	lpm r21, z
	ldi r23, 5 // only 5 pixels of each line of block is put on the stack
	// send bits to shift register
	BlockColloop:
	cbi portb, 3 //turn pixel off
	clc // clear carry flag
	ror r21
	brcc CarryIs1 //skip line if C = 0
	sbi portb, 3 // turn pixel on
	CarryIs1:
	cbi portb, 5 // put pixel in shift register
	sbi portb, 5
	dec r23 // only 5 pixels of each line of block is put on the stack
	brne BlockColloop

	subi r24, 8 // decrease blockoffset with 8
	dec r20 // decrease block counter
	brne blockloop
	rjmp loop2_menu

	jump_to_load_menu_setup:
	rjmp load_menu_setup

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

	ldi r20, 16 // reset r20 back to 16 for next line of screen
	ldi r24, 120 // reset r24 back to 120 for next line of screen
	sbi portb, 4
	cbi portb, 4
	inc r22 // increase line offset => next line of each block is read from memory for next line on display
	dec r18 // decrease line "selector" of display
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
SEI // enable interrupts (timer0 and timer1)
SBI PORTD, 3 // turn off row 3 (otherwise can glitch back to main menu when pressing "C")
ldi r20, 0 // reset position of pixel set by joystick
ldi r25, 0 // reset counter that sets the position of the boundaries on the screen
mov r5, r25 // r15 keeps track of the score (reset to zero)
mov r15, r25
main:

; runs through all lines of display and checks wether a pixel should be on
	ldi r19, 0
	mov r14, r19 // register 14 is used to keep track wether the joystick is inbetween the borders
	ldi r18, 8 ; select row
	ldi r28, 96 //2 * rows * #borders (this is used to check whether no bounds are on the screen => no bounds means end of game)
	outer_loop: 
		ldi r17, 80 // select column
		cpi r18, 1 // only convert joystick position to frequency when row 1 of display is selected (no need to do it for each row of the display)
		brne continue
		call get_tone // translates position of joystick into a discrete set of frequencies
		continue:
		call drawing // draws position of joystick + it's tail + borders

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

	mov r9, r14 // do timer1 interrupt gets value of r14 AFTER the whole screen has been updated
	cpi r28, 0 // if r28 is 0 => no borders on screen => game has end
	breq score_menu_setup // jump to load screen if game has ended

	SBI PORTD, 0 //check row 3
	SBI PORTD, 1
	CBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4 // if 0 is pressed, jump to loadscreen
		rjmp load_menu_setup
		SBI PORTD, 2 // turn of row 3 to avoid glitches
    rjmp main

// ----------------------------- SCORE MENU --------------------------------
score_menu_setup:
CLI
// convert score into digits r0 -> r2 (r0 contains 100s, r1 contains 10s, r2 contains 1s)
// only needs to be done once in the score menu
ldi r16, 0
mov r2, r16 //reset r0 -> r3
mov r3, r16
mov r4, r16
mov r16, r5 // move r5 to r16 so we can use cpi
digit100: //get all the 100s digits by substracting 100 until r16 < 100
cpi r16, 100
brlo digit10
subi r16, 100
inc r2
rjmp digit100
digit10: //get all the 10s digits by substracting 10 until r16 < 10
cpi r16, 10
brlo digit1
subi r16, 10
inc r3
rjmp digit10
digit1: //get all the 1s digits by substracting 1 until r16 =0
cpi r16, 0
breq multiply_with_8
subi r16, 1
inc r4
rjmp digit1

multiply_with_8:
ldi r19, 8 // r1 should always be zero since 9*8 < 255
mul r2, r19
mov r2, r0
mul r3, r19
mov r3, r0
mul r4, r19
mov r4, r0

score_menu:
ldi yh, high(0x010F) // last char should be send first on screen
ldi yl, low(0x010F)
ldi r20, 16 // 16 blocks fill the entire screen
ldi r18, 8 // select row
ldi r24, 40 // block offset initial value
ldi r22, 0 // offset for each seperate line in memory

Blockloop_score:
	ldi r17, 8 // offset for each block in memory
	ld r21, -y //predecrement Y and load char value pointed to by Y
	ldi r23, 5 // only 5 pixels of each line of block is put on the stack
	//calculate offset in table for char
	cpi r20, 12
	brsh zeros_on_screen //show empty blocks for r20 > 13 (after digits of score)
	cpi r20, 9
	brsh score_on_screen // show the score on the screen
	cpi r20, 7
	brsh zeros_on_screen // show empty blocks after the wod "score" on the top part of the screen
	ldi zh, high(ScoreTable<<1) // load adress table of char into Z
	ldi zl, low(ScoreTable<<1)
	add zl, r22 // line offset
	brcc next_addition_score
	inc zh // carry for word
	next_addition_score:
	add zl, r24 // block offset
	brcc load_data_score
	inc zh // carry for word
	load_data_score:
	// load column data
	lpm r21, z
	subi r24, 8 // decrease blockoffset with 8
	rjmp BlockColloop_score

	score_on_screen: // use register r2 -> r4 for each digit
	ldi zh, high(DigitsTable<<1) // load adress table of char into Z
	ldi zl, low(DigitsTable<<1)
	add zl, r22 // line offset
	brcc next_addition_digit
	inc zh // carry for word
	next_addition_digit:

	cpi r20, 9
	brne digit10_
	add zl, r2 // block offset
	brcc digit100_load
	inc zh // carry for word
	digit100_load:
	lpm r21, z
	rjmp BlockColloop_score

	digit10_:
	cpi r20, 10
	brne digit1_
	add zl, r3 // block offset
	brcc digit10_load
	inc zh // carry for word
	digit10_load:
	lpm r21, z
	rjmp BlockColloop_score

	digit1_:
	add zl, r4 // block offset
	brcc digit1_load
	inc zh // carry for word
	digit1_load:
	lpm r21, z
	rjmp BlockColloop_score

	zeros_on_screen:
	ldi r21, 0
	// send bits to shift register
	BlockColloop_score:
	cbi portb, 3 //turn pixel off
	clc // clear carry flag
	ror r21
	brcc CarryIs1_score //skip line if C = 0
	sbi portb, 3 // turn pixel on
	CarryIs1_score:
	cbi portb, 5 // put pixel in shift register
	sbi portb, 5
	dec r23 // only 5 pixels of each line of block is put on the stack
	brne BlockColloop_score
	dec r20 // decrease block counter
	brne blockloop_score
	rjmp loop2_menu_score

	loop2_menu_score:
		cp r17, r18
		brne skip_menu_score
		sbi PORTB, 3
		rjmp setrow_menu_score
		skip_menu_score:
		cbi PORTB, 3
		setrow_menu_score:
		cbi PORTB, 5
		sbi PORTB, 5
		dec r17
		brne loop2_menu_score

	ldi r20, 16 // reset r20 back to 16 for next line of screen
	ldi r24, 40 // reset r24 back to 120 for next line of screen
	sbi portb, 4
	cbi portb, 4
	inc r22 // increase line offset => next line of each block is read from memory for next line on display
	dec r18 // decrease line "selector" of display
	brne temp_Blockloop_score

	// PRESS A TO START
	SBI PORTD, 0 //check row 3
	SBI PORTD, 1
	CBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4 // if 0 is pressed, jump to main menu
		rjmp load_menu_setup
    rjmp score_menu

	temp_Blockloop_score:
	rjmp Blockloop_score


//------------------------------ GET TONE ----------------------------------

	get_tone:
	// this function turns different positional regions of the joystick into discrete tones used for the buzzer (reg 21) (C->B)
	// it also generates a value used to display the position of the joystick on the screen (reg 20)
	// conversion from reg 21 value to frequency is done using matlab (see "note_to_freq_conv.m")
	lds r20, ADCH // MSB stored in ADCH due to values set in ADC setup
	cpi r20, 230 // compare the value from the adc to different preset values and assign a note/tone to each region
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

	drawing:
	 // IS CALLED FOR EACH ROW
	// draws position of joystick + it's tail + borders

	// HOW TO BORDERS WORK:
	// - the memory has a copy of the 'level' it consists of a series of borders. the memory contains x, y, length of border but also for wich r25 values it should be drawn (this is to increase speed)
	// - the x position is only for the bottom part of the border so to get the top part a substraction of 2 needs to be performed for each border
	// - the borders are ordened in the memory in the oposite direction then how the level progresses since the display needs the pixels most to the right of the display first
	// - the code runs through the borders and see which one needs to be drawn. it will get the length of the border or calculate it when the border crosses the screen edge
	// - it will run through all the borders for the top half of the screen and again for the bottom half of the screen for each iteration (or value of r18)

	mov r4, r20 // for speed (so pointer is faster correct) // r4 contains the current position of the joystick
	continue_with_borders:
	cpi r17, 40 // only when r17 = 40 or 80 the pointer to the borders should be reset to the beginning of the dataset
	breq load_adress
	cpi r17, 80
	brne next_border
	load_adress:
	ldi zh, high(Level<<1) // load adress of first border into z
	ldi zl, low(Level<<1)
	ldi r19, 6
	mov r6, r19 // counter for amount of borders ( r6 = #borders excluding border ending in 25 for y position)
	ldi r19, 40
	mov r7, r19 // for bottom part of display (need to add 40 to get pixels to show on bottom part of screen)
	rjmp next_border

	next_border:
	// if border not on r18 => no need to check it
	lpm r16, z //y position of border
	cpi r16, 25 // if y = 25 then end of border sequence is reached
	breq temp_continue_drawing
	cpi r16, 9 // the score glitches out if the line is between the bottom and top half of the screen (r16 = 8 or 9
	breq push_data
	cpi r16, 8
	brne push_zero
	push_data:
	ldi r24, 1 // use r24 to check wether r16 is 9 or 8
	rjmp no_edge
	push_zero:
	ldi r24, 0
	no_edge:
	cp r16, r18 // only look at rest of data of border if its y-position is equal to the row that has to be drawn
	breq set_top_row
	subi r16, 2 // check for upper part of border
	cp r16, r18 // only look at rest of data of border if its y-position is equal to the row that has to be drawn
	brne top_row_border // if y-position is not equal to r18, then it might be because the y-position belongs to the bottom part of the screen
	set_top_row:
	ldi r19, 0 // to check if its top or bottom of screen
	mov r8, r19 // r8 indicates if the border is part of the top or bottom part of the screen
	rjmp load_data_border
	

	temp_continue_drawing:
	ldi r19, 0 // if x = 25 => went through all the borders so r6 should be 0
	mov r6, r19
	rjmp continue_drawing

	top_row_border:
	subi r16, 5 // substract 7 from y-position to check if border should be drawn on lower half of the screen  add 2 to r16 to compensate for the -2 to check if r16 should be drawn on the top half of the screen 
	cp r16, r18
	breq set_bottom_row
	subi r16, 2 // check for upper part of border
	cp r16, r18
	brne skip_border1
	set_bottom_row:
	ldi r19, 1
	mov r8, r19

	load_data_border: // (r16:y, r10:x, r12:length)
	adiw zl, 1 // +1
	lpm r10, z // min_r25
	adiw zl, 1 // +2
	cp r25, r10 // if r25 < min_r25 the border should not be drawn and is to be skipped
	brlo skip_border2
	lpm r10, z // max_r25
	cp r10, r25 // if r25 > max_r25 the border should not be drawn and is to be skipped
	brlo skip_border2
	adiw z, 1 // +3
	lpm r10, z // x position of border
	adiw z, 1 // +4
	lpm r12, z // length of border
	mov r11, r12 // r11 is used to check how mnay pixels should be on	
	// calculate new border length if border is outside of screen (this only has to be done for the right part of the screen, left part is solved by using r8)
	// if this calculation is not done, other borders on the same screen line will not be drawn
	mov r15, r10 // r15 = x
	add r15, r12 // r15 = x + length of border
	sub r15, r25 // r15 = x + length of border - r25
	mov r13, r7 // r13 = 40
	inc r13 // r13 = 41
	cp r15, r13 // x + length of border - r25 >= 41 => border is beyond screen edge
	brlo draw_border_bottom
	sub r15, r7 // r15 = x + length of border - r25 - 40 => length of border that is off the screen
	sub r11, r15 // r11 => length of border that is on the screen
	inc r11 // increase r11 so the border length matches the wanted border length
	rjmp draw_border_bottom

	skip_border1: // skip border after checking y-position (add total of 8 to z-pointer)
	adiw z, 2
	skip_border2: // skip border after checking min_r25 and max_r25
	adiw z, 6 // add 6 to z-pointer
	dec r28 // if r28 = 0 => no borders on screen
	dec r6 // if r6 = 0 => no borders need to be checked/drawn on that pixel line
	breq continue_drawing
	rjmp next_border

	draw_border_bottom: 
	ldi r19, 1 // add 40 to x position of border should be drawn on the bottom half of the screen
	cp r8 , r19
	brne draw_border
	add r10, r7 // add 40 to shift border to bottom of screen
	draw_border:
	ldi r19, 1
	cp r8, r19 // check if border is on top or bottom half of the screen
	brne no_lower_limit
	cpi r17, 41 // only draw for r17 < 41 if border is on the top half of the screen
	brlo continue_drawing
	rjmp borders
	no_lower_limit:
	cpi r17, 41 // only draw fr r17 >= 41 if border is on the bottom half of the screen
	brsh continue_drawing
	borders:
	mov r16, r10 // move x position to reg 16
	sub r16, r25 // substract r25 from x position => you get current x-position based on the shift caused by r25
	cp r17, r16 // if r17 < r16 => no border for that pixel
	brlt continue_drawing
	add r16, r12 // add length of border to r16
	cp r17, r16 // of r17 < r16 => border should be drawn  => everything between the 'x-position - r25' and the 'x-position - r25 + length of the border' should be drawn 
	brsh continue_drawing
	dec r11 // decrease amount of pixels that are left to draw for the border
	// for score
	cpi r17, 5
	breq top_screen
	cpi r17, 45
	brne pixel
	cpi r24, 1 // if r16 near edge between top and bottom of screen only add 5 to r14 so scoring is correct
	brne add_7
	ldi r19, 5 // load 5 into r19 to add to r14
	rjmp add_5
	add_7:
	ldi r19, 7 // load 7 into r19 to add to r14
	add_5:
	mov r14, r18 //load current line of screen into r14
	add r14, r19 //add 5 or 7 to r14
	rjmp pixel
	top_screen:
	mov r14, r18 //load current line of screen into r14
	rjmp pixel

	continue_drawing: // checks where position of joystick and tail should be drawn
	ldi r23, 0 //upper screen index
	ldi r16, 40 // lower screen index
	ldi r27, 0 // LSB part of address of first pixel
	ldi r26, 0 // MSB part of adress of first pixel
	cpi r17, 46 // tail and joystick are only drawn on the left 5 pixels of the screen so any other r17 values can be ignored
	brge no_pixel
	cpi r17, 40
	brge next_pixel_tail
	cpi r17, 6
	brlo next_pixel_tail
	rjmp no_pixel

	next_pixel_tail:
	// pixel tail is stored in r0->r4
	inc r23 // increase upper screen index
	inc r16 // increase lower screen index
	ld r22, X+ // load data from r0 -> r4 using adress X and increase adress X
	cpi r26, 6 // if r4 is reached, end of tail registers reached, and no pixel should be drawn
	brge no_pixel
	cpi r22, 8 // if y-position of tail >= 8 it should be drawn on the bottom part of the screen
	brsh top_row
	cp r18, r22 // if y-position of tail = r18 then check r17
	brne next_pixel_tail
	cp r17, r23 // if r23 = r17 (correct x-position of tail) then draw tail
	breq pixel
	rjmp next_pixel_tail // run through all the registers used for the tail and check if they should be drawn

	top_row: //(7->11)
	subi r22, 7 // substract 7 from the y-position of the tail so we get a  y-position we can use in the screen
	cp r18, r22 // if y-position of tail = r18 then check r17
	brne next_pixel_tail
	cp r17, r16// if r21 = r17 (correct x-position of tail for bottom part of the screen) then draw tail
	breq pixel
	rjmp next_pixel_tail

	pixel: // turn pixel on
	sbi portb, 3
	rjmp set_pixel_value
	no_pixel: // turn pixel off	
	cbi portb, 3
	set_pixel_value: // push pixel on stack
	cbi PORTB, 5
	sbi PORTB, 5
	dec r17 // decrease column counter
	breq stop_drawing
	cpi r17, 40 // if r17 then the adress for the borders should be loaded in again and borders should be checked again
	breq temp_continue_with_borders
	ldi r19, 0
	cp r6, r19 // if r6 =0 then all borders are checked and there is no need to check them again so only the tail is evaluated
	breq continue_drawing
	cp r11, r19 // if r11 > 0 then more of the selected border should be drawn
	brne temp_draw_border
	adiw z, 4 // add 4 to z-pointer to point to the next border
	temp_continue_with_borders:
	rjmp continue_with_borders // rjmp has larger range then conditional jump so used here
	temp_draw_border:
	rjmp draw_border // rjmp has larger range then conditional jump so used here
	stop_drawing:
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
// timer1 determines at which rate the borders shift to the left (also determines tail shift speed)
	inc r25 // r25 works as a way to shift the borders across the screen
	push r22 // push r22 on stack since it is used here
	push r16
	ldi r22, 0x6F // setup timer1 again to have the same refresh rate
	sts TCNT1H, r22 
	ldi r22, 0xFF
	sts TCNT1L, r22
	mov r0, r1 // shift tail y-positions from right to left for each refresh
	mov r1, r2
	mov r2, r3
	ldi r22, 0
	CBI PORTD, 0 //check row 0
	SBI PORTD, 1
	SBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4 // if C is pressed, jump to sound
		rjmp sound
		mov r3, r22 // if C is pressed, then a tail comes of the pixel that displays the position of the joystick, otherwise the tail dissapears
		pop r16
		pop r22
		SBI PORTD, 0 // avoids return to menu unwanted
		reti
	sound:
	//score
	mov r16, r9
	cp r16, r22 // if r14 = 0 => no boundaries so if C is not pressed +1
	breq no_score
	inc r16
	cp r16, r20
	brne no_score
	score:
	inc r5
	no_score:
	mov r3, r4 // if C is pressed, then a tail comes of the pixel that displays the position of the joystick, otherwise the tail dissapears
	pop r16
	pop r22
	no_push:
	SBI PORTD, 0 // avoids return to menu unwanted
	reti



	//------------ PREDEFINED CHARACTERS --------------------

	CharTable: // bottom => top
	// displays load menu
	.db 0b00000000, 0b00001000, 0b00001000, 0b00001000, 0b00001110, 0b00001001, 0b00001001, 0b00001110  //P adress 0x0100
	.db 0b00000000, 0b00001001, 0b00001001, 0b00001010, 0b00001110, 0b00001001, 0b00001001, 0b00001110  //R
	.db 0b00000000, 0b00001111, 0b00001000, 0b00001000, 0b00001110, 0b00001000, 0b00001000, 0b00001111  //E
	.db 0b00000000, 0b00001110, 0b00000001, 0b00000001, 0b00000110, 0b00001000, 0b00001000, 0b00000111  //S
	.db 0b00000000, 0b00001110, 0b00000001, 0b00000001, 0b00000110, 0b00001000, 0b00001000, 0b00000111  //S
	.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000  // space
	.db 0b00000000, 0b00001001, 0b00001001, 0b00001001, 0b00001111, 0b00001001, 0b00001001, 0b00000110  //A
	.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000  // space
	.db 0b00000000, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00011111  //T
	.db 0b00000000, 0b00000110, 0b00001001, 0b00001001, 0b00001001, 0b00001001, 0b00001001, 0b00000110  //O
	.db 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000, 0b00000000  // space
	.db 0b00000000, 0b00001110, 0b00000001, 0b00000001, 0b00000110, 0b00001000, 0b00001000, 0b00000111  //S
	.db 0b00000000, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00011111  //T
	.db 0b00000000, 0b00001001, 0b00001001, 0b00001001, 0b00001111, 0b00001001, 0b00001001, 0b00000110  //A
	.db 0b00000000, 0b00001001, 0b00001001, 0b00001010, 0b00001110, 0b00001001, 0b00001001, 0b00001110  //R
	.db 0b00000000, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00011111  //T adress 0x010F

	ScoreTable: // displays the word "score"
	.db 0b00000000, 0b00001110, 0b00000001, 0b00000001, 0b00000110, 0b00001000, 0b00001000, 0b00000111  //S
	.db 0b00000000, 0b00000111, 0b00001000, 0b00001000, 0b00001000, 0b00001000, 0b00001000, 0b00000111  //C
	.db 0b00000000, 0b00000110, 0b00001001, 0b00001001, 0b00001001, 0b00001001, 0b00001001, 0b00000110  //O
	.db 0b00000000, 0b00001001, 0b00001001, 0b00001010, 0b00001110, 0b00001001, 0b00001001, 0b00001110  //R
	.db 0b00000000, 0b00001111, 0b00001000, 0b00001000, 0b00001110, 0b00001000, 0b00001000, 0b00001111  //E
	.db 0b00000000, 0b00000000, 0b00001000, 0b00000000, 0b00000000, 0b00000000, 0b00001000, 0b00000000  //:

	DigitsTable:
	.db 0b00000000, 0b00000110, 0b00001001, 0b00001001, 0b00001001, 0b00001001, 0b00001001, 0b00000110 //0
	.db 0b00000000, 0b00000010, 0b00000010, 0b00000010, 0b00000010, 0b00000010, 0b00000110, 0b00000010 //1
	.db 0b00000000, 0b00001111, 0b00001000, 0b00000100, 0b00000010, 0b00000001, 0b00000001, 0b00001110 //2
	.db 0b00000000, 0b00001110, 0b00000001, 0b00000001, 0b00000111, 0b00000001, 0b00000001, 0b00001110 //3
	.db 0b00000000, 0b00000010, 0b00000010, 0b00001111, 0b00001010, 0b00001000, 0b00001000, 0b00001000 //4
	.db 0b00000000, 0b00001110, 0b00000001, 0b00000001, 0b00000110, 0b00001000, 0b00001000, 0b00001111 //5
	.db 0b00000000, 0b00000110, 0b00001001, 0b00001001, 0b00001110, 0b00001000, 0b00001000, 0b00000110 //6
	.db 0b00000000, 0b00000100, 0b00000100, 0b00000100, 0b00000100, 0b00000010, 0b00000001, 0b00001111 //7
	.db 0b00000000, 0b00000110, 0b00001001, 0b00001001, 0b00000110, 0b00001001, 0b00001001, 0b00000110 //8
	.db 0b00000000, 0b00000110, 0b00000001, 0b00000001, 0b00000111, 0b00001001, 0b00001001, 0b00000110 //9

	Level:
	.db 11, 50, 92, 90, 2, 0, 0, 0
	.db 7, 40, 85, 80, 5, 0, 0, 0
	.db 9, 30, 80, 70, 10, 0, 0, 0 
	.db 5, 21, 65, 61, 4, 0, 0, 0
	.db 3, 5, 50, 45, 5, 0, 0, 0
	.db 13, 0, 42, 40, 2, 0, 0, 0 
	.db 25, 0, 0, 0, 0, 0, 0, 0
	//y, min_r25, max_r25, x, length
	// should be in reverse order
	// us of limits for r25 to minimize screen flickering
	// min_r25 = x - 40
	// max_r25 = x + length
	// assume: no 2 borders on the same pixel column

	// MAX 16 BORDERS => ELSE OVERFLOW ON R28
	// max_r25 can be maximum 215 since we need to add 40 if its drawn on bottom half of screen
	

