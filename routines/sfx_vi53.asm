; One event voice: no chord/continuous bed. D=duration in IRQ frames.
; Include the current partial IRQ interval, then D complete intervals.
; Follow the audible interval with an idle IRQ interval.
SfxTone:
 ld a,(MusicActive)
 or a
 ret nz
 ld a,(SfxCooldown)
 or a
 ret nz
 push bc
 push de
 push hl
 di
 ld a,d
 inc a
 ld (SfxWait),a
 inc a
 ld (SfxCooldown),a
 ld l,e
 ld h,0
 add hl,hl
 add hl,hl
 ld d,h
 ld e,l
 add hl,hl
 add hl,de
 ld de,32
 add hl,de
 ld a,$36
 out ($08),a
 ld a,l
 out ($0b),a
 ld a,h
 out ($0b),a
 ei
 pop hl
 pop de
 pop bc
 ret
SfxTick:
 ld a,(MusicActive)
 or a
 ret nz
 ld a,(SfxCooldown)
 or a
 jp z,SfxTickWait
 dec a
 ld (SfxCooldown),a
SfxTickWait:
 ld a,(SfxWait)
 or a
 ret z
 dec a
 ld (SfxWait),a
 ret nz
 ld a,$30
 out ($08),a
 ret
SfxWait: db 0,0,0 ; three bytes retained for MusicMute/reset compatibility
SfxCooldown: db 0
