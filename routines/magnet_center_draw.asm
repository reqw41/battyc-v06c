; Colour only the middle eight columns/rows of the original picture.
; All pixels of the ring and lettering outside that square stay unchanged.
; Reserved free RAM after PreparedRow; no VRAM or quasi-disk scratch.
MagnetCenterDest EQU $71e9
MagnetCenterSource EQU $71eb
MagnetCenterOff EQU $71ed
NativeSampleAccentA EQU $71ee
NativeSampleAccentE EQU $71ef
MagnetCenterSourceEntry:
 call MagnetCenterSelectSource
 jp MagnetCenterSetup
MagnetCenterRow:
 push bc
 push hl
 call MagnetCenterReadShift
 pop hl
 call MagnetCenterPut
 inc h
 ld a,c
 call MagnetCenterPut
 dec h
 dec l
 pop bc
 dec b
 jp nz,MagnetCenterRow
 ret
