; Z means the enabled picture. Native column pitch is fixed in either state.
MagnetCenterSelectSource:
 ld hl,spr_magnet_circle_on+79
 jp z,MagnetCenterSourceReady
 ld hl,spr_magnet_circle_off+65
MagnetCenterSourceReady:
 ld (MagnetCenterSource),hl
 ret
