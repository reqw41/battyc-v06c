; SP fill goes down from FFFF. The first four 2K blocks are E-plane paper.
; All remaining A/C/overlay bytes must be zero, including in coloured menus.
PaperPlaneNextBlock:
 ld a,c
 cp 13
 jp nz,PaperPlaneKeepFill
 ld de,0
PaperPlaneKeepFill:
 dec c
 jp nz,pr_fill
 jp pr_restore

 INCLUDE "routines/magnet_accent_reset.asm"
