; Draw cadence by load. A draw that does not fit a raster together with its
; logic step makes the game alternate one and two steps per draw, and objects
; move unevenly. Then every draw takes exactly two logic steps and two
; rasters; back to one step once a step and a draw fit a raster again.
; The cost is read on the clock from the mark taken when the last logic step
; began (117 per raster; the costliest scene takes about 205). The one-ball
; game waits inside the renderer and keeps one step per draw.
PaceSlowFrom EQU 130 ; above the 123..146 band of two balls, bonus and enemy
PaceFastBelow EQU 117
PaceTail:
 call PaceUpdate ; uses BC
 ld c,1
 ld a,(balls_quantity)
 dec a
 jp z,pt_set
 ld a,(ps_prev+1)
 ld b,a
pt_mark:
 ld a,0 ; clock high byte when the last logic step began
 sub b
 inc c
 cp PaceSlowFrom
 jp nc,pt_set
 dec c
 cp PaceFastBelow
 jp nc,pt_wait
pt_set:
 ld a,c
 ld (pw_steps+1),a
pt_wait:
 call WaitGameplayFrame
PaceMark:
 ld a,(ps_prev+1) ; the next logic step begins now
 ld (pt_mark+1),a
 jp LB9E8_2
