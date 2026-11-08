; CH05 - Programming Games for NES
; Base NES game shell demo

;*****************************************************************
; Define NES control register values
;*****************************************************************

; Define PPU Registers
PPU_CONTROL = $2000 ; PPU Control Register 1 (Write)
PPU_MASK = $2001 ; PPU Control Register 2 (Write)
PPU_STATUS = $2002; PPU Status Register (Read)
PPU_SPRRAM_ADDRESS = $2003 ; PPU SPR-RAM Address Register (Write)
PPU_SPRRAM_IO = $2004 ; PPU SPR-RAM I/O Register (Write)
PPU_VRAM_ADDRESS1 = $2005 ; PPU VRAM Address Register 1 (Write)
PPU_VRAM_ADDRESS2 = $2006 ; PPU VRAM Address Register 2 (Write)
PPU_VRAM_IO = $2007 ; VRAM I/O Register (Read/Write)
SPRITE_DMA = $4014 ; Sprite DMA Register

; Define APU Registers
APU_DM_CONTROL = $4010 ; APU Delta Modulation Control Register (Write)
APU_CLOCK = $4015 ; APU Sound/Vertical Clock Signal Register (Read/Write)

; Joystick/Controller values
JOYPAD1 = $4016 ; Joypad 1 (Read/Write)
JOYPAD2 = $4017 ; Joypad 2 (Read/Write)

; Gamepad bit values
PAD_A      = $01
PAD_B      = $02
PAD_SELECT = $04
PAD_START  = $08
PAD_U      = $10
PAD_D      = $20
PAD_L      = $40
PAD_R      = $80

;*****************************************************************
; Define NES cartridge Header
;*****************************************************************

.segment "HEADER"
INES_MAPPER = 0 ; 0 = NROM
INES_MIRROR = 0 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0 ; 1 = battery backed SRAM at $6000-7FFF

.byte 'N', 'E', 'S', $1A ; ID 
.byte $02 ; 16k PRG bank count
.byte $01 ; 8k CHR bank count
.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
.byte (INES_MAPPER & %11110000)
.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding

;*****************************************************************
; Import both the background and sprite character sets
;*****************************************************************

.segment "TILES"
.incbin "NESDungeone.chr"

;*****************************************************************
; Define NES interrupt vectors
;*****************************************************************

.segment "VECTORS"
.word nmi
.word reset
.word irq

;*****************************************************************
; 6502 Zero Page Memory (256 bytes)
;*****************************************************************

.segment "ZEROPAGE"

nmi_ready:		.res 1 ; set to 1 to push a PPU frame update, 
					   ;        2 to turn rendering off next NMI
gamepad:		.res 1 ; stores the current gamepad values

d_x:			.res 1 ; x velocity of ball
d_y:			.res 1 ; y velocity of ball

;*****************************************************************
; Sprite OAM Data area - copied to VRAM in NMI routine
;*****************************************************************

.segment "OAM"
oam: .res 256	; sprite OAM data

;*****************************************************************
; Remainder of normal RAM area
;*****************************************************************

.segment "BSS"
palette: .res 32 ; current palette buffer

;*****************************************************************
; Some useful functions
;*****************************************************************

.segment "CODE"
; ppu_update: waits until next NMI, turns rendering on (if not already), uploads OAM, palette, and nametable update to PPU
.proc ppu_update
	lda #1
	sta nmi_ready
	loop:
		lda nmi_ready
		bne loop
	rts
.endproc

; ppu_off: waits until next NMI, turns rendering off (now safe to write PPU directly via PPU_VRAM_IO)
.proc ppu_off
	lda #2
	sta nmi_ready
	loop:
		lda nmi_ready
		bne loop
	rts
.endproc

;*****************************************************************
; Main application entry point for starup/reset
;*****************************************************************

.segment "CODE"
.proc reset
	sei			; mask interrupts
	lda #0
	sta PPU_CONTROL	; disable NMI
	sta PPU_MASK	; disable rendering
	sta APU_DM_CONTROL	; disable DMC IRQ
	lda #$40
	sta JOYPAD2		; disable APU frame IRQ

	cld			; disable decimal mode
	ldx #$FF
	txs			; initialise stack

	; wait for first vBlank
	bit PPU_STATUS
wait_vblank:
	bit PPU_STATUS
	bpl wait_vblank

	; clear all RAM to 0
	lda #0
	ldx #0
clear_ram:
	sta $0000,x
	sta $0100,x
	sta $0200,x
	sta $0300,x
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	inx
	bne clear_ram

	; place all sprites offscreen at Y=255
	lda #255
	ldx #0
clear_oam:
	sta oam,x
	inx
	inx
	inx
	inx
	bne clear_oam

; wait for second vBlank
wait_vblank2:
	bit PPU_STATUS
	bpl wait_vblank2
	
	; NES is initialized and ready to begin
	; - enable the NMI for graphical updates and jump to our main program
	lda #%10001000
	sta PPU_CONTROL
	jmp main
.endproc

;*****************************************************************
; NMI Routine - called every vBlank
;*****************************************************************

.segment "CODE"
.proc nmi
	; save registers
	pha
	txa
	pha
	tya
	pha

	lda nmi_ready
	bne :+ ; nmi_ready == 0 not ready to update PPU
		jmp ppu_update_end
	:
	cmp #2 ; nmi_ready == 2 turns rendering off
	bne cont_render
		lda #%00000000
		sta PPU_MASK
		ldx #0
		stx nmi_ready
		jmp ppu_update_end
cont_render:

	; transfer sprite OAM data using DMA
	ldx #0
	stx PPU_SPRRAM_ADDRESS
	lda #>oam
	sta SPRITE_DMA

	; transfer current palette to PPU
	lda #%10011000 ; set horizontal nametable increment
	sta PPU_CONTROL 
	lda PPU_STATUS
	lda #$3F ; set PPU address to $3F00
	sta PPU_VRAM_ADDRESS2
	stx PPU_VRAM_ADDRESS2
	ldx #0 ; transfer the 32 bytes to VRAM
loop:
	lda palette, x
	sta PPU_VRAM_IO
	inx
	cpx #32
	bcc loop

	; enable rendering
	lda #%00011110
	sta PPU_MASK
	; flag PPU update complete
	ldx #0
	stx nmi_ready
ppu_update_end:

	; restore registers and return
	pla
	tay
	pla
	tax
	pla
	rti
.endproc

;*****************************************************************
; IRQ Clock Interrupt Routine
;*****************************************************************

.segment "CODE"
irq:
	rti

;*****************************************************************
; Main application logic section includes the game loop
;*****************************************************************
 .segment "CODE"
 .proc main
 	; main application - rendering is currently off

 	; initialize palette table
 	ldx #0
paletteloop:
	lda default_palette, x
	sta palette, x
	inx
	cpx #32
	bcc paletteloop

 	; clear 1st name table
 	jsr clear_nametable

 	; Load our custom 160x160 full screen nametable layout
 	lda PPU_STATUS	; reset address latch
 	lda #$20		; set PPU address to start of Nametable 0 ($2000)
 	sta PPU_VRAM_ADDRESS2
 	lda #$00
 	sta PPU_VRAM_ADDRESS2

 	ldx #0
nametable_loop:
 	lda default_nametable, x       ; First 256 bytes
 	sta PPU_VRAM_IO
 	lda default_nametable+256, x   ; Second 256 bytes
 	sta PPU_VRAM_IO
 	lda default_nametable+512, x   ; Third 256 bytes
 	sta PPU_VRAM_IO
 	lda default_nametable+768, x   ; Fourth 256 bytes (including attributes)
 	sta PPU_VRAM_IO
 	inx
 	bne nametable_loop	; Loops 256 times to transfer all 1024 bytes


 	; render here (might need extra level load system)

 	; get the screen to render
 	jsr ppu_update

 mainloop:
 	; skip reading controls if and change has not been drawn
 	lda nmi_ready
 	cmp #0
 	bne mainloop
 	; read the gamepad
 	jsr gamepad_poll

 	; ensure our changes are rendered
 	lda #1
 	sta nmi_ready
 	jmp mainloop
.endproc

.segment "CODE"
.proc clear_nametable
 	lda PPU_STATUS ; reset address latch
 	lda #$20 ; set PPU address to $2000
 	sta PPU_VRAM_ADDRESS2
 	lda #$00
 	sta PPU_VRAM_ADDRESS2

 	; empty nametable
 	lda #0
 	ldy #30 ; clear 30 rows
 	rowloop:
 		ldx #32 ; 32 columns
 		columnloop:
 			sta PPU_VRAM_IO
 			dex
 			bne columnloop
 		dey
 		bne rowloop

 	; empty attribute table
 	ldx #64 ; attribute table is 64 bytes
 	loop:
 		sta PPU_VRAM_IO
 		dex
 		bne loop
 	rts
 .endproc

;*****************************************************************
; gamepad_poll: this reads the gamepad state into the variable labelled "gamepad"
; This only reads the first gamepad, and also if DPCM samples are played they can
; conflict with gamepad reading, which may give incorrect results.
;*****************************************************************

.segment "CODE"
.proc gamepad_poll
	; strobe the gamepad to latch current button state
	lda #1
	sta JOYPAD1
	lda #0
	sta JOYPAD1
	; read 8 bytes from the interface at $4016
	ldx #8
loop:
	pha
	lda JOYPAD1
	; combine low two bits and store in carry bit
	and #%00000011
	cmp #%00000001
	pla
	; rotate carry into gamepad variable
	ror
	dex
	bne loop
	sta gamepad
	rts
.endproc

;*****************************************************************
; Our default palette table 16 entries for tiles and 16 entries for sprites
;*****************************************************************

.segment "RODATA"
default_palette:
.incbin "test.pal"
default_nametable:
.incbin "test.nam"


; 	; now move the bat if left or right pressed
;  	lda gamepad
;  	and #PAD_L
;  	beq NOT_GAMEPAD_LEFT
;  		; gamepad has been pressed left
;  		lda oam + 3 ; get current X
;  		cmp #0
;  		beq NOT_GAMEPAD_LEFT
;  		sec
;  		sbc #1
;  		sta oam + 3 ; change X to the left
;  NOT_GAMEPAD_LEFT:
;  	lda gamepad
;  	and #PAD_R
;  	beq NOT_GAMEPAD_RIGHT
;  		; gamepad has been pressed right
;  		lda oam + 3 ; get current X
;  		cmp #248
;  		beq NOT_GAMEPAD_RIGHT
;  		clc
;  		adc #1
;  		sta oam + 3 ; change X to the left
;  NOT_GAMEPAD_RIGHT:
;  	; now move our ball
;  	lda oam + (1 * 4) + 0 ; get the current Y
; 	clc
; 	adc d_y ; add the Y velocity
;  	sta oam + (1 * 4) + 0 ; write the change
;  	cmp #0 ; have we hit the top border
;  	bne NOT_HITTOP
;  		lda #1 ; reverse direction
;  		sta d_y
;  NOT_HITTOP:
;  	lda oam + (1 * 4) + 0
;  	cmp #210 ; have we hit the bottom border
;  	bne NOT_HITBOTTOM
;  		lda #$FF ; reverse direction (-1)
;  		sta d_y
;  NOT_HITBOTTOM:
;  	lda oam + (1 * 4) + 3 ; get the current x
;  	clc
;  	adc d_x	; add the X velocity
;  	sta oam + (1 * 4) + 3
;  	cmp #0 ; have we hit the left border
;  	bne NOT_HITLEFT
;  		lda #1 ; reverse direction
;  		sta d_x
;  NOT_HITLEFT:
;  	lda oam + (1 * 4) + 3
;  	cmp #248 ; have we hot the right border
;  	bne NOT_HITRIGHT
;  		lda #$FF ; reverse direction (-1)
;  		sta d_x
;  NOT_HITRIGHT: