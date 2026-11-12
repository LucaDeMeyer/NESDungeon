;*****************************************************************
; Player Logic
;*****************************************************************
.include "NESLib.inc"
.include "Player.inc"

.segment "ZEROPAGE"
player_x:       .res 1 ;player X pos
player_y:       .res 1 ;player Y pos
player_speed:   .res 1 ;player speed

ANIM_DELAY = 20             ; game frames to show each animation frame (60 per second / 20 = 3 anim fps)

ANIM_IDLE = 0
ANIM_WALK = 4

anim_base:  .res 1          ; start offset of the current animation (ANIM_IDLE / ANIM_WALK)
anim_frame: .res 1          ; current frame within that animation, 0-3
anim_timer: .res 1          ; game frames until the next animation frame

.segment "RODATA"
; tile ID of each of the 4 sprites, per animation frame
            ;Idle                       ;walking
frame_tl: .byte $00, $02, $04, $06,   $20, $22, $24, $26
frame_tr: .byte $01, $03, $05, $07,   $21, $23, $25, $27
frame_bl: .byte $10, $12, $14, $16,   $30, $32, $34, $36
frame_br: .byte $11, $13, $15, $17,   $31, $33, $35, $37

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

    lda #ANIM_IDLE
    sta anim_base
    lda #0
    sta anim_frame
    sta anim_timer

    rts
.endproc

.segment "CODE"
;Move and draw the player 
.proc update_player
    jsr move_player
    jsr Update_sprite
    rts
.endproc

.segment "CODE"
.proc move_player
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

.segment "CODE"
.proc Update_sprite
    ;pick which animation should be playing
    lda gamepad
    and #(PAD_U|PAD_D|PAD_L|PAD_R)  ; any direction held?
    beq pick_idle
        lda #ANIM_WALK
        jmp set_anim
pick_idle:
    lda #ANIM_IDLE
set_anim:
    cmp anim_base                   ; is this already the current animation?
    beq advance                     ; yes: keep playing it
    sta anim_base                   ; no: switch to it
    lda #0
    sta anim_frame                  ;restart from its first frame
    sta anim_timer

advance:
    ; step the frame every ANIM_DELAY game frames
    inc anim_timer
    lda anim_timer
    cmp #ANIM_DELAY
    bcc write_tiles                 ; not time yet
    lda #0
    sta anim_timer
    inc anim_frame
    lda anim_frame
    and #%00000011                  ; wrap 4 back to 0
    sta anim_frame

write_tiles:
    ; table index = animation start + current frame
    lda anim_base
    clc
    adc anim_frame
    tax
    lda frame_tl,x
    sta oam+1                       ; top-left tile ID
    lda frame_tr,x
    sta oam+5                       ; top-right tile ID
    lda frame_bl,x
    sta oam+9                       ; bottom-left tile ID
    lda frame_br,x
    sta oam+13                      ; bottom-right tile ID
    rts
.endproc