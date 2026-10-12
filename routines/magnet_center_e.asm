MagnetCenterE:
 ld a,(MagnetCenterOff)
 or a
 ld a,e
 jp nz,MagnetCenterEOn
 cpl
 and (hl)
 jp MagnetCenterEStore
MagnetCenterEOn:
 or (hl)
MagnetCenterEStore:
 ld (hl),a
 ld a,h
 sub $40
 ld h,a
 ret
