;	====================================
;	ANSI Driver for Montezuma Micro CP/M
;	====================================
;
;	Version 0.2, March 2026
;
;	This ANSI driver provides support for ANSI escape sequences on the
;	Montezuma Micro CP/M system. It is designed to be installed in the BIOS
;	and provides enhanced video and keyboard capabilities through the use of
;	ANSI escape codes. The driver intercepts calls to the video output and
;	keyboard input routines, allowing it to process ANSI escape sequences and
;	translate them into the appropriate actions on the TRS-80 Model 4 hardware.
;
;	The driver supports a range of ANSI escape sequences for cursor movement,
;	screen clearing, and text attributes. The installation process involves
;	patching the BIOS to redirect video output and keyboard input to the ANSI
;	driver, which then processes the input and output as needed.

;	The driver installs itself in the extended memory area (EXMEM) and patches
;	the BIOS to call it for video output and keyboard input. The CP/M Drive M:
;	is disabled during installation to ensure that the driver can safely use
;	the EXMEM area for its code and data without conflicts.
;
;	The following keys are remapped to provide better ANSI compatibility:
;	- [Clear] is remapped to DEL (0x7F) to allow it to be used
;	  as a backspace key in ANSI applications.
;	- [Break] is remapped to ESC (0x1B) to allow it to be used
;	  as an escape key in ANSI applications.
;	- Shift-[Clear] is remapped to (0x1C) to allow it to be used
;	  as a clear line key in ANSI applications.
;	- Shift-[Up] is remapped to ESC (0x1B) to allow it to be used
;	  as an escape key in ANSI applications.
;	- Shift-[Down] is remapped to Ctrl-Z (0x1A) to allow it to be used
;	  as a substitute for the standard Ctrl-Z end-of-file key in ANSI applications.
;	- Shift-[Left] is remapped to Ctrl-H (0x08) to allow it to be used
;	  as a backspace key in ANSI applications.
;	- Shift-[Right] is remapped to Ctrl-I (0x09) to allow it to be used
;	  as a tab key in ANSI applications.
;	- Arrow keys are remapped to their corresponding ANSI escape sequences
;	  (e.g., [Left] sends ESC'[D', [Up] sends ESC'[A', etc.).
;
;	Copyright (c) 2026 GmEsoft

;	Permission is hereby granted, free of charge, to any person obtaining a copy
;	of this software and associated documentation files (the "Software"), to deal
;	in the Software without restriction, including without limitation the rights
;	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;	copies of the Software, and to permit persons to whom the Software is
;	furnished to do so, subject to the following conditions:
;
;	The above copyright notice and this permission notice shall be included in all
;	copies or substantial portions of the Software.
;
;	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;	SOFTWARE.
;

DEBUG	EQU	0			;Set to 1 to enable debug breakpoints

;	Banner text macro.
BANNER	MACRO
	DB	1AH,0FH
	DB	09H,'===============================================================',15H,0DH,0AH
	DB	09H,'ANSI Driver for Montezuma Micro CP/M vers. 0.2 (c) 2026 GmEsoft',15H,0DH,0AH
	DB	09H,'===============================================================',15H,0DH,0AH
	DB	0EH,0AH,'$'
	ENDM


;	Unconditional break macro for debugging.
$BREAK	MACRO
	IF	DEBUG
	DB	0EDH,0F5H		;$BREAK
	ENDIF
	ENDM

;	Conditional break macro for debugging. Will break if the emulator is running in EXEC mode,
;	but not if running in GO mode.
$CBREAK	MACRO
	IF	DEBUG
	DB	0EDH,0FCH		;$CBREAK
	ENDIF
	ENDM

;	CP/M boot vector
BOOTVEC	EQU	0001H

;	CP/M BDOS entry point
BDOS	EQU	0005H

;	TPA entry point for ANSI driver installer
	ORG	0100H			;TPA

;=====	ANSI driver installer
START:
;	$BREAK

	;Save and init SP, to safely switch high bank
	LD	HL,0			;Get SP to HL
	ADD	HL,SP			;
	LD	(EXIT+1),HL		;Save to EXIT door
	LD	SP,8000H		;Temp SP in low 32K bank

	;Display banner
	LD	DE,BANNER$		;Banner text
	LD	C,9			;call BDOS Display String function
	CALL	BDOS			;

	;Get BIOS warm-boot vector, save to DE
	LD	HL,(BOOTVEC)		;Get BIOS WBOOT vector
	LD	L,0			;Clear LSB
	EX	DE,HL			;Save to DE
	LD	HL,0B0H-100H		;Offset to BDOS LOGIN MSB
	ADD	HL,DE			;Point to BDOS LOGIN MSB
	BIT	4,(HL)			;Test BDOS LOGIN bit 12 (drive M:)
	JR	Z,OK1			;OK if zero

	;Error: M: drive in use
	LD	DE,MINUSE$		;'M: drive in use'

	;Display error message and exit
ABORT	LD	C,9			;call BDOS Display String function
	CALL	BDOS			;
	LD	HL,1			;Ret code = 1
	LD	A,L			;
	JP	EXIT			;Exit

	;M: not in use - check if enabled
OK1	LD	HL,013FH		;offset to 0 or CR preceding "M: enabled"
	ADD	HL,DE			;Point to MDRIVEM
	LD	A,(HL)			;0 if no M: drive
	OR	A			;Is M: drive enabled?
	JR	NZ,OK2			;OK if yes

	;Error: Not a 128K system
	LD	DE,NO128K$		;'Not a 128K system'
	JR	ABORT			;Display error message and exit

	;Check if already installed
OK2	INC	A			;MDRIVEM contains 0FFH if already installed
	JR	NZ,OK3			;Go if not

	;Error: Already installed
	LD	DE,ALRINS$		;'Already installed'
	JR	ABORT			;Display error message and exit

	;OK to install
OK3	LD	(HL),0FFH		;Mark M: disabled
	PUSH	DE			;Save BIOS base
	LD	DE,INSTAL$		;'Installing'
	LD	C,9			;call BDOS Display String function
	CALL	BDOS			;
	POP	DE			;Restore BIOS base

	;Disable drive M:
	LD	HL,0037H		;offset to DPHTBL pointer in SPB
	ADD	HL,DE			;point to DPHTBL pointer
	LD	A,(HL)			;get DPHTBL
	INC	HL			;
	LD	H,(HL)			;
	LD	L,A			;
	LD	BC,'M'-'A'		;get address of M: DPH
	ADD	HL,BC			;
	ADD	HL,BC			;
	LD	(HL),B			;Clear entry (B is 0)
	INC	HL			;
	LD	(HL),B			;

	;Change keyboard mapping
	LD	HL,0043H		;offset to KBDCB pointer in SPB
	ADD	HL,DE			;point to KBDCB pointer
	LD	A,(HL)			;get KBDCB
	INC	HL			;
	LD	H,(HL)			;
	LD	L,A			;
	LD	BC,0EEA6H-0EE93H	;get KDBCOD to HL
	ADD	HL,BC			;
	PUSH	HL			;
	POP	IX			;Move KBDCOD to IX
	LD	(IX+11H),7FH		;Assign DEL    to [Clear]
	LD	(IX+12H),1BH		;Assign ESC    to [Break]
	LD	(IX+11H+18H),1CH	;Assign Clear  to [Shift-Clear]
	LD	(IX+13H+18H),1BH	;Assign Esc    to [Shift-Up]
	LD	(IX+14H+18H),1AH	;Assign Ctrl-Z to [Shift-Down]
	LD	(IX+15H+18H),18H	;Assign Ctrl-X to [Shift-Left]
	LD	(IX+16H+18H),19H	;Assign Ctrl-Y to [Shift-Right]

	;Get VDOUT address and store in callback
	$CBREAK
	LD	HL,027FH		;VCRTOUT offset in Device Drivers table
	ADD	HL,DE			;Point to VCRTOUT
	PUSH	HL			;Save VCRTOUT for later patching
	LD	C,(HL)			;Get VDOUT address in BC
	INC	HL			;
	LD	B,(HL)			;
	LD	(VDOCLBK+1),BC		;Store in callback routine

	;Get KBSCAN address and store in callback
	LD	HL,027BH		;VCRTINP offset in Device Drivers table
	ADD	HL,DE			;Point to VCRTSTS
	LD	C,(HL)			;Get KBSTS address in BC
	INC	HL			;
	LD	B,(HL)			;
	PUSH	BC			;Save KBSTS for later patching
	LD	HL,0007H		;Offset to KBSCAN call address in KBSTS
	ADD	HL,BC			;Point to KBSCAN call address in KBSTS
	LD	C,(HL)			;Get KBSCAN address to BC
	INC	HL			;
	LD	B,(HL)			;
	LD	(KBSCLBK+1),BC		;Store KBSCAN in callback routine

	;Move caller and callback routines to BIOS in banner area
	LD	HL,013FH-CLENGTH	;Calc VDOCALL = routines address in BIOS
	ADD	HL,DE			;
	PUSH	DE			;Save BIOS base
	PUSH	HL			;Save VDOCALL in BIOS
	LD	DE,CBEGIN		;Source routines address
	PUSH	HL			;Save VDOCALL in BIOS
	OR	A			;
	SBC	HL,DE			;Calc relocation offset to BC
	LD	B,H			;
	LD	C,L			;
	LD	HL,(RELO1+1)		;Relocate SP save address
	ADD	HL,BC			;
	LD	(RELO1+1),HL		;
	LD	HL,(RELO2+1)		;Relocate new SP address
	ADD	HL,BC			;
	LD	(RELO2+1),HL		;
	POP	HL			;Restore VDOCALL in BIOS
	EX	DE,HL			; to DE, HL=source address
	LD	BC,CLENGTH		;
	LDIR				;Move routines
	POP	DE			;Restore VDOCALL in BIOS

	;Address of the moved callback routine
	LD	HL,VDOCLBK-VDOCALL	;*DO Callback routine offset
	ADD	HL,DE			;Calc effective address
	;Store *DO callback routine into ANSI driver
	LD	(VVDOUT+OFFSET+1),HL	;Save into ANSI driver
	LD	HL,KBSCLBK-VDOCALL	;*KI Callback routine offset
	ADD	HL,DE			;Calc effective address
	;Store *KI callback routine into ANSI driver
	LD	(VKBSCAN+OFFSET+1),HL	;Save into ANSI driver
	PUSH	DE			;Save VDOCALL in BIOS

	;Move ANSI driver to EXMEM page 1
	DI				;No interrupts while switching bank
	LD	A,0BFH			;Map EXMEM page 1 to 8000-FFFF
	OUT	(84H)			;
	LD	HL,BEGIN		;ANSI driver source address
	LD	DE,8000H		;EXMEM dest address
	LD	BC,XLENGTH		;ANSI driver length
	LDIR				;Move to EXMEM
	LD	A,8FH			;Unmap EXMEM page 1
	OUT	(84H),A			;

	POP	BC			;restore VDOCALL in BIOS
	POP	DE			;restore BIOS base

	;replace KBSCAN with VKBCALL in KBSTS and KBINP
	POP	IY			;restore VCRTOUT to replace KBSCAN with KBSCALL
	INC	BC			;Point to KBSCALL
	LD	(IY+07H),C		;KBSCAN call in KBSTS
	LD	(IY+08H),B		;
	LD	(IY+19H),C		;KBSCAN call in KBINP
	LD	(IY+1AH),B		;
	DEC	BC

	;replace VDOUT with VDOCALL in the VCRTOUT entry of DDATBL
	POP	IY			;restore VCRTOUT to replace VDOUT with VDOCALL
	LD	(IY+00H),C		;*VCRTOUT = VDOCALL in BIOS
	LD	(IY+01H),B		;

	;Installation successful
	LD	DE,INSTOK$		;'Installation successful'
	LD	C,9			;call BDOS Display String function
	CALL	BDOS			;

	;Done -- exit
EXIT	LD	SP,$-$			;Restore stack pointer
	RET				;and exit

;-----	ANSI driver installer messages
BANNER$	BANNER
MINUSE$	DB	'Drive M: in use$'
NO128K$	DB	'Not a 128K system$'
ALRINS$	DB	'Already installed$'
INSTAL$	DB	'Installing ...$'
INSTOK$	DB	0DH,0AH,'ANSI driver successfully installed$'

;=====	Block to move to BIOS
CBEGIN:					;Begin of code to install into BIOS
;-----	Jump to ANSI driver in EXMEM
	;VDOUT replacement
VDOCALL:DB	3EH			;A != 0 for *DO call
	;KBSCAN replacement
KBSCALL:XOR	A			;A == 0 for *KI call
	LD	B,A			;Save to B
	DI				;Disable interrupts before switching bank
	LD	HL,0			;Save SP to exit door
	ADD	HL,SP			;
RELO1	LD	(VCALLSP+1),HL		;
RELO2	LD	SP,CEND+22H		;Stack uses 'Drive M: enabled' message
	LD	A,0FFH			;Map EXMEM page 1 to 0000-7FFF
	OUT	(084H),A		;
	RST	8			;Call ANSI
	PUSH	AF			;Save char and flags
	LD	A,08FH			;Unmap EXMEM page 1 to 0000-7FFF
	OUT	(084H),A		;
	POP	AF			;Restore char and flags
VCALLSP	LD	SP,$-$			;Restore SP
	EI				;Re-enable interrupts
	RET				;Done

;-----	ANSI *DO driver callback to original driver
VDOCLBK	CALL	$-$			;Call original VDOUT routine
	JR	CBKEXIT			;Exit callback routine

;-----	ANSI *KI driver callback to original driver
KBSCLBK	CALL	$-$			;Call original KBSCAN routine
CBKEXIT	PUSH	AF			;Save char and flags
	LD	A,0FFH			;Map EXMEM page 1 to 0000-7FFF
	OUT	(84H),A			;
	POP	AF			;Restore char and flags
	RET				;Return to ANSI driver

CEND:					;End of code to install into BIOS
CLENGTH	EQU	CEND-CBEGIN

;=====	Block to move to EXMEM page 1
BEGIN:	;ANSI driver source address

	PHASE	0000H			;Will be mapped to 0000H

XBEGIN	EQU	$			;Begin of ANSI driver block
	$BREAK				;Should not come here...
	HALT				;Halt system
	DS	8-$			;Move to RST 8

;-----	ANSI driver vector (RST 8)
ANSI	LD	A,B			;Test device flag
	OR	A			;zero for *KI, non-zero for *DO
	JP	NZ,VDANSI		;Jump to ANSI *DO driver
	JP	KBANSI			;Jump to ANSI *KI driver

;-----	VDANSI DO driver
VDANSI:
;	DB	0EDH,0FCH		;$CBREAK
	LD	HL,ESCFLG		;Point to ESC mode flag
	LD	A,(HL)			;
	OR	A			;Test if inside an ESC sequence
	JR	NZ,VDANSI1		;Jump if yes
	LD	A,C			;Test char to send
	CP	' '			;Is displayable?
	JR	NC,VDAOUT		;Go if yes, display it
;	$BREAK
	CP	1BH			;Is Esc?
	JR	Z,VDANSI0		;If yes, store in ESC mode flag
	CP	0DH			;CR?
	JR	Z,VDAOUT		;If yes, send it
	CP	0AH			;LF?
	JR	Z,VDAOUT		;If yes, send it
	CP	07H			;BEL?
	JR	Z,VDAOUT		;If yes, send it
	CP	08H			;BS?
	JR	Z,VDAOUT		;If yes, send it
	CP	09H			;TAB?
	JR	Z,VDAOUT		;If yes, send it
	CP	0CH			;CLRSCR?
	LD	A,1AH			;Translate to ADM-3A CLRSCR
	JP	Z,VVDOUTA		;If yes, send it
	$CBREAK				;Conditional break for unhandled codes
VDAOUT	JP	VVDOUT			;Send original char

VDARST	XOR	A			;Reset ESC mode flag

VDANSI0	LD	(HL),A			;Store ESC mode
	RET				;Exit

	;ESC mode active: check if following ESC
VDANSI1:
	CP	1BH			;Following ESC?
	JR	NZ,VDANSI2		;Go if not
	LD	A,C			;Get char
	CP	'['			;'[' ?
	JR	NZ,VDARST		;If not, exit ESC mode
	LD	(HL),A			;Save to ESC mode
	XOR	A			;Clear args area
	LD	B,8			;8 bytes to clear
VDANS11	INC	HL			;Clear them
	LD	(HL),A			;
	DJNZ	VDANS11			;
	RET				;Done

	;Check if following ESC'['
VDANSI2	CP	'['			;Following ESC'['?
	JR	NZ,VDANSI3		;Go if not
	LD	A,C			;Get char
	CP	';'			;Argument separator ';' ?
	JR	NZ,VDANSI4		;Go if not
	;Shift arguments
	INC	HL			;Shift arguments
	LD	D,H			; ARG1 <- ARG2
	LD	E,L			; ARG2 <- ARG3
	INC	HL			; ARG3 <- 0
	INC	HL			;
	LD	BC,6			;
	LDIR				;
	RET				;Done

	;Unhandled char following ESC
VDANSI3
	$BREAK
	JR	VDARST			;Exit ESC mode and return

	;Not ';', check for digit
VDANSI4	CP	'9'+1			;Is the char a digit?
	JR	NC,VDANSI5		;Go if above digits
	SUB	'0'			;
	RET	C			;Return if below
	;calc ARG3 = 10 * ARG3 + digit value
	LD	C,A			;Digit value to BC
	LD	B,0			;
	LD	HL,(ARG3)		;HL = ARG3, the last arg
	LD	D,H			;HL *= 10
	LD	E,L			;
	ADD	HL,HL			;
	ADD	HL,HL			;
	ADD	HL,DE			;
	ADD	HL,HL			;
	ADD	HL,BC			;HL += BC, the digit value
	LD	(ARG3),HL		;Store to ARG3
	RET				;done

	;Check and process command
VDANSI5	CP	'A'			;Is char a letter ?
	RET	C			;Return if below upper case letters
	CP	'z'+1			;
	RET	NC			;Return if above lower case letters
	CP	'a'			;
	JR	NC,VDANS51		;Continue if above lower case letters
	CP	'Z'+1
	RET	NC			;Return if above upper case letters
VDANS51	LD	(HL),0			;reset ESCFLG to exit ESC mode
	LD	HL,(ARG2)		;Get ARG2
	EX	DE,HL			;  to DE
	LD	HL,(ARG3)		;Get ARG3 to HL
	LD	C,1			;Will be used later in commands

	;Process ESC commands

	;Inverse video ON or OFF
	;ESC'['attr'm'
	CP	'm'			;'m' command
	JR	NZ,VDANS52		;Go if not
	LD	A,L			;get attr code
	CP	50			;less than 50?
	RET	NC			;exit if not
	LD	DE,TATTR		;Attribute conversion table
	ADD	HL,DE			;Add offset
	LD	A,(HL)			;Get converted value
	ADD	A,0EH			;0E to set/0F to clear reverse mode
	JP	VVDOUTA			;Send 0E/0F and exit

VDANS52:
	;Relocate cursor to (x,y)
	;ESC'['x';'y'H'
	;ESC'['x';'y'f'
	;x and y: 0 becomes 1
	CP	'H'			;'H' command
	JR	Z,VDAN521		;Go if not
	CP	'f'			;'f' command synonym
	JR	NZ,VDANS53		;Go if not
VDAN521	LD	A,L			;get y
	SUB	C			;dec and set Cy if 0
	ADC	A,20H			;add 32 with Cy
	PUSH	AF			;save y+32
	LD	A,E			;get x
	SUB	C			;dec and set Cy if 0
	ADC	A,20H			;add 32 with Cy
	PUSH	AF			;save x+32
	LD	C,1BH			;send ESC
	CALL	VVDOUT			;
	LD	C,'='			;send '='
	CALL	VVDOUT			;
	POP	AF			;restore x+32
	CALL	VVDOUTA			;send x+32
	POP	AF			;restore y+32
	JP	VVDOUTA			;send y+32 and exit

VDANS53:
	;CLRSCR or CLREOS
	;ESC'['n'J'
	CP	'J'			;'J' command
	JR	NZ,VDANS54		;Go if not
	LD	A,L			;Get argument
	CP	2			;Test if =2
	LD	C,1AH			;CLRSCR if yes
	JR	Z,VVDA531		;
	LD	C,17H			;CLREOS otherwise
VVDA531	JP	VVDOUT			;Send it and exit

VDANS54:
	;CLRSCR or CLREOS
	;ESC'[K'
	CP	'K'			;'K' command
	JR	NZ,VDANS55		;Go if not
	LD	C,15H			;send CLREOL
	JP	VVDOUT			;and exit

VDANS55:
	;INSERT LINE
	;ESC'[L'
	CP	'L'			;'L' command
	JR	NZ,VDANS56		;Go if not
	LD	C,1CH			;send INSLINE
	JP	VVDOUT			;and exit

VDANS56:
	;DELETE LINE
	;ESC'[M'
	CP	'M'			;'M' command
	JR	NZ,VDANS57		;Go if not
	LD	C,1DH			;send DELLINE
	JP	VVDOUT			;and exit

VDANS57:
	;SET OPTIONS
	;ESC'['func'h'
	CP	'h'			;'h' command
	JR	NZ,VDANS58		;Go if not
	LD	A,L			;get arg
	CP	25			;arg = set cursor (25)?
	RET	NZ			;exit if not
	LD	C,1BH			;send <ESC>
	CALL	VVDOUT			;
	LD	C,'1'			;send cursor on
	JP	VVDOUT			;and exit

VDANS58:
	;RESET OPTIONS
	;ESC'['func'l'
	CP	'l'			;'l' command
	JR	NZ,VDANS59		;Go if not
	LD	A,L			;get arg
	CP	25			;reset cursor?
	RET	NZ			;exit if not
	LD	C,1BH			;send <ESC>
	CALL	VVDOUT			;
	LD	C,'0'			;cursor off (TODO: 0)
	JP	VVDOUT			;and exit

VDANS59:
	;MOVE CURSOR UP n LINES
	;ESC'['n'A'
	CP	'A'			;'A' command
	JR	NZ,VDANS5A		;Go if not
	LD	E,0BH			;Cursor up (VDVT)
	JR	VDAN5C1			;Send it L times

VDANS5A:
	;MOVE CURSOR DOWN n LINES
	;ESC'['n'B'
	CP	'B'			;'B' command
	JR	NZ,VDANS5B		;Go if not
	LD	E,0AH			;Cursor down (VDLF)
	JR	VDAN5C1			;Send it L times

VDANS5B:
	;MOVE CURSOR RIGHT n COLS
	;ESC'['n'C'
	CP	'C'			;'C' command
	JR	NZ,VDANS5C		;Go if not
	LD	E,0CH			;Cursor right (VDCRT)
	JR	VDAN5C1			;Send it L times

VDANS5C:
	;MOVE CURSOR LEFT n COLS
	;ESC'['n'D'
	CP	'D'			;'D' command
	JR	NZ,VDANS5X		;Go if not
	LD	E,08H			;cursor left (VDCLT)

	;Repeat char in C, L times
VDAN5C1
	LD	A,L			;get arg from L
	SUB	C			;if 0 change to 1
	ADC	A,C			;
	LD	B,A			;repeat count to B
	LD	C,E			;Char to C
VDAN5C2	PUSH	BC			;Save char and counter
	CALL	VVDOUT			;send char
	POP	BC			;Restore char and counter
	DJNZ	VDAN5C2			;Repeat B times
	RET				;Done

VDANS5X:
	;Unrecognized command
	$BREAK				;Unconditional emulator break
	RET				;Ignore and return

VVDOUTA	LD	C,A			;Display char in A
VVDOUT	JP	$-$			;gets VDOCLBK: display char in C

;------	ANSI Keyboard scan replacement routine
KBANSI:	;Scan for pending keystrokes
	LD	HL,KBNEXT		;Point to pending keystrokes
	LD	A,(HL)			;Get next keystroke
	OR	A			;Is there a pending keystroke?
	JR	Z,VKBSCAN		;Go if not
	$CBREAK				;Conditional break for debugging
	LD	D,H			;Shift left next pending keystrokes
	LD	E,L			;
	INC	HL			;
	LD	BC,0007H		;
	LDIR				;
	RET				;Return pending keystroke

VKBSCAN	;No pending keystrokes, call BIOS KBSCAN routine
	CALL	$-$			;Call original KBSCAN via callback
	OR	A			;Is there a keystroke?
	RET	Z			;Return with Z if not
	$CBREAK				;Conditional break for debugging
	LD	HL,KBNEXT		;HL = next pending keystroke pointer
	IF	0			;Enable special [Esc] treatment
	CP	1BH			;[Esc]?
	JR	NZ,KBANSI0		;Go if not
	LD	(HL),A			;post another [Esc]
	OR	A			;Set Z flag
	RET				;done
	ENDIF				;end conditional block
	CP	1CH			;is it Shift-Clear?
	LD	C,18H			;to replace with Ctrl-X
	JR	Z,KBANSIC		;if yes, replace DEL with BSP
	CP	7FH			;is it DEL?
	LD	C,08H			;to replace with BSP
	JR	Z,KBANSIC		;if yes, replace DEL with BSP
	CP	18H			;is it Ctrl-X?
	JR	Z,KBANSIC		;if yes, replace
	INC	C			;to replace with TAB
	CP	19H			;is it Ctrl-Y?
	JR	NZ,KBANSI0		;Go if not

KBANSIC	LD	A,C			;Else replace char code
	OR	A			;Clear Z
	RET				;Done

KBANSI0:;Replace arrow keys with their corresponding ANSI sequences
	CP	08H			;below [Left]?
	RET	C			;exit if yes
	CP	0CH			;above [Right]?
	JR	C,KBANSI1		;Go if not
	OR	A			;Else clear Z
	RET				;Done

KBANSI1:
	NEG				;Convert 8,9,10,11 to 'D','C','B','A'
	ADD	A,'D'+8			;A := 'D' - ( A - 8 )
	LD	(HL),5BH		;post '['
	INC	HL			;
	LD	(HL),A			;post direction code
	LD	A,1BH			;Return [Esc]
	OR	A			;Clear Z
	RET				;Done


TATTR:
	;Attributes translation table
	DB	0,0,0,0,0,0,0,1,0,0	;00-09 - 007=reverse on
	DB	0,0,0,0,0,0,0,0,0,0	;10-19
	DB	0,0,0,0,0,0,0,0,0,0	;20-29
	DB	1,0,0,0,0,0,0,0,0,0	;30-39 - 30 = black
	DB	0,0,0,0,0,0,0,0,0,0	;40-49


	;Variables
ESCFLG	DB	0			;ESCAPE state flag for *DO
ARG1	DW	0			;ARG1
ARG2	DW	0			;ARG2
ARG3	DW	0			;ARG3
ARG00	DW	0			;Dummy
KBLAST	DB	0			;Last *KI char
KBNEXT	DC	8,0			;Up to 7 pending *KI chars

XEND	EQU	$			;End of ANSI driver block

XLENGTH	EQU	XEND-XBEGIN

	DEPHASE

OFFSET	EQU	BEGIN-XBEGIN

	END	START
