MagnetSampleCenterRead:
 inc hl
 ld a,(hl)
 call NativeSampleShift
 ld b,a
 ld a,(NativeSampleByte)
 cp 1
 ld a,b
 ret z
 ld a,c
 ret
