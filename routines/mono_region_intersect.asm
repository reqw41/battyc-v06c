MonoRegionsIntersect:
 ld b,(hl)
 inc hl
 ld c,(hl)
 ld a,(de)
 cp c
 jp nc,mri_no
 inc de
 ld a,(de)
 cp b
 jp c,mri_no
 jp z,mri_no
 inc hl
 ld b,(hl)
 inc hl
 ld c,(hl)
 inc de
 ld a,(de)
 cp c
 jp c,mri_no
 inc de
 ld a,(de)
 cp b
 jp c,mri_yes
 jp z,mri_yes
mri_no:
 xor a
 ret
mri_yes:
 ld a,1
 ret
