; Small restoration helpers in the reclaimed cache tail.
NativeBrickPresent:
 ld a,h
 cp 32
 jp c,NativeBrickAbsent
 cp 128
 jp nc,NativeBrickAbsent
 ld a,l
 cp 8
 jp c,NativeBrickAbsent
 cp 248
 jp nc,NativeBrickAbsent
 ld a,(de)
 or a
 jp m,NativeBrickAbsent
 ld a,$ff
 ret
NativeBrickAbsent:
 xor a
 ret

NativeSampleShift:
 ld b,a
 ld a,(NativeShift)
 or a
 ld a,b
 jp nz,NativeRotateByte
 ld c,0
 ret

NativeRestoreMagnetSample:
 push bc
 push de
 push hl
 ld (NativeSampleValue),a
 ld a,d
 sub $c0
 ld (NativeSampleColumn),a
 ld a,$e0
 sub e
 ld (NativeSampleY),a
 ld a,(magnets_quantity)
 ld (NativeSampleCount),a
 ld hl,magnet_properties
 ld (NativeSampleProp),hl
 ld hl,NativeMagnetOverlayFlags
 ld (NativeSampleFlag),hl
 jp NativeSampleNextMagnet
NativeMagnetOverlayFlags: db 0,0,0,0
NativeSampleValue: db 0
NativeSampleColumn: db 0
NativeSampleY: db 0
NativeSampleCount: db 0
NativeSampleProp: dw 0
NativeSampleFlag: dw 0
NativeSampleX: db 0
NativeSampleOriginY: db 0
NativeSampleSprite: dw 0
NativeSampleHeight: db 0
NativeSampleRow: db 0
NativeSampleByte: db 0
NativeSampleWidth: db 0
NativeSampleSource: dw 0
NativeSampleMask: db 0
NativeSamplePixel: db 0

NativeRestoreClipTable: db $80,0,$ff,$ff,0,1
