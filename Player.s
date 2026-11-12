;*****************************************************************
; Player Logic
;*****************************************************************
.include "NESLib.inc"
.include "Player.inc"

.segment "ZEROPAGE"
player_x:       .res 1 ;player X pos
player_y:       .res 1 ;player Y pos
player_speed:   .res 1 ;player speed

.segment "CODE"
.proc init_player
    lda #100
    sta player_x
    sta player_y
    
    lda #1       ; Move 1 pixel per frame
    sta player_speed

    lda #$00
    sta oam+1    ; Top-left ID
    
    lda #$01
    sta oam+5    ; Top-right ID 
    
    lda #$10
    sta oam+9    ; Bottom-left ID
    
    lda #$11
    sta oam+13   ; Bottom-right ID
    
    ; Palette 0 for all pieces
    lda #$00     
    sta oam+2
    sta oam+6
    sta oam+10
    sta oam+14

    rts
.endproc

.segment "CODE"
;Move and draw the player 
.proc update_player
    ; Check Right
    lda gamepad
    and #PAD_R
    beq not_right
        lda player_x
        clc
        adc player_speed
        sta player_x
not_right:
    ; Check Left
    lda gamepad
    and #PAD_L
    beq not_left
        lda player_x
        sec
        sbc player_speed
        sta player_x
not_left:

        ; Check Up
    lda gamepad
    and #PAD_U
    beq not_up
        lda player_y
        sec
        sbc player_speed
        sta player_y
not_up:
    ; Check Down
    lda gamepad
    and #PAD_D
    beq not_down
        lda player_y
        clc
        adc player_speed
        sta player_y
not_down:

    ;DRAW THE 4 SPRITES
    
    ; Top-Left
    lda player_y
    sta oam+0
    lda player_x
    sta oam+3

    ; Top-Right
    lda player_y
    sta oam+4
    lda player_x
    clc
    adc #8       ; Shift 8 pixels right
    sta oam+7

    ; Bottom-Left
    lda player_y
    clc
    adc #8       ; Shift 8 pixels down
    sta oam+8
    lda player_x
    sta oam+11

    ; Bottom-Right
    lda player_y
    clc
    adc #8       ; Shift 8 pixels down
    sta oam+12
    lda player_x
    clc
    adc #8       ; Shift 8 pixels right
    sta oam+15

    rts
.endproc