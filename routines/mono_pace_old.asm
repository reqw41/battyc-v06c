PaceAccountOld:
 ld hl,(PaceWork)
 ld de,4 ; 256 cycles of old-owner descriptor/control
 add hl,de
 ld (PaceWork),hl
 ret
PaceReset:
 ld hl,0
 ld (PaceWork),hl
 jp MonoResetBody
