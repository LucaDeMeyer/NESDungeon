;*****************************************************************
; Collsion Logic
;*****************************************************************

.include "NESLib.inc"
.include "Player.inc"
.export Set_Collison_Map
.export Check_Solid_Tile

.segment "ZEROPAGE"
col_ptr:        .res 2 ;current collison map
col_addr:       .res 2 ;address of the current tile
x_check:        .res 1
y_check:        .res 1

.segment "RODATA"
.include "RoomCollisionMaps.asm"

.segment "CODE"
.proc Set_Collison_Map
    lda current_level
    asl A
    tax
    lda RoomTable, X
    sta col_ptr
    lda RoomTable+1, X
    sta col_ptr+1
    rts
.endproc

.segment "CODE"
.proc Check_Solid_Tile
    ; Calculate (temp_y / 8) * 32 as a 16-bit offset in col_addr
    lda y_check
    and #$F8            ; Clear the bottom 3 bits round down to a multiple of 8
    sta col_addr
    lda #0
    sta col_addr+1      ; Clear the high byte

    asl col_addr        ; Shift the low byte left by 1 bit old bit 7 moves into the Carry flag
    rol col_addr+1      ; Rotate the high byte left by 1 bit pulling spilled Carry bit into bit 0. Both of these actions multiplied the address by two
    asl col_addr        ; Do this again to multiply by 4
    rol col_addr+1 

    ; Add (temp_x / 8) to col_addr
    lda x_check
    lsr A               ; Shift right 1 bit divides X by 2
    lsr A               ; Shift right 1 bit divides X by 4
    lsr A               ; Shift right 1 bit divides X by 8
    clc
    adc col_addr        ; Add the tile column (A) to the low byte of col_addr
    sta col_addr
    lda col_addr+1
    adc #0              ; Add 0 + the Carry flag if low byte overflowed past 255 this increments high byte by 1
    sta col_addr+1      ; Save the updated high byte back into col_addr+1

    ;Add base pointer to get final ROM address
    lda col_addr
    clc
    adc col_ptr
    sta col_addr
    lda col_addr+1
    adc col_ptr+1       
    sta col_addr+1    

    ; Read the tile byte
    ldy #0
    lda (col_addr), y
    beq walkable
        sec             ; Set carry flag on walk
        rts
walkable:
    clc                 ; Clear carry flag on no walk
    rts
.endproc