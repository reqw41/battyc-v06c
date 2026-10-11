; Bonus icon shares the full rocket source, but clips away its flame.
MonoBonusHeight:
 push hl
 ld hl,(IXobj)
 ld a,(hl)
 cp 4
 jp nz,mbh_done
 inc hl
 ld a,(hl)
 cp 6
 jp nz,mbh_done
 ld b,12
mbh_done:
 pop hl
 ret
