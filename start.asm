.org	0x00
.cseg

	rjmp	RESET			; Reset Handler
	rjmp	EXT_INT0		; IRQ0 Handler
	rjmp	PCINT			; PCINT Handler
	rjmp	TIM1_COMPA		; Timer1 CompareA Handler
	rjmp	TIM1_COMPB		; Timer1 CompareB Handler
	rjmp	TIM1_OVF		; Timer1 Overflow Handler
	rjmp	TIM0_OVF		; Timer0 Overflow Handler
	rjmp	USI_START		; USI Start Handler
	rjmp	USI_OVF			; USI Overflow Handler
	rjmp	EE_RDY			; EEPROM Ready Handler
	rjmp	ANA_COMP		; Analog Comparator Handler
	rjmp	ADC_CONV		; ADC Conversion Handler
	rjmp	WDT				; WDT Interrupt Handler
	rjmp	EXT_INT1		; IRQ1 Handler
	rjmp	TIM0_COMPA		; Timer0 CompareA Handler
	rjmp	TIM0_COMPB		; Timer0 CompareB Handler
	rjmp	TIM0_CAPT		; Timer0 Capture Event Handler
	rjmp	TIM1_COMPD		; Timer1 CompareD Handler
	rjmp	FAULT_PROTECTION ; Timer1 Fault Protection

checksum:
	.db		0x00, 0xFF

.include	"extra\timestamp.txt"

EXT_INT0:
	reti
PCINT:
	reti
TIM1_COMPA:
	reti
TIM1_COMPB:
	reti
TIM1_OVF:
	reti
TIM0_OVF:
	reti
USI_START:
	reti
USI_OVF:
	reti
EE_RDY:
	reti
ANA_COMP:
	reti
ADC_CONV:
	reti
WDT:
	reti
EXT_INT1:
	reti
TIM0_COMPA:
	push	tmp
	in		tmp, SREG
	push	tmp

	ldi		tmp, 0
	out		TCNT0H, tmp		;clear timer
	out		TCNT0L, tmp

	clc
	rol		int_pulseL
	rol		int_pulseH

	brcs	over_inc
	cbi		PORT_SPEAKER, SPEAKER_OUT
	pop		tmp
	out		SREG, tmp
	pop		tmp
	reti

over_inc:
	sbr		int_pulseL, 1		;set the shifted bit
	sbi		PORT_SPEAKER, SPEAKER_OUT
	pop		tmp
	out		SREG, tmp
	pop		tmp
	reti	


	;ldi		tmp, clock_divide_high
	;out		TCNT0H, tmp
	;ldi		tmp, clock_divide_low
	;out		TCNT0L, tmp		;reset the timer values

	;cpi		led, 128		;make sure led is 127 or less
	;brlo	TIM0_OVF_led_sanity
	;ldi		led, 127
	;TIM0_OVF_led_sanity:

	;inc		pulse_frame
	;cpi		pulse_frame, 16
	;brlo	TIM0_OVF_next

	;clr		pulse_frame			;beginning of new frame (60fps)
	;sbr		rint, (1<<rint_new_frame)
	;inc		frame
	;cpi		frame, 61
	;brlo	TIM0_OVF_next

	;clr		frame			;1 second
	;sbr		rint, (1<<rint_new_second)

	;TIM0_OVF_next:

	;cpi		led, 0
	;breq	TIM0_OVF_led_off
	;cp		led, fade
	;brmi	TIM0_OVF_led_off
	;sbi		led_port, led_bit
	;sbi		led_port, led_bit2
	;rjmp	TIM0_OVF_end

	;TIM0_OVF_led_off:
	;cbi		led_port, led_bit
	;cbi		led_port, led_bit2

	;TIM0_OVF_end:


	reti
TIM0_COMPB:
	reti
TIM0_CAPT:
	reti
TIM1_COMPD:
	reti
FAULT_PROTECTION:
	reti

clear_regs:
	clr		r0
	clr		r1
	clr		r2
	clr		r3
	clr		r4
	clr		r5
	clr		r6
	clr		r7
	clr		r8
	clr		r9
	clr		r10
	clr		r11
	clr		r12
	clr		r13
	clr		r14
	clr		r15
	clr		r16
	clr		r17
	clr		r18
	clr		r19
	clr		r20
	clr		r21
	clr		r22
	clr		r23
	clr		r24
	clr		r25
	clr		r26
	clr		r27
	clr		r28
	clr		r29
	clr		r30
	clr		r31
	ret
