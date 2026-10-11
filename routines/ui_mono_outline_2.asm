UiMonoOutlineTail:
 call UiOutlineByte
 inc l
 ld a,c
 and $80
 rlca
 ld b,a
 dec h
 call UiOutlineByte
 inc h
 inc h
 ld a,c
 and 1
 rrca
 ld b,a
 call UiOutlineByte
 ld a,1
 ld (OverlayActive),a
 pop de
 pop bc
 pop hl
 pop af
 ret
