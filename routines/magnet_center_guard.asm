; Native kind 3 is a separator (5) or a magnet (6/7); HUD is dispatched earlier.
MagnetCenterDraw:
 ld hl,(IXobj)
 inc hl
 ld a,(hl)
 cp 6
 ret c
 sub 6
 ld (MagnetCenterOff),a
 jp MagnetCenterSourceEntry
