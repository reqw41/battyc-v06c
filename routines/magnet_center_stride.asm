NativeSampleCenterStride:
 ld de,0
 ld a,l
 sub e
 ld l,a
 ld a,h
 sbc a,d
 ld h,a
 jp MagnetSampleCenterRead
