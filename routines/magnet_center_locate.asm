MagnetSampleCenterBody:
 ld hl,(NativeSampleSource)
 ld a,(NativeSampleByte)
 cp 1
 jp z,MagnetSampleCenterRead
 jp NativeSampleCenterStride
