; Exactly two choices, with pointer rows matching the two centred labels.
MenuControlPointerRow:
 and 1
 ld a,$82
 ret z
 ld a,$9a
 ret
NormalizeMenuControls:
 ld a,(ctrl_type_1up)
 and 1
 ld (ctrl_type_1up),a
 call MenuControlPointerRow
 ld (coord_ctrl_1up+1),a
 ld a,(ctrl_type_2up)
 and 1
 ld (ctrl_type_2up),a
 call MenuControlPointerRow
 ld (coord_ctrl_2up+1),a
 ret
