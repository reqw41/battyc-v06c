; Small restoration helpers in the reclaimed cache tail.
 INCLUDE "routines/restore_brick_magnet_filter.asm"

NativeSampleShift:
 ld b,a
 ld a,(NativeShift)
 or a
 ld a,b
 jp nz,NativeRotateByte
 ld c,0
 ret

NativeMagnetOverlayFlags:
MagnetRedrawFlags: db 0,0,0,0 ; magnets touched by the current brick restore
NativeRestoreMagnetCount: db 0
NativeRestoreBoundLeft: db 0
NativeRestoreBoundRight: db 0
NativeRestoreBoundTop: db 0
NativeRestoreBoundBottom: db 0
