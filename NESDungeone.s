;*****************************************************************
; Main Game File
;*****************************************************************

.include "NESLib.inc"
.include "Player.inc"
.include "Enemy.inc"
 
.export main   
;*****************************************************************
; Import both the background and sprite character sets
;*****************************************************************

.segment "ZEROPAGE"
nam_ptr: .res 2
current_level: .res 1
game_state:    .res 1

STATE_TITLE   = 0
STATE_PLAYING = 1

.segment "TILES"
.incbin "main.chr"

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

	 lda #<startScreen
    sta nam_ptr
    lda #>startScreen
    sta nam_ptr+1
    jsr load_new_screen

    lda #STATE_TITLE
    sta game_state

	; get the screen to render
	jsr ppu_update

	

mainloop:
	; skip reading controls if and change has not been drawn
	lda nmi_ready
	cmp #0
	bne mainloop
	; read the gamepad
	jsr gamepad_poll
	 lda game_state
    cmp #STATE_TITLE
    bne playing
        jsr update_title
        jmp done
playing:
        jsr update_player
		jsr update_enemy
done:
    lda #1
    sta nmi_ready
    jmp mainloop
.endproc

.proc update_title
    lda gamepad
    and #PAD_START
    beq not_pressed
        jsr start_game
not_pressed:
    rts
.endproc


.segment "CODE"
.proc load_new_screen
	jsr ppu_off             ; Turn off screen safely on next VBlank

	lda PPU_STATUS
	lda #$20
	sta PPU_VRAM_ADDRESS2
	lda #$00
	sta PPU_VRAM_ADDRESS2

	ldy #0
	ldx #4                  ; 4 * 256 = 1024 bytes
screen_loop:
	lda (nam_ptr), y
	sta PPU_VRAM_IO
	iny
	bne screen_loop
	inc nam_ptr+1
	dex
	bne screen_loop

	jsr ppu_update          ; Turn screen back on
	rts
.endproc


.proc start_game
    lda #<default_nametable
    sta nam_ptr
    lda #>default_nametable
    sta nam_ptr+1
    jsr load_new_screen     ; turns the screen off, loads Level 1, turns it back on

    jsr init_player
	jsr init_enemy_room1

    lda #STATE_PLAYING
    sta game_state
    rts
.endproc

;*****************************************************************
; Our default palette table 16 entries for tiles and 16 entries for sprites
;*****************************************************************

.segment "RODATA"
default_palette:
;.incbin "NESDungeone.pal"
.byte $0F,$16,$27,$30,  $0F,$11,$21,$30,  $0F,$19,$29,$30,  $0F,$14,$24,$34 ;temp colors until the actual .pal file is fixed
.byte $0F,$16,$27,$30,  $0F,$11,$21,$30,  $0F,$19,$29,$30,  $0F,$14,$24,$34
startScreen:
.incbin "startScreen.nam"
default_nametable:
.incbin "Level1.nam"
screen2_nametable:
.incbin "Level2.nam"

NUM_LEVELS = 2 

level_table_lo:
	.byte <default_nametable, <screen2_nametable
level_table_hi:
	.byte >default_nametable, >screen2_nametable


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