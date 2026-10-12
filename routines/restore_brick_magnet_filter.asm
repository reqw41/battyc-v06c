; JS-modelled conservative byte footprint: four columns, ten rows.
; The brick is always restored as plain texture. Every magnet whose 4x24
; byte footprint can share a touched byte is marked for a cached repaint.
; The count also keeps the cautious queue portion next to a magnet.
NativeRestoreChooseMagnets:
 xor a
 ld (NativeRestoreMagnetCount),a
 ld a,(magnets_quantity)
 or a
 ret z
 ld b,a
 ld hl,(NativeRestoreOrigin)
 ld a,l
 rrca
 rrca
 rrca
 and 31
 dec a
 ld (NativeRestoreBoundLeft),a
 add a,4
 ld (NativeRestoreBoundRight),a
 ld a,h
 dec a
 ld (NativeRestoreBoundTop),a
 add a,10
 ld (NativeRestoreBoundBottom),a
 ld hl,magnet_properties+2
 ld de,MagnetRedrawFlags
nrmf_magnet:
 push hl
 ld a,(hl)
 sub 5
 rrca
 rrca
 rrca
 and 31
 ld c,a
 add a,4
 ld l,a
 ld a,(NativeRestoreBoundLeft)
 cp l
 jp nc,nrmf_next
 ld a,(NativeRestoreBoundRight)
 cp c
 jp c,nrmf_next
 jp z,nrmf_next
 pop hl
 push hl
 inc hl
 inc hl
 ld a,(hl)
 sub 5
 ld c,a
 add a,MagRows
 ld l,a
 ld a,(NativeRestoreBoundTop)
 cp l
 jp nc,nrmf_next
 ld a,(NativeRestoreBoundBottom)
 cp c
 jp c,nrmf_next
 jp z,nrmf_next
 ld a,1
 ld (de),a
 ld (NativeRestoreMagnetCount),a
nrmf_next:
 pop hl
 ld a,16
 call hl_add_a
 inc de
 dec b
 jp nz,nrmf_magnet
 ret
