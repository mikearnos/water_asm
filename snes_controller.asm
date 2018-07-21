.dseg
snes_upper:				;holds currently read buttons, 1 = pressed, 0 = not
	.db		0x00
snes_lower:
	.db		0x00
snes_upper2:			;holds previous buttons
	.db		0x00
snes_lower2:
	.db		0x00
snes_upper_single:		;holds bits for buttons previously off, but then pressed
	.db		0x00		;aka single click, clear bits manually after reading them
snes_lower_single:
	.db		0x00
.cseg


		;===SNES controller
.equ	PORT_SNES = PORTB
.equ	PIN_SNES = PINB
.equ	DDR_SNES = DDRB
.equ	SNES_CLOCK = PB0
.equ	SNES_LATCH = PB1
.equ	SNES_DATA = PB2

		;===SNES controller pinout
		;1		5 volt		White
		;2		Clock		Yellow
		;3		Latch		Orange
		;4		Data		Red
		;7		Ground		Brown

		;===ram snes_upper bit defines
.equ	SNES_B = 0
.equ	SNES_Y = 1
.equ	SNES_SELECT = 2
.equ	SNES_START = 3
.equ	SNES_UP = 4
.equ	SNES_DOWN = 5
.equ	SNES_LEFT = 6
.equ	SNES_RIGHT = 7
		;===ram snes_lower bit defines
.equ	SNES_A = 0
.equ	SNES_X = 1
.equ	SNES_L = 2
.equ	SNES_R = 3

read_snes:
	push	r16
	push	r17
	push	r18

	lds		r16, snes_upper				;copy new input into old input
	sts		snes_upper2, r16
	lds		r16, snes_lower
	sts		snes_lower2, r16

	;begin reading controller
	sbi		PORT_SNES, SNES_CLOCK		;clock starts/rests at high
	sbi		PORT_SNES, SNES_LATCH		;tell controller to latch all inputs
	cbi		PORT_SNES, SNES_LATCH		;drop latch, inputs can be read

	clr		r18					;register will store button presses
	ldi		r16, 0x08			;read 8 bits
	clc
	read_snes_loop:				;reads B, Y, Select, Start, Up, Down, Left, Right
	in		r17, PIN_SNES
	sbrs	r17, SNES_DATA
	sec							;sets carry high if button is pressed (logic 0)
	ror		r18					;shifts carry into r18
	cbi		PORT_SNES, SNES_CLOCK
	sbi		PORT_SNES, SNES_CLOCK
	dec		r16
	brne	read_snes_loop
	sts		snes_upper, r18

	clr		r18					;register will store button presses
	ldi		r16, 0x08			;read 8 bits
	read_snes_loop2:			;reads A, X, L, R
	in		r17, PIN_SNES
	sbrs	r17, SNES_DATA
	sec							;sets carry high if button is pressed (logic 0)
	ror		r18					;shifts carry into r18
	cbi		PORT_SNES, SNES_CLOCK
	sbi		PORT_SNES, SNES_CLOCK
	dec		r16
	brne	read_snes_loop2
	sts		snes_lower, r18
	;done reading controller


	lds		r16, snes_upper		;check for button down upper byte
	lds		r17, snes_upper2
	mov		r18, r16
	eor		r18, r17		;make sure the button is either being pressed or released
	and		r16, r18		;make sure button is only being pressed
	sts		snes_upper_single, r16

	lds		r16, snes_lower		;check for button down lower byte
	lds		r17, snes_lower2
	mov		r18, r16
	eor		r18, r17		;make sure the button is either being pressed or released
	and		r16, r18		;make sure button is only being pressed
	sts		snes_lower_single, r16

	pop		r18
	pop		r17
	pop		r16
	ret

init_snes:
	sbi		DDR_SNES, SNES_LATCH
	sbi		DDR_SNES, SNES_CLOCK
	cbi		DDR_SNES, SNES_DATA

	ret
