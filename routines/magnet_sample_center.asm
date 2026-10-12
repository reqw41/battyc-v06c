; Return central glyph bits in A for the sampled destination byte.
MagnetSampleCenter:
 ld a,(NativeSampleRow)
 and $f8
 cp 8
 ld a,0
 ret nz
 ld a,(NativeSampleByte)
 dec a
 cp 2
 ld a,0
 ret nc
 jp MagnetSampleCenterBody
