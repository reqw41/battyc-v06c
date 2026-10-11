PaceAccountOld:
 ld hl,(PaceWork)
 ld de,12 ; 768 cycles of old-owner descriptor/control
 add hl,de
 ld (PaceWork),hl
 ret
PaceReset:
 ld hl,0
 ld (PaceWork),hl
 jp MonoResetBody
