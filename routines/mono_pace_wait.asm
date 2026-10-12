; Raster IRQs masked by SP may have passed without advancing IntCount.
; Skip HALT only if the previous native render already exceeded one raster.
WaitGameplaySlow:
 ld hl,(PaceWork)
 ld de,-936 ; 59904 synchronized cycles, one raster
 add hl,de
 ld hl,0
 ld (PaceWork),hl
 jp nc,WaitVideoFrame
 ei
 ld a,(IntCount)
 jp wvf_ready
