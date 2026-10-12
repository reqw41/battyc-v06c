MagnetCenterSetup:
 ld hl,(MagnetCenterDest)
 ld a,h
 add $31
 ld h,a
 ld a,$d8
 sub l
 ld l,a
 ld b,8
 jp MagnetCenterRow
