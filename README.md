### Water electrolisis control module / tone generator

This was a little project incorporating an Atmel AVR ATtiny461, HD44780 LCD display, a SNES controller, and a tub of water. The idea was to send pulses to the water at different frequencies, and through electrolysis separate the water into hydrogen and oxygen and make fuel. It works wonders and will run your car on water 100%.

Just kidding. This thing is more like a tone generator, and it has a nice display controlled with the SNES controller. You are able to change pulse positions at different frequencies, and store settings in eeprom for later use.

The idea with this thing was that it would run by itself going through all frequencies and pulses it can create and see if a *magic* tone could be found. I never got that far with it but you're free to try with this source code.

I used [AVR Studio v4.18.SP3.716](https://www.microchip.com/mplab/avr-support/avr-and-sam-downloads-archive) (install the setup.exe then the SP3.exe). Although 4.19 or somewhat later versions should still work, I just didn't like the change in the interface of 5.0.

Here's the output when I assemble it:

```
AVRASM: AVR macro assembler 2.1.42 (build 1796 Sep 15 2009 10:48:36)
Copyright (C) 1995-2009 ATMEL Corporation

water.asm(1): Including file 'C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\Appnotes\tn461def.inc'
water.asm(2): Including file 'start.asm'
start.asm(27): Including file 'extra\timestamp.txt'
water.asm(3): Including file 'lcd_44780.asm'
water.asm(4): Including file 'snes_controller.asm'
water.asm(5): Including file 'eeprom.asm'
water.asm(865): No EEPROM data, deleting bin\water.eep

ATtiny461 memory use summary [bytes]:
Segment   Begin    End      Code   Data   Used    Size   Use%
---------------------------------------------------------------
[.cseg] 0x000000 0x000724   1548    280   1828    4096  44.6%
[.dseg] 0x000060 0x000088      0     40     40     256  15.6%
[.eseg] 0x000000 0x000000      0      0      0     256   0.0%

Assembly complete, 0 errors. 0 warnings
```
