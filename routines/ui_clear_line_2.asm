ClearOutlinedLinePixels:
 ld a,h
 sub $40
 ld h,a
 dec h
 ld a,l
 add a,6
 ld l,a
 ld (ClearDst),hl
 call FastErasePlain
 pop de
 pop bc
 pop hl
 ret
