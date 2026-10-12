; Compose the stationary magnet and its current animated layer over one texture byte.
NativeSampleNextMagnet:
 ld hl,(NativeSampleProp)
 inc hl
 inc hl
 ld a,(hl)
 sub 5
 ld (NativeSampleX),a
 inc hl
 inc hl
 ld a,(hl)
 sub 5
 ld (NativeSampleOriginY),a
 ld hl,spr_magnet_circle_on
 ld (NativeSampleSprite),hl
 ld a,30
 ld (NativeSampleHeight),a
 call NativeSampleMagnetLayer
 ld hl,(NativeSampleFlag)
 ld a,(hl)
 or a
 jp z,NativeSampleAdvanceMagnet
 ld hl,(NativeSampleProp)
 inc hl
 ld a,(hl)
 ld hl,spr_magnet_circle_on
 cp 6
 jp z,NativeSampleAnimatedSource
 ld hl,spr_magnet_circle_off
NativeSampleAnimatedSource:
 ld (NativeSampleSprite),hl
 ld a,23
 ld (NativeSampleHeight),a
 call NativeSampleMagnetLayer
NativeSampleAdvanceMagnet:
 ld hl,(NativeSampleProp)
 ld de,16
 add hl,de
 ld (NativeSampleProp),hl
 ld hl,(NativeSampleFlag)
 inc hl
 ld (NativeSampleFlag),hl
 ld hl,NativeSampleCount
 dec (hl)
 jp nz,NativeSampleNextMagnet
 pop hl
 pop de
 pop bc
 ld a,(NativeSampleValue)
 ret

NativeSampleMagnetLayer:
 ld a,(NativeSampleOriginY)
 ld b,a
 ld a,(NativeSampleY)
 sub b
 ret c
 ld b,a
 ld a,(NativeSampleHeight)
 cp b
 ret z
 ret c
 ld a,b
 ld (NativeSampleRow),a
 ld a,(NativeSampleX)
 ld b,a
 and 7
 ld (NativeShift),a
 ld a,b
 rrca
 rrca
 rrca
 and 31
 ld b,a
 ld a,(NativeSampleColumn)
 sub b
 ret c
 ld (NativeSampleByte),a
 ld hl,(NativeSampleSprite)
 ld a,(hl)
 ld (NativeSampleWidth),a
 ld b,a
 ld a,(NativeSampleByte)
 inc b
 cp b
 ret nc
NativeSampleLocate:
 ld a,(NativeSampleWidth)
 cp 4
 ld de,46
 jp nz,NativeSampleStrideReady
 ld de,60
NativeSampleStrideReady:
 ex de,hl
 ld (NativeSamplePreviousStride+1),hl
 ld (NativeSampleCenterStride+1),hl
 ex de,hl
 ld hl,(NativeSampleSprite)
 inc hl
 inc hl
 ld a,(NativeSampleByte)
 or a
 jp z,NativeSampleRowOffset
 ld b,a
NativeSampleColumnOffset:
 add hl,de
 dec b
 jp nz,NativeSampleColumnOffset
NativeSampleRowOffset:
 ld a,(NativeSampleRow)
 add a,a
 call hl_add_a
 ld (NativeSampleSource),hl
 ; Current source byte and the previous byte's shifted carry.
 ld a,(NativeSampleWidth)
 ld b,a
 ld a,(NativeSampleByte)
 cp b
 ld a,0
 jp z,NativeSampleCurrentMask
 ld a,(hl)
 cpl
NativeSampleCurrentMask:
 call NativeSampleShift
 ld (NativeSampleMask),a
 ld hl,(NativeSampleSource)
 inc hl
 ld a,(NativeSampleWidth)
 ld b,a
 ld a,(NativeSampleByte)
 cp b
 ld a,0
 jp z,NativeSampleCurrentPixel
 ld a,(hl)
NativeSampleCurrentPixel:
 call NativeSampleShift
 ld (NativeSamplePixel),a
 ld a,(NativeSampleByte)
 or a
 jp z,NativeSampleMerge
 ld hl,(NativeSampleSource)
NativeSamplePreviousStride:
 ld de,0
 ld a,l
 sub e
 ld l,a
 ld a,h
 sbc a,d
 ld h,a
 ld a,(hl)
 cpl
 call NativeSampleShift
 ld a,(NativeSampleMask)
 or c
 ld (NativeSampleMask),a
 inc hl
 ld a,(hl)
 call NativeSampleShift
 ld a,(NativeSamplePixel)
 or c
 ld (NativeSamplePixel),a
NativeSampleMerge:
 call MagnetSampleAccent
 ld a,(NativeSampleMask)
 cpl
 ld b,a
 ld a,(NativeSampleValue)
 and b
 ld b,a
 ld a,(NativeSamplePixel)
 or b
 ld (NativeSampleValue),a
 ret
