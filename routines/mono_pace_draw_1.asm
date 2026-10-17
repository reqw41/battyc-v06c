; Add the clock time since the previous read to PaceRepeat, in whole rasters.
; Read after every logic step and before every draw, so that reads are never
; 43.7 ms apart (one wrap of the counter). Returns HL=PaceRepeat.
PaceUpdate:
 ld a,$80 ; latch channel 2
 out ($08),a
 in a,($09) ; low byte, unused
 in a,($09)
 ld b,a
ps_prev:
 ld c,0 ; high byte at the previous read
 ld (ps_prev+1),a
 ld a,c
 sub b ; elapsed, in 256-count units
 ld hl,PaceRepeat
ps_acc:
 add a,0 ; plus the part of a raster carried over
 jp nc,ps_count
 add a,256-2*117
 inc (hl)
 inc (hl)
 jp ps_count
 DS 11,0 ; free, keeps the sprite pads at their old addresses
