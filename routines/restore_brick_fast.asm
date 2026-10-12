; Full empty tile column, no magnets. Copy C, invert into E, PUSH zeros into A.
NativeRestoreCopyFull:
 ld (NativeRestoreCopySource+1),hl
 ex de,hl
 ld (NativeRestoreCopyBase+1),hl
 ld hl,0
 add hl,sp
 ld (NativeRestoreCopyReturn+1),hl
NativeRestoreCopyBase:
 ld hl,0
 inc l
 di
 ld sp,hl
NativeRestoreCopySource:
 ld hl,0
 ld a,(NativeRestoreMask+1)
 ld c,a
 ld b,4
NativeRestoreCopyPair:
 ld a,(hl)
 and c
 ld d,a
 ld a,b
 cp 4
 jp nz,NativeRestoreCopyTopDone
 ld a,(NativeRestoreTopMask)
 and d
 ld d,a
NativeRestoreCopyTopDone:
 dec hl
 ld a,(hl)
 and c
 ld e,a
 ld a,b
 cp 1
 jp nz,NativeRestoreCopyBottomDone
 ld a,(NativeRestoreBottomMask)
 and e
 ld e,a
NativeRestoreCopyBottomDone:
 push de
 dec hl
 dec b
 jp nz,NativeRestoreCopyPair
 ld hl,(NativeRestoreCopyBase+1)
 ld a,h
 add $20
 ld h,a
 inc l
 ld sp,hl
 dec l
 ld a,h
 sub $20
 ld h,a
 ld b,4
NativeRestoreInvertPair:
 ld a,(hl)
 cpl
 ld d,a
 dec l
 ld a,(hl)
 cpl
 ld e,a
 dec l
 push de
 dec b
 jp nz,NativeRestoreInvertPair
 ld hl,(NativeRestoreCopyBase+1)
 ld a,h
 sub $20
 ld h,a
 inc l
 ld sp,hl
 ld de,0
 DUP 4
 push de
 EDUP
NativeRestoreCopyReturn:
 ld sp,0
 ei
 pop de
 ret

