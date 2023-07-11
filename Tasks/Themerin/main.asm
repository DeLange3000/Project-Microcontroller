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

	ldi r16, 0b00000100
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

	// ---------- TURN VALUE FROM BUZZER INTO DISPLAYABLE VALUE ----------------------

		//how to get get frequency:
		// f_clk = 16 Mhz/ 256 = 62500² Hz
		// f_buzzer = f_clk/r20

		cpi r18, 8 ; only calculate what number needs to be shown, when the row of the screen is equal to 8
		brne check66
		call get_hertz // transforms register value to frequency value in r22 (LSB) and r23 (MSB); values: 0-9999

		mov r30, r24 // copy result from r25:r24 to r31:30 so SBIW can be used
		mov r31, r25

		;ldi r30, 0b11010010 ;  testers
		;ldi r31, 0b00000100

		//mov r30, r20 // use this to display buzzer register value
		//ldi r31, 0

		// --------------- extract digits from register r30 (LSB) and r31 (MSB) to show on display --------------

		// factor 1000
		check22:
		ldi r24, 0 //r24 counts how many times 1000 fits in word r31:r30
		check2:
		cpi r31, 3 
		brlo check33 // if lower value in r31:r30 < 1000
		cpi r31, 4 
		brlo extra_check // if lower value in r31:r30 MIGHT be < 1000
		not_yet:
		ldi r23, 15 //load loop index
		substraction_loop: //substracts 945 from r31:r30 in steps of 63 since 63 is max value for SBIW
		sbiw r30, 63 // 63 is max value for SBIW
		dec r23 // decrease loop index
		brne substraction_loop
		sbiw r30, 55 //substract another 55 to get 1000 substracted from r31:r30
		inc r24  // keeps track of how many 1000's are in r31:r30
		rjmp check2  // keep looping if value in r31:r30 >= 1000

		extra_check: //check if r31:r30 is actually < 1000
		cpi r30, 0b11101000 // checks if r30 < 232
		brlo check33 // if r30 < 232, move to factor 100
		rjmp not_yet //jump back inf r30 >= 232 (since r31:r30 >= 1000)

		// factor 100
		check33:
		adiw r30, 50 // add 100 to r30 to compensate for jumping to factor 100 without increasing r23 in last loop
		adiw r30, 50 // done in two steps since 63 is max value for ADIW
		ldi r23, 0 // r23 keeps track of how many 100's are in r31:r30
		check3:
		sbiw r30, 50 // substract 100 from r31:r30
		sbiw r30, 50
		cpi r31, 0 // check if r31 is zero (means max value in r31:r30 is now 255 since everything is now in r30)
		brne no_100 // jump to increase r23 without checking r30
		cpi r30, 100 // check if r30 < 100
		brlo check44 // if r30 < 100 no more 100's present in r31:r30
		no_100:
		inc r23  // keeps track of how many 100's are in r31:r30
		rjmp check3 // loop as long as r30 >= 100

		// factor 10
		check44:
		adiw r30, 10 // add 10 to r30 to compensate for jumping to factor 10 without increasing r23 in last loop
		ldi r22, 0 // r22 keeps track of how many 10's are in r30 ( r31 is empty now)
		check4:
		subi r30, 10 // substract 10 from r30
		cpi r30, 10 // if r30 < 10 jump to factor 1 (no more 10's present in r30)
		brlo check55
		inc r22  // keeps track of how many 10's are in r30
		rjmp check4

		// factor 1
		check55:
		ldi r28, 0 // r28 keeps track of how many 10's are in r30 ( r31 is empty now)
		adiw r30, 1 // add 1 to r30 to compensate for jumping to factor 1 without increasing r23 in last loop
		check5:
		subi r30, 1 // substract 1 from r30
		cpi r30, 0 // if r30 = 0 jump to check66 (no more 1's present in r30) => conversion to digits is complete
		breq check66
		inc r28  // keeps track of how many 1's are in r30
		rjmp check5

		check66:
		// ------------- DRAW NUMBERS -------------------
		// draws 1's first and 1000's last since everything has to be pushed on display stack

		// r31 is used to check wich number needs to be drawn
		// r26 is the offset that determines where the number is drawn on the screen

		// 1's
		mov r21, r28
		ldi r26, 69
		call draw1 // checks wich pixel needs to be drawn

		cpi r27, 1 // only draws pixel if r27 is set to 1 else check other digits
		breq temp_pixel // inbetween jump (branch out of reach)

		// 10's
		mov r21, r22
		ldi r26, 63
		call draw1

		cpi r27, 1
		breq temp_pixel

		// 100's
		mov r21, r23
		ldi r26, 57
		call draw1

		cpi r27, 1
		breq pixel

		// 1000's
		mov r21, r24
		ldi r26, 51
		call draw1

		cpi r27, 1
		breq pixel
		rjmp skip_pixel // so inbetween jump label is not used
		
		// inbetween jump label
		temp_pixel:
		rjmp pixel

		skip_pixel:


		// ------------ DRAW "Hz" -------------------------------------------
		
		// checks which row is selected and pushes bits on stack to draw "Hz"
		cpi r18, 7
		breq Hz_row_7
		cpi r18, 6
		breq Hz_row_6
		cpi r18, 5
		breq Hz_row_5
		cpi r18, 4
		breq Hz_row_4
		cpi r18, 3
		breq Hz_row_3

		Hz_row_1:
		cpi r17, 71
		breq pixel
		cpi r17, 75
		breq pixel
		rjmp no_pixel

		Hz_row_3:
		cpi r17, 71
		breq pixel
		cpi r17, 80
		breq no_pixel
		cpi r17, 75
		brge pixel
		rjmp no_pixel

		Hz_row_4:
		cpi r17, 78
		breq pixel
		cpi r17, 76
		brge no_pixel
		cpi r17, 71
		brge pixel
		rjmp no_pixel

		Hz_row_5:
		cpi r17, 71
		breq pixel
		cpi r17, 75
		breq pixel
		cpi r17, 77
		breq pixel
		rjmp no_pixel

		Hz_row_6:
		cpi r17, 71
		breq pixel
		cpi r17, 75
		breq pixel
		cpi r17, 76
		breq pixel
		rjmp no_pixel

		Hz_row_7:
		cpi r17, 80
		breq no_pixel
		cpi r17, 71
		breq pixel
		cpi r17, 75
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

		// ----------- NUMBER SELECTOR -------------------------
		
		// uses branching and then function call since function call cannot be made in branching condition
		draw1:
		cpi r21, 0
		breq draw_0
		cpi r21, 1
		breq draw_1
		cpi r21, 2
		breq draw_2
		cpi r21, 3
		breq draw_3
		cpi r21, 4
		breq draw_4
		cpi r21, 5
		breq draw_5
		cpi r21, 6
		breq draw_6
		cpi r21, 7
		breq draw_7
		cpi r21, 8
		breq draw_8
		cpi r21, 9
		breq draw_9
		//rjmp draw_0 // could draw zero if value in register is bigger then 9
		ret

		// calls correct function to draw number
		draw_0:
		call draw_zero
		ret
		draw_1:
		call draw_one
		ret
		draw_2:
		call draw_two
		ret
		draw_3:
		call draw_three
		ret
		draw_4:
		call draw_four
		ret
		draw_5:
		call draw_five
		ret
		draw_6:
		call draw_six
		ret
		draw_7:
		call draw_seven
		ret
		draw_8:
		call draw_eight
		ret
		draw_9:
		call draw_nine
		ret

// ------------- ZERO --------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number
draw_zero:
mov r25, r26
cpi r18, 7
breq hor_line
cpi r18, 1
breq hor_line

vert_line: // draws vertical lines of zero
cp r17, r25
breq pixel0
subi r25, 4
cp r17, r25
breq pixel0
rjmp skip_pixel0

hor_line: // draws horizontal lines of zero
cp r17, r25
brge skip_pixel0
subi r25, 3
cp r17, r25
brge pixel0
rjmp skip_pixel0

pixel0: // sets r27 to 1 if pixel needs to be on (pixel drawing is done by drawing function
ldi r27, 1
rjmp set_pixel_value0
skip_pixel0:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value0:
ret

// --------------------- ONE ----------------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number

draw_one:
mov r25, r26
subi r25, 2
cpi r18, 2
breq part1_1
cp r17, r25
breq pixel1
rjmp skip_pixel1

part1_1:
cp r17, r25
breq pixel1
subi r25, 1
cp r17, r25
breq pixel1
rjmp skip_pixel1

pixel1:
ldi r27, 1 // sets r27 to 1 if pixel needs to be drawn (pixel drawing is done by drawing function
rjmp set_pixel_value1
skip_pixel1:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value1:
ret
// --------------------- TWO ------------------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number

draw_two:
mov r25, r26
cpi r18, 1
breq topline2
cpi r18, 7
breq bottomline2
cpi r18, 4
brlo part2_1
cpi r18, 4
breq middleline2

part2_2:
subi r25, 4
cp r17, r25
breq pixel2
rjmp skip_pixel2

topline2:
cp r17, r25
brge skip_pixel2
subi r25, 4
cp r17, r25
brge pixel2
rjmp skip_pixel2

bottomline2:
ldi r16, 1
add r25, r16
cp r17, r25
brge skip_pixel2
subi r25, 5
cp r17, r25
brge pixel2
rjmp skip_pixel2

middleline2:
ldi r16, 1
add r25, r16
cp r17, r25
brge skip_pixel2
subi r25, 4
cp r17, r25
brge pixel2
rjmp skip_pixel2

part2_1:
cp r17, r25
breq pixel2
rjmp skip_pixel2

pixel2:
ldi r27, 1 // sets r27 to 1 if pixel needs to be drawn (pixel drawing is done by drawing function
rjmp set_pixel_value2
skip_pixel2:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value2:
ret

// ------------------ THREE -----------------------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number

draw_three:
mov r25, r26
cpi r18, 1
breq vert_3
cpi r18, 4
breq vert_3_middle
cpi r18, 7
breq vert_3

hor_3:
cp r17, r25
breq pixel3
rjmp skip_pixel3

vert_3:
cp r17, r25
brge skip_pixel3
subi r25, 4
cp r17, r25
brge pixel3
rjmp skip_pixel3

vert_3_middle:
cp r17, r25
breq pixel3
brge skip_pixel3
subi r25, 4
cp r17, r25
brge pixel3
rjmp skip_pixel3

pixel3:
ldi r27, 1 // sets r27 to 1 if pixel needs to be drawn (pixel drawing is done by drawing function
rjmp set_pixel_value3
skip_pixel3:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value3:
ret

// ----------------- FOUR -------------------------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number

draw_four:
mov r25, r26
cpi r18, 5
brge part1_4
cpi r18, 4
breq part2_4
cpi r18, 3
breq part3_4

part4_4:
subi r25, 4
cp r17, r25
breq pixel4
rjmp skip_pixel4

part1_4:
subi r25, 2
cp r17, r25
breq pixel4
rjmp skip_pixel4

part2_4:
cp r17, r25
brge skip_pixel4
subi r25, 4
cp r17, r25
brge pixel4
rjmp skip_pixel4

part3_4:
subi r25, 2
cp r17, r25
breq pixel4
subi r25, 2
cp r17, r25
breq pixel4
rjmp skip_pixel4


pixel4:
ldi r27, 1 // sets r27 to 1 if pixel needs to be drawn (pixel drawing is done by drawing function
rjmp set_pixel_value4
skip_pixel4:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value4:
ret

// ----------------- FIVE ------------------------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number

draw_five:
mov r25, r26
cpi r18, 1
breq topline5
cpi r18, 4
brlo part1_5
cpi r18, 4
breq middleline5
cpi r18, 7
breq middleline5

part2_5:
cp r17, r25
breq pixel5
rjmp skip_pixel5

topline5:
cp r17, r25
breq pixel5
cp r17, r25
brge skip_pixel5
subi r25, 4
cp r17, r25
brge pixel5
rjmp skip_pixel5

middleline5:
cp r17, r25
brge skip_pixel5
subi r25, 4
cp r17, r25
brge pixel5
rjmp skip_pixel5

part1_5:
subi r25, 4
cp r17, r25
breq pixel5
rjmp skip_pixel5

pixel5:
ldi r27, 1 // sets r27 to 1 if pixel needs to be drawn (pixel drawing is done by drawing function
rjmp set_pixel_value5
skip_pixel5:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value5:
ret

// ------------------ SIX ---------------------------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number

draw_six:
mov r25, r26
cpi r18, 1
breq horiz_6
cpi r18, 4
breq horizmiddle_6
cpi r18, 7
breq horiz_6
cpi r18, 5
brlo vert1_6

vert2_6:
cp r17, r25
breq pixel6
subi r25, 4
cp r17, r25
breq pixel6
rjmp skip_pixel6

vert1_6:
subi r25, 4
cp r17, r25
breq pixel6
rjmp skip_pixel6

horiz_6:
cp r17, r25
brge skip_pixel6
subi r25, 3
cp r17, r25
brge pixel6
rjmp skip_pixel6

horizmiddle_6:
cp r17, r25
brge skip_pixel6
subi r25, 4
cp r17, r25
brge pixel6
rjmp skip_pixel6


pixel6:
ldi r27, 1 // sets r27 to 1 if pixel needs to be drawn (pixel drawing is done by drawing function
rjmp set_pixel_value6
skip_pixel6:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value6:
ret
// ------------------- SEVEN --------------------------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number

draw_seven:
mov r25, r26
cpi r18, 1
breq top7
cpi r18, 2
breq part6_7
cpi r18, 4
brlo part5_7

part4_7:
subi r25, 2
cp r17, r25
breq pixel7
rjmp skip_pixel7

top7:
cp r17, r25
breq pixel7
brge skip_pixel7
subi r25, 4
cp r17, r25
brge pixel7
rjmp skip_pixel7

part6_7:
cp r17, r25
breq pixel7
rjmp skip_pixel7

part5_7:
subi r25, 1
cp r17, r25
breq pixel7
rjmp skip_pixel7

pixel7:
ldi r27, 1 // sets r27 to 1 if pixel needs to be drawn (pixel drawing is done by drawing function
rjmp set_pixel_value7
skip_pixel7:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value7:
ret

// ---------------------- EIGHT ----------------------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number

draw_eight:
mov r25, r26
cpi r18, 1
breq horiz_8
cpi r18, 7
breq horiz_8
cpi r18, 4
breq horiz_8

vert_8:
cp r17, r25
breq pixel8
subi r25, 4
cp r17, r25
breq pixel8
rjmp skip_pixel8

horiz_8:
cp r17, r25
brge skip_pixel8
subi r25, 3
cp r17, r25
brge pixel8
rjmp skip_pixel8

pixel8:
ldi r27, 1 // sets r27 to 1 if pixel needs to be drawn (pixel drawing is done by drawing function
rjmp set_pixel_value8
skip_pixel8:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value8:
ret

// ---------------------- NINE ---------------------------------------

// r26 is offset in column of screen
// r25 is used to calculate correct pixel positions based on r26
// r18 is used to check which row needs to be drawn
// r17 is used to check if selected column pixel matches one of the pixels that needs to be drawn for the number

draw_nine:
mov r25, r26
cpi r18, 1
breq horiz_9
cpi r18, 7
breq horiz_9
cpi r18, 4
breq horiz_middle_9
cpi r18, 5
brlo vert_top_9
cpi r18, 6
breq vert_top_9

vert_bottom_9:
cp r17, r25
breq pixel9
rjmp skip_pixel9

vert_top_9:
cp r17, r25
breq pixel9
subi r25, 4
cp r17, r25
breq pixel9
rjmp skip_pixel9

horiz_9:
cp r17, r25
brge skip_pixel9
subi r25, 3
cp r17, r25
brge pixel9
rjmp skip_pixel9

horiz_middle_9:
cp r17, r25
breq pixel9
brge skip_pixel9
subi r25, 3
cp r17, r25
brge pixel9
rjmp skip_pixel9


pixel9:
ldi r27, 1 // sets r27 to 1 if pixel needs to be drawn (pixel drawing is done by drawing function
rjmp set_pixel_value9
skip_pixel9:
ldi r27, 2 // make sure that r27 is not 1 if piwel has to be off
set_pixel_value9:
ret
	
// -------------- GET HERZ VALUE FROM REGISTER -----------------

//how to get get frequency:
// f_clk = 16 Mhz/ 256 = 62500 Hz
// f_buzzer = f_clk/r20

// THIS SECTION NEEDS LOTS OF CYCLES TO CALCULATE FREQUENCY -> LEADS TO SCREEN FLICKER AND BRIGHT TOP LINE OF SCREEN
// note no substraction/addition using words since no K only r23

get_hertz: // tranforms register r20 value into frequency


ldi r24, 0 // r25:r24 is where frequency result is stored
ldi r25, 0 
cpi r20, 0 // no need to do conversion if r20 is zero (is set to zero if button is not pressed)
breq end_Hz

ldi r22, 0b01111010 ; 62500/2 = 31250 stored in r22:r21
ldi r21, 0b00010010
;ldi r22, 0b00000001 ; reduced for better display performance
mov r23, r20 // copy r20 to r23
com r23 // 255 - r23
ldi r26, 0 // used as flag
ldi r27, 1 // used as counter

// loop used to speed up calculation process (might lose accuracy in calculation)
faster_loop:
cp r22, r23 // r22 < r23 skip this loop
brlo devision_loop
sub r22, r23 // substract r23 from r22
inc r25 // increase r25 immediantly instead of r24
rjmp faster_loop

// another loop used to speed up calculation process (might lose accuracy in calculation)
faster_calc:
cpi r23, 0b01000000 // keep shifting r23 to left as long as it is smaller then 0b01000000
brge devision_loop
lsl r23
lsl r27 // also left shift r27 such that correct amount is added to r24
rjmp faster_calc

devision_loop:
cpi r22, 0 // check r22 in r22:21. It should be zero to say loop is done since r23 is only 8 bits and r22 contains 8 MSB from r22:r21
breq maybe_done // it is not necessarly done if only r22 is zero
not_done:
sub r21, r23 // keep substracting r23 from r21
brcs sub_from_r22 // if carry flag is set, also substract 1 from r22
done_subbing: 
clc
add r24, r27 // add r27 to r24 since r24 contains how many times r23 fits in r22:r21
brcs add_to_r25 // if carry flag is set add 1 to r25 since frequency result is stored in r25:r24
done_adding:
rjmp devision_loop // keep looping

sub_from_r22: // if carry flag is set, substract 1 from r22
cpi r26, 1 // if carry flag is set and r26 = 1 (means that r22 is 0) calculaton is done
breq done
dec r22 // sub 1 from r22
rjmp done_subbing // jump back to main loop when substration is done

add_to_r25: // if carry flag is set add 1 to r25 since frequency result is stored in r25:r24
inc r25
rjmp done_adding // jump back to main loop

maybe_done: // if r22 is zero set r26 to 1
ldi r26, 1 // r26 axts as a flag here
rjmp not_done

done:

//this part shifts the result to the left if a simplefied version if 62500 is used
/*ldi r26, 8 // comment this section if working with real value of 62500
ldi r25, 1
shifts:
dec r26
breq end_Hz
lsl r23
lsl r22
brcc shifts
add r23, r25
clc
rjmp shifts*/

end_Hz:
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
	out TCNT0, R20 // set value of buzzer
	SBI PINB, 1 // make buzzer go bzzzzzzzzzzzz
	reti
