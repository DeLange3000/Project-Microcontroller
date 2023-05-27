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

	// display
	sbi DDRB, 3
	sbi PORTB, 3

	sbi DDRB, 5
	sbi PORTB, 5

	sbi DDRB, 4
	sbi PORTB, 4

/*	CBI DDRC, 0 ; set ADC input
	CBI PORTC, 0

	CBI DDRC, 1
	CBI PORTC, 1*/

	SBI DDRC, 2
	SBI PORTC, 2

	SBI DDRC, 3
	SBI PORTC, 3

	;set c pins as input
	cbi ddrc, 1
	cbi ddrc ,0




	LDI R20, 185 ; register 31 controls frequency
	out TCNT0, R20

	ldi r16, 0b00000100
	out TCCR0B,r16 ; Timer clock = system clock / 256
	ldi r16,1<<TOV0
	out TIFR0,r16 ; Clear TOV0/ Clear pending interrupts
	ldi r16,1<<TOIE0
	sts TIMSK0,r16 ; Enable Timer/Counter0 Overflow Interrupt

	ldi r16, 0b11111111
	sts didr0, r16

	ldi r16, 0b11111111
	sts didr1, r16

	ldi r16, 0b00000000
	sts prr, r16

	ldi r16, 0b11101010
	sts ADCSRA, r16

	ldi r16, 0b01100000 ; last 0011 for adc3
	sts ADMUX, r16
	
	ldi r16, 0b00000000
	sts ADCSRB, r16



	SEI


	rjmp main



// register use:

// display: r19, r18, r17
// buzzer: r20
// configs: r16
// for showing number on display: r21
// number display: r25, r26, r22, r24, r23, r27
// herz calculator: r10 -> r15

main:
// ------------------ DISPLAY --------------------------
	ldi r18, 8
	outer_loop:
		ldi r17, 80
		SBI PORTB, 3
		mov r19, r18
		loop:
			sbi PINB, 3
			dec r19
			brne loop

		loop1:
			call drawing
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

		CBI PORTB, 4
		SBI PORTB, 4
		CBI PORTB, 4
		dec r18
	brne outer_loop

    rjmp main


	drawing:

	// ---------- TURN VALUE FROM BUZZER INTO DISPLAYABLE VALUE ----------------------

		//how to get get frequency:
		// f_clk = 16 Mhz/ 256 = 62500² Hz
		// f_buzzer = f_clk/r20

		cpi r18, 8
		brne check66
		call get_hertz // comment this id r20 is used (speeds up display)

		mov r30, r22 // use this to get frequency
		mov r31, r23

		;ldi r30, 0b11010010 ;  testers
		;ldi r31, 0b00000100

		//mov r30, r20 // use this to get register r20 value
		//ldi r31, 0


		check22:
		ldi r24, 0
		check2:
		cpi r31, 3
		brlo check33
		cpi r31, 4
		brlo extra_check
		not_yet:
		ldi r23, 15
		substraction_loop:
		sbiw r30, 63
		dec r23
		brne substraction_loop
		sbiw r30, 55
		inc r24  ; houdt cijfer van de eenheid bij
		rjmp check2

		extra_check:
		cpi r30, 0b11101000
		brlo check33
		rjmp not_yet

		check33:
		adiw r30, 50
		adiw r30, 50
		ldi r23, 0
		check3:
		sbiw r30, 50
		sbiw r30, 50
		cpi r31, 0
		brne no_100
		cpi r30, 100
		brlo check44
		no_100:
		inc r23  ; houdt cijfer van de eenheid bij
		rjmp check3

		check_double:

		check44:
		ldi r22, 10
		add r30, r22
		ldi r22, 0
		check4:
		subi r30, 10
		cpi r30, 10
		brlo check55
		inc r22  ; houdt cijfer van de eenheid bij
		rjmp check4

		check55:
		ldi r28, 0
		adiw r30, 1
		check5:
		subi r30, 1
		cpi r30, 0
		breq check66
		inc r28  ; houdt cijfer van de eenheid bij
		rjmp check5

		check66:

		// ------------- DRAW NUMBERS -------------------

		mov r21, r28
		ldi r26, 70
		call draw1

		cpi r27, 1
		breq temp_pixel

		mov r21, r22
		ldi r26, 65
		call draw1

		cpi r27, 1
		breq temp_pixel

		mov r21, r23
		ldi r26, 60
		call draw1

		cpi r27, 1
		breq pixel

		mov r21, r24
		ldi r26, 55
		call draw1

		cpi r27, 1
		breq pixel
		rjmp skip_pixel
		

		temp_pixel:
		rjmp pixel

		skip_pixel:


		// ------------ DRAW "Hz" -------------------------------------------
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

		pixel:
		sbi portb, 3
		rjmp set_pixel_value
		no_pixel:
		cbi portb, 3
		set_pixel_value:
		cbi PORTB, 5
		sbi PORTB, 5
		dec r17
		reti

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
		//rjmp draw_0
		reti

		draw_0:
		call draw_zero
		reti
		draw_1:
		call draw_one
		reti
		draw_2:
		call draw_two
		reti
		draw_3:
		call draw_three
		reti
		draw_4:
		call draw_four
		reti
		draw_5:
		call draw_five
		reti
		draw_6:
		call draw_six
		reti
		draw_7:
		call draw_seven
		reti
		draw_8:
		call draw_eight
		reti
		draw_9:
		call draw_nine
		reti

// ------------- ZERO --------------------------
draw_zero:
mov r25, r26
cpi r18, 7
breq hor_line
cpi r18, 1
breq hor_line

vert_line:
cp r17, r25
breq pixel0
subi r25, 4
cp r17, r25
breq pixel0
rjmp skip_pixel0

hor_line:
cp r17, r25
brge skip_pixel0
subi r25, 3
cp r17, r25
brge pixel0
rjmp skip_pixel0

pixel0:
ldi r27, 1
rjmp set_pixel_value0
skip_pixel0:
ldi r27, 2
set_pixel_value0:
reti

// --------------------- ONE ----------------------------------
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
ldi r27, 1
rjmp set_pixel_value1
skip_pixel1:
ldi r27, 2
set_pixel_value1:
reti
// --------------------- TWO ------------------------------------
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
ldi r27, 1
rjmp set_pixel_value2
skip_pixel2:
ldi r27, 2
set_pixel_value2:
reti

// ------------------ THREE -----------------------------------------
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
ldi r27, 1
rjmp set_pixel_value3
skip_pixel3:
ldi r27, 2
set_pixel_value3:
reti

// ----------------- FOUR -------------------------------------------
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
ldi r27, 1
rjmp set_pixel_value4
skip_pixel4:
ldi r27, 2
set_pixel_value4:
reti

// ----------------- FIVE ------------------------------------------
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
ldi r27, 1
rjmp set_pixel_value5
skip_pixel5:
ldi r27, 2
set_pixel_value5:
reti

// ------------------ SIX ---------------------------------------------
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
ldi r27, 1
rjmp set_pixel_value6
skip_pixel6:
ldi r27, 2
set_pixel_value6:
reti
// ------------------- SEVEN --------------------------------------------
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
ldi r27, 1
rjmp set_pixel_value7
skip_pixel7:
ldi r27, 2
set_pixel_value7:
reti

// ---------------------- EIGHT ----------------------------------------
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
ldi r27, 1
rjmp set_pixel_value8
skip_pixel8:
ldi r27, 2
set_pixel_value8:
reti

// ---------------------- NINE ---------------------------------------
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
ldi r27, 1
rjmp set_pixel_value9
skip_pixel9:
ldi r27, 2
set_pixel_value9:
reti
	
// -------------- GET HERZ VALUE FROM REGISTER -----------------

		//how to get get frequency:
		// f_clk = 16 Mhz/ 256 = 62500 Hz
		// f_buzzer = f_clk/r20

get_hertz:


ldi r23, 0
ldi r24, 0
cpi r20, 0
breq end_Hz

ldi r22, 0b01111010 ; 62500/2 = 31250
;ldi r22, 0b00000001 ; reduced for better display performance
ldi r21, 0b00010010
mov r23, r20
com r23
ldi r25, 0
ldi r26, 0
ldi r27, 1

faster_loop:
cp r22, r23
brlo devision_loop
sub r22, r23
inc r25
rjmp faster_loop

faster_calc:
cpi r23, 0b01000000
brge devision_loop
lsl r23
lsl r27
rjmp faster_calc

devision_loop:
cpi r22, 0
breq maybe_done
not_done:
sub r21, r23
brcs sub_from_r22
done_subbing:
clc
add r24, r27
brcs add_to_r25
done_adding:
rjmp devision_loop

sub_from_r22:
cpi r26, 1
breq done
dec r22
rjmp done_subbing

add_to_r25:
inc r25
rjmp done_adding

maybe_done:
ldi r26, 1
rjmp not_done

done:
mov r22, r24
mov r23, r25

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

reti


// ------------ TIMER INTERRUPT ----------------------------
TIM0_OVF_ISR:
	CBI PORTD, 0 //check row 0
	SBI PORTD, 1
	SBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4
		rjmp output_C
		sbi portc, 3
	reti

	output_C:
	CBI portc, 3
		
	out TCNT0, R20
	SBI PINB, 1
	reti

// --------------------- ADC CONVERSION INTERRUPT ---------------------

ADC_COMPLETE:
/*	CBI PORTC, 3 ;led 3 on
	CBI PORTC, 2 ; led 2 on*/

	CBI PORTD, 0 //check row 0
	SBI PORTD, 1
	SBI PORTD, 2
	SBI PORTD, 3
		SBIS PIND, 4
		rjmp output_C_ADC
		sbi portc, 3

	ldi r20, 0
	reti
	output_C_ADC:
	CBI portc, 3
	lds r20, ADCL
	lds r20, ADCH

	
	
	


	reti