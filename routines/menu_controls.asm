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
