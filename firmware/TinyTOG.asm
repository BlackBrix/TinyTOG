//==============================================================================
// File:		TinyTOG.asm
// Compiler:	AVR Studio 3.11 www.atmel.com
// Output Size:	-
// Created:    	Sat Aug 15 10:39:35 2004
// Copyright:	(C) 2004 ALM, Hong Kong
//
// This program is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation; either version 2 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but without
// any warranty; without even the implied warranty of merchantability or fitness
// for a particular purpose. See the GNU General Public License for more details
// at http://www.gnu.org/licenses
//==============================================================================

.include "tn15def.inc"



.def lowL = r4
.def lowH = r5

.def highL = r6
.def highH = r7

.def temp1 = r16
.def temp2 = r17

.def demodelay = r18
.def democnt = r19

.def waitcnt = r20
.def waitcntL = r21
.def waitcntH = r22

.MACRO addi 
	subi @0, 0xFF - @1 + 1
.ENDMACRO





.org	0x000
MAIN:

	; PB4 ADC input from oil temperature sensor
	; PB3 n.c.
	; PB2 n.c.
	; PB1 PWM output to instrument cluster
	; PB0 Jumper for demo mode (low=demo)
	
	; Prepare port
	ldi temp1, 0b00001000
	out DDRB, temp1
	ldi temp1, 0b00001111
	out PORTB, temp1
	
	; Prepare ADC
	ldi temp1, 0b00100011
	out ADMUX, temp1
	ldi temp1, 0b11100000
	out ADCSR, temp1
	
	; Calibrate 
	ldi temp1, low( CAL_BYTE<<1 )
	mov ZL, temp1
	ldi temp1, high( CAL_BYTE<<1 )
	mov ZH, temp1
	lpm
	out OSCCAL, r0
	
	; Jump to demo mode?
	sbis PINB, 0
	rjmp DEMO


MAIN_LOOP:
	
	rcall ADC_VALUE
	rcall LOAD_TOG_VALUES
	rcall OUT_VALUE

	rjmp MAIN_LOOP




	
OUT_VALUE:

	cbi PORTB, 3

	ldi waitcntL, 160
	ldi waitcntH, 0
	rcall WAIT

	sbi PORTB, 3

	mov waitcntL, lowL
	mov waitcntH, lowH
	rcall WAIT

	cbi PORTB, 3
	
	mov waitcntL, highL
	mov waitcntH, highH
	rcall WAIT

	sbi PORTB, 3

	ldi waitcntL, 208
	ldi waitcntH, 7
	rcall WAIT

	ret




/*******************************************************************************
* Procedure: ADC_VALUE
*
* Reads ADC and delivers back an index on the loopup table in temp1
*******************************************************************************/

ADC_VALUE:
	in temp2, ADCH
ADC_41:		
	cpi temp2, 217
	brlo ADC_60	
	ldi temp1, 0
	ret
ADC_60:
	cpi temp2, 213
	brlo ADC_65
	ldi temp1, 1
	ret
ADC_65:
	cpi temp2, 203
	brlo ADC_70
	ldi temp1, 2
	ret
ADC_70:
	cpi temp2, 192
	brlo ADC_75
	ldi temp1, 3
	ret
ADC_75:
	cpi temp2, 183
	brlo ADC_80
	ldi temp1, 4
	ret
ADC_80:
	cpi temp2, 174
	brlo ADC_85
	ldi temp1, 5
	ret
ADC_85:
	cpi temp2, 165
	brlo ADC_90
	ldi temp1, 6
	ret
ADC_90:
	cpi temp2, 150
	brlo ADC_95
	ldi temp1, 7
	ret
ADC_95:
	cpi temp2, 146
	brlo ADC_100
	ldi temp1, 8
	ret
ADC_100:
	cpi temp2, 138
	brlo ADC_105
	ldi temp1, 9
	ret
ADC_105:
	cpi temp2, 129
	brlo ADC_110
	ldi temp1, 10
	ret
ADC_110:
	cpi temp2, 121
	brlo ADC_115
	ldi temp1, 11
	ret
ADC_115:
	cpi temp2, 115
	brlo ADC_120
	ldi temp1, 12
	ret
ADC_120:
	cpi temp2, 108
	brlo ADC_125
	ldi temp1, 13
	ret
ADC_125:
	cpi temp2, 93
	brlo ADC_130
	ldi temp1, 14
	ret
ADC_130:
	cpi temp2, 81
	brlo ADC_135
	ldi temp1, 15
	ret
ADC_135:
	cpi temp2, 75
	brlo ADC_140
	ldi temp1, 16
	ret
ADC_140:
	cpi temp2, 69
	brlo ADC_145
	ldi temp1, 17
	ret
ADC_145:
	cpi temp2, 63
	brlo ADC_150
	ldi temp1, 18
	ret
ADC_150:
	cpi temp2, 58
	brlo ADC_155
	ldi temp1, 19
	ret
ADC_155:
	cpi temp2, 53
	brlo ADC_160
	ldi temp1, 20
	ret
ADC_160:
	cpi temp2, 50
	brlo ADC_165
	ldi temp1, 21
	ret
ADC_165:
	cpi temp2, 49
	brlo ADC_170
	ldi temp1, 22
	ret
ADC_170:
	ldi temp1, 23

	ret





/*******************************************************************************
* Procedure: DEMO
*
* Shifts output from 41°C to 175°C and back.
*******************************************************************************/

DEMO:
	
	ldi temp1, 23
	rcall LOAD_TOG_VALUES

	ldi demodelay, 20

DEMO_LOOP1:

	rcall OUT_VALUE
	dec demodelay
	brne DEMO_LOOP1

	ldi democnt, 23
	
DEMO_OUTER_LOOP:
	
	mov temp1, democnt
	rcall LOAD_TOG_VALUES

	ldi demodelay, 225

DEMO_INNER_LOOP:

	rcall OUT_VALUE
	dec demodelay
	brne DEMO_INNER_LOOP
	
	dec democnt
	brne DEMO_OUTER_LOOP
	
	rjmp DEMO





/*******************************************************************************
* Procedure: DEMO
*
* Load wait states from lookup table
*******************************************************************************/

LOAD_TOG_VALUES:

	lsl temp1
	lsl temp1

	ldi temp2, low( TOG_LOOKUP_TABLE<<1 )
	mov ZL, temp2
	ldi temp2, high( TOG_LOOKUP_TABLE<<1 )
	mov ZH, temp2

	add ZL, temp1
	ldi temp1,0
	adc ZH, temp1
	 
	ldi temp1, 1
	ldi temp2, 0

	lpm
	mov lowL, r0
	add ZL, temp1
	adc ZH, temp2
	lpm
	mov lowH, r0
	add ZL, temp1
	adc ZH, temp2
	lpm
	mov highL, r0
	add ZL, temp1
	adc ZH, temp2
	lpm
	mov highH, r0

	ret





/*******************************************************************************
* Procedure: DEMO
*
* Just a few wait staites...
*******************************************************************************/

WAIT:
	subi waitcntL, 1
	sbci waitcntH, 0
WAIT_LOOP:
	ldi waitcnt, 47
	rcall WAITING
	subi waitcntL, 1
	sbci waitcntH, 0
	brne WAIT_LOOP
	ldi waitcnt, 45
	nop
	nop
	rcall WAITING
	ret

WAITING:
	nop
	dec waitcnt
	brne WAITING
	nop
	ret





.org 0x1CD
TOG_LOOKUP_TABLE:
//				°C
.dw 188, 192	; 41
.dw 210, 216	; 60
.dw 216, 222	; 65
.dw 224, 226	; 70
.dw 228, 234	; 75
.dw 234, 240	; 80
.dw 242, 246	; 85
.dw 248, 252	; 90
.dw 254, 260	; 95
.dw 260, 266	; 100
.dw 266, 272	; 105
.dw 272, 280	; 110
.dw 280, 286	; 115
.dw 286, 294	; 120
.dw 294, 300	; 125
.dw 300, 306	; 130
.dw 306, 314	; 135
.dw 314, 320	; 140
.dw 320, 326	; 145
.dw 328, 334	; 150
.dw 334, 342	; 155
.dw 342, 348	; 160
.dw 348, 356	; 165
.dw 356, 362	; 170
.dw 368, 374	; 175


.org 0x1FF
CAL_BYTE:
.dw 0x78
