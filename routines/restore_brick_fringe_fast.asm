; Empty no-magnet fringe cells always have complementary C/E bits.
; Preserve texture HL in DE while updating video; no per-row stack/magnet scan.
NativeRestoreFringeFast:
 ld a,(NativeRestoreClip+1)
 ld (nff_clip+1),a
 cpl
 ld (nff_keep+1),a
 ld a,(NativeRestoreMask+1)
 ld (nff_horizontal+1),a
nff_row:
 ld a,(hl)
nff_horizontal:
 and $ff
 ld c,a
 ld a,e
 and 7
 jp nz,nff_last
 ld a,(NativeRestoreTopMask)
 and c
 ld c,a
 jp nff_pixel
nff_last:
 cp 1
 jp nz,nff_pixel
 ld a,(NativeRestoreBottomMask)
 and c
 ld c,a
nff_pixel:
 ld a,c
nff_clip:
 and $ff
 ld c,a
 ex de,hl
 ld a,(hl)
nff_keep:
 and 0
 or c
 ld (hl),a
 ld c,a
 ld a,h
 add $20
 ld h,a
 ld a,c
 cpl
 ld (hl),a
 ld a,h
 sub $20
 ld h,a
 ex de,hl
 dec hl
 dec e
 dec b
 jp nz,nff_row
 pop de
 ret
