;*****************************************************************
; Main Game File
;*****************************************************************

.include "NESLib.inc"
.include "Player.inc"
 
.export main   
;*****************************************************************
; Import both the background and sprite character sets
;*****************************************************************

.segment "TILES"
.incbin "NESDungeone.chr"

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
	jsr init_player
	; get the screen to render
	jsr ppu_update

mainloop:
	; skip reading controls if and change has not been drawn
	lda nmi_ready
	cmp #0
	bne mainloop
	; read the gamepad
	jsr gamepad_poll
	jsr update_player
	; ensure our changes are rendered
	lda #1
	sta nmi_ready
	jmp mainloop
.endproc

;*****************************************************************
; Our default palette table 16 entries for tiles and 16 entries for sprites
;*****************************************************************

.segment "RODATA"
default_palette:
.incbin "NESDungeone.pal"
default_nametable:
.incbin "NESDungeone.nam"


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