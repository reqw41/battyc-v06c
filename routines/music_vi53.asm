; Native three-voice round fanfare. New composition, not a ZX transcription.
; Vector timer: control=$08, counter 0=$0b, 1=$0a, 2=$09.
; Mode 3 generates the waveform in hardware; IRQ only changes score events.
; Divisors use the 1.5 MHz timer clock. Zero duration ends the score.
MusicInit:
 xor a
 ld (MusicActive),a
 jp MusicMute
MusicStart:
 xor a
 ld (MusicActive),a
 ld (MusicWait),a
 ld hl,MusicScore
 ld (MusicPointer),hl
 ld a,1
 ld (MusicActive),a
 ret
MusicStop:
 xor a
 ld (MusicActive),a
MusicMute:
 ld (SfxCooldown),a
 ld (SfxWait),a
 ld (SfxWait+1),a
 ld (SfxWait+2),a
 ; Mode 0 without loading a count holds OUT low on all three channels.
 ld a,$30
 out ($08),a
 ld a,$70
 out ($08),a
 ld a,$b0
 out ($08),a
 ret
MusicTick:
 ld a,(MusicActive)
 or a
 ret z
 ld a,(MusicWait)
 or a
 jp z,MusicNext
 dec a
 ld (MusicWait),a
 ret nz
MusicNext:
 push bc
 push de
 push hl
 ld hl,(MusicPointer)
 ld a,(hl)
 or a
 jp z,MusicEnd
 ld (MusicWait),a
 inc hl
 ld a,$36
 out ($08),a
 ld a,(hl)
 out ($0b),a
 inc hl
 ld a,(hl)
 out ($0b),a
 inc hl
 ld a,$76
 out ($08),a
 ld a,(hl)
 out ($0a),a
 inc hl
 ld a,(hl)
 out ($0a),a
 inc hl
 ld a,$b6
 out ($08),a
 ld a,(hl)
 out ($09),a
 inc hl
 ld a,(hl)
 out ($09),a
 inc hl
 ld (MusicPointer),hl
 jp MusicDone
MusicEnd:
 call MusicStop
MusicDone:
 pop hl
 pop de
 pop bc
 ret
MusicActive: db 0
MusicWait: db 0
MusicPointer: dw MusicScore
MusicScore:
 db 6
 dw 2867,3827,11467 ; C5 G4 C3
 db 6
 dw 2275,3827,11467 ; E5 G4 C3
 db 6
 dw 1913,2867,11467 ; G5 C5 C3
 db 6
 dw 2275,3827,11467 ; E5 G4 C3
 db 6
 dw 2554,3409,8590  ; D5 A4 F3
 db 6
 dw 2148,3409,8590  ; F5 A4 F3
 db 6
 dw 1913,3037,7653  ; G5 B4 G3
 db 12
 dw 1433,2275,11467 ; C6 E5 C3
 db 0
