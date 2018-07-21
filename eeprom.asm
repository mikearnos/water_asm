.cseg

write_eeprom:	;address = r18:r17 data = r16
	cli						;disable interrupts

	write_eeprom_1:
	sbic	EECR, EEPE		;wait until EEPE becomes zero
	rjmp	write_eeprom_1

	push	r16
	ldi		r16, (0<<EEPM1)|(0<<EEPM0)		; Set Programming mode
	out		EECR, r16
	pop		r16

	out		EEARH, r18		; Set up address (r18:r17) in address register
	out		EEARL, r17

	out		EEDR, r16		;write EEPROM data to EEDR

	sbi		EECR, EEMPE		;set master write enable
	sbi		EECR, EEPE		;within four clock cycles
	sei

	ret


read_eeprom:	;address = r18:r17 returns data = r16
	sbic	EECR, EEPE		;make sure there's no writing going on
	rjmp	read_eeprom

	out		EEARH, r18		; Set up address (r18:r17) in address register
	out		EEARL, r17

	sbi		EECR, EERE		; Start eeprom read by writing EERE
	in		R16, EEDR		; Read data from data register
	ret
