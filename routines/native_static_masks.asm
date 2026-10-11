NativeStaticMasks:
 ld a,(background_color)
 ld b,a
 and 4
 ld a,0
 jp z,nsc_mask_a
 cpl
nsc_mask_a:
 ld (nsc_a+1),a
 ld a,b
 and 2
 ld a,0
 jp z,nsc_mask_c
 cpl
nsc_mask_c:
 ld (nsc_c+1),a
 ld a,b
 and 1
 ld a,0
 jp z,nsc_mask_e
 cpl
nsc_mask_e:
 ld (nsc_e+1),a
 ret
