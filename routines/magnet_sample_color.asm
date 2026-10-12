; Preserve central RGB accents while composing stationary magnet layers.
MagnetSampleAccent:
 ld a,(NativeSampleMask)
 cpl
 ld b,a
 ld a,(NativeSampleAccentA)
 and b
 ld (NativeSampleAccentA),a
 ld a,(NativeSampleAccentE)
 and b
 ld (NativeSampleAccentE),a
 call MagnetSampleCenter
 ld b,a
 ld a,(NativeSampleAccentA)
 or b
 ld (NativeSampleAccentA),a
 jp MagnetAccentOff
