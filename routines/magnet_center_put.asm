MagnetCenterPut:
 ld e,a
 or (hl)
 ld (hl),a
 ld a,h
 add $20
 ld h,a
 ld a,e
 or (hl)
 ld (hl),a
 ld a,h
 add $20
 ld h,a
 jp MagnetCenterE
