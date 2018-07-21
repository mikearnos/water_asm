.dseg
dead_lcd_buffer:	;allows to write off screen
	.db		0, 0
lcd_display:		;holds ASCII to be sent to lcd
	.db		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	.db		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.cseg

.equ	PORT_LCD = PORTA
.equ	DDR_LCD = DDRA
.equ	LCD_LED = PA0
.equ	LCD_RS = PA1
.equ	LCD_E = PA2
.equ	LCD_DB4 = PA4
.equ	LCD_DB5 = PA5
.equ	LCD_DB6 = PA6
.equ	LCD_DB7 = PA7

.equ	LCD_INST = 0
.equ	LCD_NYBBLE = 1

error_message:
.db		"   CONTROLLER   "
.db		"  NOT DETECTED  "

init_lcd:
	in		r16, DDR_LCD
	ldi		r17, (1 << LCD_LED) | (1 << LCD_RS) | (1 << LCD_E) | (1 << LCD_DB4) | (1 << LCD_DB5) | (1 << LCD_DB6) | (1 << LCD_DB7)
	or		r16, r17
	out		DDR_LCD, r16

	rcall	wait_5_ms
	rcall	wait_5_ms
	rcall	wait_5_ms		;wait 15ms after startup

	ldi		r16, 0x03
	ldi		r17, (1 << LCD_NYBBLE) | (1 << LCD_INST)	;only need to set the first time
	rcall	send_LCD
	rcall	wait_5_ms		;write 0x03 and wait 5ms

	ldi		r16, 0x03
	rcall	send_LCD
	rcall	wait_160_us		;write 0x03 and wait 160us

	ldi		r16, 0x03
	rcall	send_LCD
	rcall	wait_160_us		;write 0x03 and wait 160us

	ldi		r16, 0x02				;4bit mode
	rcall	send_LCD
	rcall	wait_5_ms

	ldi		r16, 1					;clear display
	ldi		r17, 1 << LCD_INST
	rcall	send_LCD
	rcall	wait_160_us

	ldi		r16, 2					;return cursor to home position
	;ldi		r17, 1 << LCD_INST
	rcall	send_LCD
	rcall	wait_5_ms

	ldi		r16, 0x20 | 0x08		;interface legth 4 bit, 2 line display
	;ldi		r17, 1 << LCD_INST
	rcall	send_LCD
	rcall	wait_160_us

	ldi		r16, 8 | 4 | 0 | 0		;enable display, turn display on, cursor on, blink on
	;ldi		r17, 1 << LCD_INST
	rcall	send_LCD
	rcall	wait_160_us

	ret

update_lcd:
	ldi		r16, 2					;return cursor to home position
	ldi		r17, 1 << LCD_INST
	rcall	send_LCD
	rcall	wait_5_ms

	ldi		ZH, high(lcd_display)
	ldi		ZL, low(lcd_display)	;get pointer to lcd buffer

	ldi		r18, 16			;send 16 bytes
	ldi		r17, 0			;default settings for send_LCD
	update_lcd_loop:
	ld		r16, Z+
	rcall	send_LCD
	rcall	wait_160_us
	dec		r18
	brne	update_lcd_loop

	ldi		r16, 0x80 | 0x40	;move cursor to position 0x40
	ldi		r17, 1 << LCD_INST
	rcall	send_LCD
	rcall	wait_160_us

	ldi		r18, 16			;send 16 bytes
	ldi		r17, 0			;default settings for send_LCD
	update_lcd_loop2:
	ld		r16, Z+
	rcall	send_LCD
	rcall	wait_160_us
	dec		r18
	brne	update_lcd_loop2

	ret

shift_display_screen_2:
	ldi		r18, 16		;shift screen 16 times

	shift_display_screen_2_loop:
	ldi		r16, 0x18	;shift screen once to the left
	ldi		r17, 1 << LCD_INST
	rcall	send_LCD
	rcall	wait_160_us

	dec		r18
	cpi		r18, 0
	brne	shift_display_screen_2_loop

	ret


upload_controller_error_screen:
	ldi		ZH, high(error_message*2)
	ldi		ZL, low(error_message*2)	;get pointer to lcd buffer

	ldi		r16, 0x80 | 0x10	;move cursor to position 0x10
	ldi		r17, 1 << LCD_INST
	rcall	send_LCD
	rcall	wait_160_us

	ldi		r18, 16			;send 16 bytes
	ldi		r17, 0			;default settings for send_LCD
	upload_screen_loop:
	lpm		r16, Z+
	rcall	send_LCD
	rcall	wait_160_us
	dec		r18
	brne	upload_screen_loop

	ldi		r16, 0x80 | 0x50	;move cursor to position 0x50
	ldi		r17, 1 << LCD_INST
	rcall	send_LCD
	rcall	wait_160_us

	ldi		r18, 16			;send 16 bytes
	ldi		r17, 0			;default settings for send_LCD
	upload_screen_loop2:
	lpm		r16, Z+
	rcall	send_LCD
	rcall	wait_160_us
	dec		r18
	brne	upload_screen_loop2

	ret

send_LCD:		;r16 = byte to send, r17 can be NYBBLE or INST, byte and data are default
	push	r17		;do not destroy setting, makes multiple sends easier
	push	r18
	push	r19

	in		r19, PORT_LCD			;leave the other two bits alone (LED and n/c) by clearing
	andi	r19, ~((1 << LCD_RS) | (1 << LCD_E) | 0xF0)	;control lines and data bits

	sbrc	r17, LCD_NYBBLE
	swap	r16

	send_LCD_loop:
	mov		r18, r16
	andi	r18, 0xF0		;upper nybble
	sbrs	r17, LCD_INST
	sbr		r18, 1 << LCD_RS		;set data bit based on r17
	or		r18, r19		;restore other two bits (LED and n/c)

	out		PORT_LCD, r18
	;nop
	;nop
	;nop
	sbi		PORT_LCD, LCD_E
	;nop
	;nop
	;nop
	cbi		PORT_LCD, LCD_E
	;nop
	;nop
	;nop

	sbrc	r17, LCD_NYBBLE
	rjmp	send_LCD_end

	swap	r16
	sbr		r17, 1 << LCD_NYBBLE
	rjmp	send_LCD_loop	;send the lower nybble if byte mode is set

	send_LCD_end:
	pop		r19
	pop		r18
	pop		r17
	ret

clear_lcd_buffer:
	ldi		ZH, high(lcd_display*2)
	ldi		ZL, low(lcd_display*2)
	ldi		r16, 32					;fill 32 bytes with spaces
	ldi		r17, ' '
	clear_lcd_buffer_loop:
	st		Z+, r17
	dec		r16
	brne	clear_lcd_buffer_loop

	ret

wait_10_us:			;waits exactly 10 microseconds
	push	tmp

	ldi		tmp, 23
	wait_10_us_loop:
	dec		tmp
	brne	wait_10_us_loop

	pop		tmp
	ret

wait_160_us:		;waits exactly 160 microseconds
	push	tmp
	push	r17

	ldi		tmp, 0xA3
	ldi		r17, 2
	wait_160_us_loop:
	dec		tmp
	brne	wait_160_us_loop
	dec		r17
	brne	wait_160_us_loop
	nop
	nop
	nop

	pop		r17
	pop		tmp
	ret


wait_5_ms:			;waits exactly 5 miliseconds
	push	tmp
	push	r17

	clr		tmp
	ldi		r17, 0x33	
	wait_5_ms_loop:
	dec		tmp
	brne	wait_5_ms_loop
	dec		r17
	brne	wait_5_ms_loop

	ldi		tmp, 0xEE
	wait_5_ms_loop2:
	dec		tmp
	brne	wait_5_ms_loop2

	pop		r17
	pop		tmp
	ret
