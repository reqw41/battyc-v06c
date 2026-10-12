UiStencilPass EQU $71e6
 ASSERT UiStencilPass == MonoPairActive+1
 ASSERT UiStencilPass < PreparedCover
; All text uses the same solid menu glyphs; gameplay writes white only.
PrintOutlinedLine:
 jp PrintLineBody

 INCLUDE "routines/ball_shift_rows.asm"
