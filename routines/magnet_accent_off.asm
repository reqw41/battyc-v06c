MagnetAccentOff:
 ld a,(NativeSampleSprite)
 cp spr_magnet_circle_off%256
 ret nz
 ld a,(NativeSampleAccentE)
 or b
 ld (NativeSampleAccentE),a
 ret
