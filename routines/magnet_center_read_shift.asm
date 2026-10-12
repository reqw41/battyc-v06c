MagnetCenterReadShift:
 ld hl,(MagnetCenterSource)
 ld a,(hl)
 inc hl
 inc hl
 ld (MagnetCenterSource),hl
 jp NativeSampleShift
