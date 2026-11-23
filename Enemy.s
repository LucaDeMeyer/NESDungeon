;*****************************************************************
; Enemy Logic
;*****************************************************************
.include "NESLib.inc"
.include "Enemy.inc"


MAX_ENEMIES = 4 ; the amount of enemies in the room with the highest amount of enemies, needed to reserve te memory for that room


.segment "ZEROPAGE"

current_enemies:    .res 2 ;this can change each room 
enemy_x:            .res MAX_ENEMIES ;enemy X pos
enemy_y:            .res MAX_ENEMIES ;enemy Y pos
enemy_speed:        .res MAX_ENEMIES ;enemy speed (if enemies can have different speeds) idk yet
enemy_direction_x:  .res MAX_ENEMIES ; X direction of the enemy movement 
enemy_direction_y:  .res MAX_ENEMIES ; Y direction of the enemy movement 

ANIM_DELAY = 20             ; game frames to show each animation frame (60 per second / 20 = 3 anim fps)

ANIM_IDLE = 0
ANIM_WALK = 4

.segment "BSS"

anim_base:  .res 1          ; start offset of the current animation (ANIM_IDLE / ANIM_WALK)
anim_frame: .res 1          ; current frame within that animation, 0-3
anim_timer: .res 1          ; game frames until the next animation frame

enemy_flip:    .res 1 ;0 = facing right, $40 = facing left (OAM flip bit)

enemy_health:   .res 1  ; enemy health

.segment "RODATA"
.include "RoomCollisionMaps.asm"

; tile ID of each of the 4 sprites, per animation frame
            ;Idle                       ;walking    
frame_tl: .byte $00, $02, $04, $06,   $20, $22, $24, $26
frame_tr: .byte $01, $03, $05, $07,   $21, $23, $25, $27
frame_bl: .byte $10, $12, $14, $16,   $30, $32, $34, $36
frame_br: .byte $11, $13, $15, $17,   $31, $33, $35, $37

.segment "CODE"
.proc init_enemy_room1
    lda #$02
    sta current_enemies

    ; Enemy 0
    lda #$40
    sta enemy_x
    lda #$50
    sta enemy_y

    ; Enemy 1
    lda #$80
    sta enemy_x+1
    lda #$60
    sta enemy_y+1

    rts
.endproc

.segment "CODE"
.proc update_enemy

.endproc