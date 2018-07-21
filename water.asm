.include "tn461def.inc"
.include "start.asm"
.include "lcd_44780.asm"
.include "snes_controller.asm"
.include "eeprom.asm"

.cseg

.def	tmp_freq = r9
.def	pulseL = r10
.def	pulseH = r11
.def	counter = r12
.def	freq = r13
.def	lcd_x_pos = r14
.def	lcd_y_pos = r15

.def	tmp = r16
.def	tmp2 = r17
.def	tmp3 = r18
.def	fade = r19
.def	pulse_frame = r20
.def	rint = r21
.def	save_position = r22
.def	pattern_counter = r23

.def	int_pulseH = r25
.def	int_pulseL = r24


		;===LED interrupt timing
.equ	clock_divide = 400
.equ	clock_divide_high = high(0xFFFF - clock_divide)
.equ	clock_divide_low = low(0xFFFF - clock_divide)

int_timings:
;khz:	0     1     2     3     4     5     6     7     8    9   10   11   12   13   14   15   16   17   18   19   20
.dw		0, 4000, 2000, 1333, 1000,  800,  667,  571,  500, 444, 400, 364, 333, 308, 286, 267, 250, 235, 222, 211, 200
.dw		0, 8000, 4000, 2667, 2000, 1600, 1333, 1143, 1000, 889, 800, 727, 667, 615, 571, 533, 500, 471, 444, 421, 400
.dw		0,  500,  250,  167,  125,  100,   83,   71,   63,  56,  50,  45,  42,  38,  36,  34,  31,  29,  28,  26,  25

.equ	rint_new_frame = 1
.equ	rint_new_second = 2
.equ	rint_keep_brightness = 4

.equ	PORT_CELL = PORTB
.equ	PIN_CELL = PINB
.equ	DDR_CELL = DDRB
.equ	CELL_HOT = PB7

.equ	PORT_SPEAKER = PORTB
.equ	DDR_SPEAKER = DDRB
.equ	SPEAKER_OUT = PB6

.equ	CS_STOP = 0
.equ	CS_NO_PRESCALING = 1
.equ	CS_DIV8 = 2
.equ	CS_DIV64 = 3
.equ	CS_DIV256 = 4
.equ	CS_DIV1024 = 5

.equ	EEPROM_SAVE_SLOTS = 42
.equ	FREQUENCIES = 63



default_pattern:
.db		0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, "________"


RESET:
	ldi		r16, low(RAMEND)
	ldi		r17, high(RAMEND)
	out		SPL, r16				; Set Stack Pointer to top of RAM
	out		SPH, r17				; Tiny461 have also SPH

	;ldi		r16, RAMEND
	;out		SPL, r16				; Set Stack Pointer to top of RAM

	;ldi		int_pulseH, 0xaa
	;ldi		int_pulseL, 0xaa

	;rcall	load_seed
	rcall	clear_regs

	ldi		tmp, 0
	out		TCNT0H, tmp		;clear timer
	out		TCNT0L, tmp
	ldi		tmp, 0x0
	out		OCR0A, tmp		;clear compare value
	out		OCR0B, tmp

	ldi		tmp, (1<<TCW0)	;16bit timer/counter0
	out		TCCR0A, tmp
	ldi		tmp, CS_NO_PRESCALING
	out		TCCR0B, tmp		;set the prescaler bit/enable timer
	ldi		tmp, 0
	rcall	set_timer


	ldi		tmp, (1<<OCIE0A) | (1<<WGM00);(1<<TOIE0)
	out		TIMSK, tmp		;enable TIM0_OVF interrupt

	sei

	;ldi		tmp, clock_divide_high
	;out		TCNT0H, tmp		;set the timer high
	;ldi		tmp, clock_divide_low
	;out		TCNT0L, tmp		;set the timer low

	;ldi		tmp, 0xFF
	;out		DDRA, tmp		;set all ports as output
	;out		DDRB, tmp

	;clr		tmp
	;out		PORTA, tmp
	;out		PORTB, tmp

	;cbi		switch_port, switch_bit		;input for flicker/constant switch

	;sbr		rint, (1<<rint_new_second)
	;sbr		rint, (1<<rint_new_frame)


main:

	rcall	init_snes				;set i/o pins
	rcall	init_lcd				;set i/o pins
	sbi		PORT_LCD, LCD_LED		;turn backlight on
	rcall	clear_lcd_buffer
	rcall	load_pattern			;loads default wave pattern
	rcall	update_pulse_bits
	rcall	upload_controller_error_screen

	sbi		DDR_SPEAKER, SPEAKER_OUT

	clr		counter


s:
	rcall	update_lcd

	rcall	read_snes
	lds		r17, snes_lower		;make sure it's plugged in
	cbr		r17, 0x0F
	cpi		r17, 0x00
	brne	not_in
	rjmp	process_input
not_in:
	rcall	controller_error
	rjmp	s

process_input:
	lds		r17, snes_upper_single

	in		r16, PORT_LCD		;toggle backlight with START
	ldi		r18, 1 << LCD_LED
	sbrc	r17, SNES_START
	eor		r16, r18
	;inc		save_position
	cbr		r17, 1 << SNES_START
	out		PORT_LCD, r16

	;sbrc	r17, SNES_START
	;inc		save_position
	;cpi		save_position, 10
	;brlo	s_start
	;clr		save_position 
	;s_start:
	;cbr		r17, 1 << SNES_START

	sbrs	r17, SNES_SELECT	;inc counter with SELECT
	rjmp	process_up
	mov		tmp, counter
	cpi		tmp, 0
	breq	s_select_load

	mov		tmp_freq, counter
	clr		counter
	clr		tmp
	rjmp	s_select_done

	s_select_load:
	mov		counter, tmp_freq
	mov		tmp, counter

	s_select_done:
	rcall	set_timer
	cbr		r17, 1 << SNES_SELECT

	process_up:
	;mov		r16, lcd_y_pos		;sets lcd_y_pos to 0 if UP is pressed
	;sbrc	r17, SNES_UP
	;ldi		r16, 0
	;cbr		r17, 1 << SNES_UP
	;mov		lcd_y_pos, r16

	;mov		r16, lcd_y_pos		;sets lcd_y_pos to 1 if DOWN is pressed
	;sbrc	r17, SNES_DOWN
	;ldi		r16, 1
	;cbr		r17, 1 << SNES_DOWN
	;mov		lcd_y_pos, r16

	mov		r16, save_position		;incs save_position if less than EEPROM_SAVE_SLOTS if UP is pressed
	sbrc	r17, SNES_UP
	inc		r16
	cpi		r16, EEPROM_SAVE_SLOTS + 1
	brlo	s_up
	ldi		r16, 0					;going over EEPROM_SAVE_SLOTS resets value to 0
	s_up:
	cbr		r17, 1 << SNES_UP
	mov		save_position, r16

	mov		r16, save_position		;decs save_position if greater than 0 if DOWN is pressed
	sbrc	r17, SNES_DOWN
	dec		r16
	cpi		r16, 0
	brge	s_down
	ldi		r16, EEPROM_SAVE_SLOTS	;going below 0 sets save_position to highest value EEPROM_SAVE_SLOTS
	s_down:
	cbr		r17, 1 << SNES_DOWN
	mov		save_position, r16

	mov		r16, lcd_x_pos		;decs lcd_x_pos if greater than 0 if LEFT is pressed
	sbrc	r17, SNES_LEFT
	dec		r16
	cpi		r16, 0
	brge	s_left
	ldi		r16, 0
	s_left:
	cbr		r17, 1 << SNES_LEFT
	mov		lcd_x_pos, r16
	
	
	mov		r16, lcd_x_pos		;incs lcd_x_pos if less than 16 if RIGHT is pressed
	sbrc	r17, SNES_RIGHT
	inc		r16
	cpi		r16, 16
	brlo	s_right
	ldi		r16, 15
	s_right:
	cbr		r17, 1 << SNES_RIGHT
	mov		lcd_x_pos, r16


	sbrs	r17, SNES_Y		;changes pulse display bytes when Y is pressed
	rjmp	s_done
	ldi		YH, high(lcd_display)
	ldi		YL, low(lcd_display)
	adiw	Y, 16

	push	lcd_x_pos
	add		YL, lcd_x_pos
	brcc	invert_character
	inc		YH
	invert_character:

	ld		tmp, Y			;load the character at lcd_x_pos
	cpi		tmp, 0xFF
	breq	pulse_low
	ldi		tmp, 0xFF		;if the character is not FF, then make it FF
	rjmp	pulse_done
	pulse_low:				;change the full bar (FF) into '_'
	ldi		tmp, '_'
	pulse_done:
	pop		lcd_x_pos
	st		Y, tmp
	cbr		r17, 1 << SNES_Y

	rcall	update_pulse_bits		;convert 16 byte display characters to 16bit

	s_done:
	sts		snes_upper_single, r17		;update the single value in ram

	lds		r17, snes_lower_single		;get lower value for other 4 buttons

	sbrs	r17, SNES_L			;dec counter with L
	rjmp	process_R
	dec		counter
	mov		tmp, counter
	cpi		tmp, 0
	brge	s_l
	ldi		tmp, FREQUENCIES - 1
	mov		counter, tmp
	s_l:
	rcall	set_timer
	cbr		r17, 1 << SNES_L



;------------------------
	;mov		r16, save_position		;incs save_position if less than EEPROM_SAVE_SLOTS if UP is pressed
	;sbrc	r17, SNES_UP
	;inc		r16
	;cpi		r16, EEPROM_SAVE_SLOTS + 1
	;brlo	s_up
	;ldi		r16, 0					;going over EEPROM_SAVE_SLOTS resets value to 0
	;s_up:
	;cbr		r17, 1 << SNES_UP
	;mov		save_position, r16
;-----------------------



	process_r:
	sbrs	r17, SNES_R			;inc counter with R
	rjmp	process_x
	inc		counter
	mov		tmp, counter
	cpi		tmp, FREQUENCIES
	brlo	s_r
	clr		tmp
	clr		counter
	
	s_r:
	rcall	set_timer
	cbr		r17, 1 << SNES_R

	process_x:
	sbrs	r17, SNES_X			;load from eeprom with X
	rjmp	process_A
	push	r17
	clr		r18
	mov		r17, save_position
	add		r17, save_position
	add		r17, save_position		;multiply by 3

	rcall	read_eeprom		;address = r18:r17 returns data = r16
	mov		pulseH, r16
	inc		r17
	rcall	read_eeprom
	mov		pulseL, r16
	inc		r17
	rcall	read_eeprom
	cpi		r16, FREQUENCIES
	brlo	process_x_good_freq
	ldi		r16, FREQUENCIES - 1

	process_x_good_freq:
	mov		counter, r16
	mov		tmp, r16
	rcall	set_timer
	rcall	display_pulse_bits

	pop		r17
	cbr		r17, 1 << SNES_X

	process_A:
	sbrs	r17, SNES_A
	rjmp	s_counter_done

	push	r17
	clr		r18
	mov		r17, save_position
	add		r17, save_position
	add		r17, save_position		;multiply by 3
	mov		r16, pulseH
	rcall	write_eeprom
	inc		r17
	mov		r16, pulseL
	rcall	write_eeprom
	inc		r17
	mov		r16, counter
	rcall	write_eeprom

	pop		r17
	cbr		r17, 1 << SNES_A


	s_counter_done:
	sts		snes_lower_single, r17		;update the single value in ram
	
	ldi		ZH, high(lcd_display)
	ldi		ZL, low(lcd_display)	;get pointer to lcd buffer
	mov		r16, lcd_x_pos		;convert x and y pos into sram pointer
	sbrc	lcd_y_pos, 0
	sbr		r16, 16
	add		ZL, r16

	ld		r16, Z					;read byte from current position in lcd buffer
	lds		r17, snes_upper_single	;inc r16 with Y, dec with B
	sbrc	r17, SNES_Y
	inc		r16
	cbr		r17, 1 << SNES_Y
	sbrc	r17, SNES_B
	dec		r16
	cbr		r17, 1 << SNES_B
	sts		snes_lower_single, r17
	st		Z, r16

	ldi		ZH, high(lcd_display)	;get LCD buffer
	ldi		ZL, low(lcd_display)

	mov		r16, pulseH
	or		r16, pulseL
	breq	counter_off

	mov		r16, counter			;show counter
	tst		r16
	breq	counter_off
	cpi		r16, 100		;make sure counter is 99 or less
	brsh	counter_100
	sbiw	Z, 1
	counter_100:

	cpi		r16, 10		;make sure counter is 9 or less
	brsh	counter_10
	sbiw	Z, 1
	counter_10:

	rjmp	counter_khz

	counter_off:
	ldi		tmp, 'O'
	st		Z+, tmp
	ldi		tmp, 'F'
	st		Z+, tmp
	ldi		tmp, 'F'
	st		Z+, tmp
	ldi		tmp, ' '
	st		Z+, tmp
	st		Z+, tmp
	st		Z+, tmp

	rjmp	khz_displayed

	counter_khz:
	rcall	hex2dec
	ldi		tmp, 'K'
	st		Z+, tmp
	ldi		tmp, 'h'
	st		Z+, tmp
	ldi		tmp, 'z'
	st		Z+, tmp
	ldi		tmp, ' '
	st		Z+, tmp
	st		Z+, tmp
	
	khz_displayed:

	ldi		ZH, high(lcd_display)
	ldi		ZL, low(lcd_display)
	adiw	Z, 13
	mov		r16, save_position
	rcall	hex2dec

	ldi		ZH, high(lcd_display)
	ldi		ZL, low(lcd_display)
	adiw	Z, 8				;starting position of FILE
	cpi		save_position, 10
	brge	file_leading_zero
	adiw	Z, 1
	file_leading_zero:

	ldi		tmp, ' '
	st		Z+, tmp
	ldi		tmp, 'F'
	st		Z+, tmp
	ldi		tmp, 'I'
	st		Z+, tmp
	ldi		tmp, 'L'
	st		Z+, tmp
	ldi		tmp, 'E'
	st		Z+, tmp
	ldi		tmp, ' '
	st		Z+, tmp

	;lds		r16, snes_lower
	;in		r16, TCNT0H

	;mov		r16, int_pulseL;TCNT0L
	;rcall	hex2dec


	;lds		r18, SNES_LOWER
	;ldi		r16, ' '
	;sbrc	r18, SNES_A
	;ldi		r16, 'A'
	;rcall	send_LCD
	;rcall	wait_160_us

	rjmp	s

	;in		tmp, PORTA
	;eor		tmp, r17
	;out		PORTA, tmp
	;rjmp	main
	;sbic	switch_port_in, switch_bit
	;rcall	set_constant
	;sbrc	rint, rint_new_second
	;rcall	new_second
	;sbrc	rint, rint_new_frame
	;rcall	new_frame

	
	rjmp	main

update_pulse_bits:		;tmp = value from sram, tmp2 = shifted bit mask, tmp3 = 8 bit binary version of lcd
	ldi		YH, high(lcd_display)
	ldi		YL, low(lcd_display)
	adiw	Y, 16			;location of first character on second line

	ldi		tmp2, 0x80		;bitmask, starts at leftmost bit, shifts to finish on the rightmost bit
	clr		tmp3

	pulse_bit_loop:
	ld		tmp, Y+
	inc		tmp				;compare character to FF
	brne	pulse_bit_low	;if not FF, leave bit blank
	or		tmp3, tmp2		;set bit based on bitmask

	pulse_bit_low:
	lsr		tmp2			;shift bit mask for next loop
	brne	pulse_bit_loop	;loop if bits are left

	mov		pulseH, tmp3

	;do it again for lower 8 bits
	ldi		tmp2, 0x80		;bitmask
	clr		tmp3

	pulse_bit_loop2:
	ld		tmp, Y+
	inc		tmp				;compare to full bar value, 0xFF
	brne	pulse_bit_low2
	or		tmp3, tmp2

	pulse_bit_low2:
	lsr		tmp2
	brne	pulse_bit_loop2

	mov		pulseL, tmp3

	cli
	mov		int_pulseH, pulseH
	mov		int_pulseL, pulseL
	sei

	ret

display_pulse_bits:

	ldi		YH, high(lcd_display)
	ldi		YL, low(lcd_display)
	adiw	Y, 16			;location of first character on second line

	ldi		tmp2, 0x80		;bitmask, starts at leftmost bit, shifts to finish on the rightmost bit

	display_pulse_bit_loop:
	ldi		tmp, '_'
	mov		tmp3, pulseH
	and		tmp3, tmp2
	breq	display_pulse_bit_done
	ldi		tmp, 0xFF

	display_pulse_bit_done:
	st		Y+, tmp

	lsr		tmp2					;shift bit mask for next loop
	brne	display_pulse_bit_loop	;loop if bits are left

	;do it again for lower 8 bits
	ldi		tmp2, 0x80		;bitmask, starts at leftmost bit, shifts to finish on the rightmost bit

	display_pulse_bit_loop2:
	ldi		tmp, '_'
	mov		tmp3, pulseL
	and		tmp3, tmp2
	breq	display_pulse_bit_done2
	ldi		tmp, 0xFF

	display_pulse_bit_done2:
	st		Y+, tmp

	lsr		tmp2					;shift bit mask for next loop
	brne	display_pulse_bit_loop2	;loop if bits are left

	cli
	mov		int_pulseH, pulseH
	mov		int_pulseL, pulseL
	sei

	ret


load_pattern:
	push	r16
	push	r17

	ldi		ZH, high(default_pattern*2)
	ldi		ZL, low(default_pattern*2)

	ldi		YH, high(lcd_display)
	ldi		YL, low(lcd_display)
	adiw	Y, 16

	ldi		r16, 16

	copy_to_lcd_buffer_loop:
	lpm		r17, Z+
	st		Y+, r17
	dec		r16
	brne	copy_to_lcd_buffer_loop

	pop		r17
	pop		r16
	ret

set_timer:				;tmp is used as index for int_timings array
	push	tmp
	clr		tmp
	out		TCCR0B, tmp		;stop timer
	pop		tmp
	tst		tmp
	breq	set_timer_off

	ldi		ZH, high(int_timings*2)
	ldi		ZL, low(int_timings*2)

	lsl		tmp
	add		ZL, tmp
	brcc	set_timer_load
	inc		ZH

	set_timer_load:
	ldi		tmp, 0
	out		TCNT0H, tmp		;clear timer
	out		TCNT0L, tmp

	ldi		tmp, CS_NO_PRESCALING;CS_DIV8	;clock / 8
	out		TCCR0B, tmp		;set the prescaler bit/enable timer

	push	tmp2
	lpm		tmp, Z+
	lpm		tmp2, Z+
	out		OCR0B, tmp2
	out		OCR0A, tmp
	pop		tmp2

	ret

	set_timer_off:
	ldi		tmp, 0
	out		TCNT0H, tmp		;clear timer
	out		TCNT0L, tmp
	cbi		PORT_SPEAKER, SPEAKER_OUT
	;sbi		PORT_LCD, LCD_LED

	ret

controller_error:
	;push	r16
	;push	r17

	;ldi		ZH, high(error_message*2)
	;ldi		ZL, low(error_message*2)
	;ldi		YH, high(lcd_display)
	;ldi		YL, low(lcd_display)
	;ldi		r16, 32

	;copy_to_lcd_buffer_loop:
	;lpm		r17, Z+
	;st		Y+, r17
	;dec		r16
	;brne	copy_to_lcd_buffer_loop

	;pop		r17
	;pop		r16
	rcall	shift_display_screen_2

	controller_error_check:
	rcall	read_snes
	lds		r17, snes_lower		;make sure it's plugged in
	cbr		r17, 0x0F
	cpi		r17, 0x00
	brne	controller_error_check

	ret


incfreq:
	push	tmp
	mov		tmp, freq

	cpi		tmp, 21
	brlo	incfreq_next
	ldi		tmp, 20

	incfreq_next:
	inc		tmp

	mov		freq, tmp
	pop		tmp

	ret

hex2dec:	;r16 = byte, Z = pointer to sram location
	ldi		r17, 0		;this will store current digit
	ldi		r18, 100	;this will store current decimal place
	ldi		r19, 81		;this will knock the decimal place down by 1

	hex2dec_start:
	sub		r16, r18
	brcs	hex2dec_next	;branch if we went negative
	inc		r17
	rjmp	hex2dec_start

	hex2dec_next:
	add		r16, r18	;went negative, put it back into positive
	ori		r17, 0x30	;make into ascii
	st		Z+, r17		;store the digit to sram

	sub		r18, r19	;puts 100 down to 10 first loop
	clr		r19			;won't be around second loop
	clr		r17			;clear current digit
	subi	r18, 9		;puts 10 down to 1 on second loop

	brcc	hex2dec_start	;loop till r18 goes negative

	ret

update_gui:




	ret


new_second:
	cbr		rint, (1<<rint_new_second)
	;rcall	random_generator			;get a random number
	;lds		tmp, random_numbers
	andi	tmp, 0x0F					;between 0 and 15
	subi	tmp, 5
	brpl	new_second_end

	;lds		random_hits, random_numbers
	;---------------------------------------------------
	;ldi		random_hits, 1		;number of flickers 1-3
	;---------------------------------------------------
	;andi	random_hits, 3
	;inc		random_hits
	
	new_second_end:

	ret

new_frame:
	cbr		rint, (1<<rint_new_frame)
	tst		pattern_counter			;if there's no frames left
	breq	new_frame1
	dec		pattern_counter			;dec the counter
	;lpm		led, Z+					;load the next frame
	rjmp	new_frame_end

	new_frame1:						;20 frames have played
	;clr		pattern_counter
	;tst		random_hits
	breq	new_frame_end
	;dec		random_hits				;shall we play another?
	breq	new_frame_end
	rcall	random_hit
	ldi		pattern_counter, 20		;we'll play another frame

	new_frame_end:
	ret

random_hit:
	clr		YH
	clr		YL

	random_hit1:
	;lds		tmp, random_numbers
	andi	tmp, 0x07			;gives us 8 patterns
	;---------------------------------------------------
	;ldi		tmp, 0			;load first pattern only
	;---------------------------------------------------
	cpi		tmp, 0
	breq	random_hit2

	random_hit_loop:			;Y = tmp * 20
	adiw	Y, 20
	dec		tmp
	brne	random_hit_loop

	random_hit2:

	ldi		ZH, high(flicker_patterns*2)	;load the base pointer
	ldi		ZL, low(flicker_patterns*2)

	add		ZL, YL				;add Y to Z
	brcc	random_hit3
	inc		ZH
	random_hit3:
	add		ZH, YH

	ret


set_constant:
	wait_for_switch:
	sbrs	rint, rint_new_frame
	rjmp	wait_for_switch

	;sbis	switch_port_in, switch_bit
	ret

	;push	led
	sbrs	rint, rint_keep_brightness
	;ldi		led, 127

	wait_for_switch_off:
	;sbic	switch_port_in, switch_bit
	rjmp	wait_for_switch_off

	;pop		led

	ret


startup_fade:
	;ldi		led, 127

	wait_for_frame:
	sbrs	rint, rint_new_frame
	rjmp	wait_for_frame

	;sbic	switch_port_in, switch_bit		;allows brightness to be dimmed
	sbr		rint, (1<<rint_keep_brightness)
	rcall	set_constant

	cbr		rint, (1<<rint_new_frame)

	;dec		led
	;cpi		led, 0
	breq	fade_up
	rjmp	wait_for_frame

	fade_up:

	wait_for_frame1:
	sbrs	rint, rint_new_frame
	rjmp	wait_for_frame1

	;sbic	switch_port_in, switch_bit		;allows brightness to be dimmed
	sbr		rint, (1<<rint_keep_brightness)
	rcall	set_constant

	cbr		rint, (1<<rint_new_frame)

	;inc		led
	;cpi		led, 128
	breq	startup_fade_done
	rjmp	wait_for_frame1

	startup_fade_done:

	cbr		rint, (1<<rint_keep_brightness)

	ret

flicker_patterns:

.db		20, 20, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 40, 20, 128
