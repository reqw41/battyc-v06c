; Session lock: only F1+F3 enables cheats. Active-low keyboard rows come from IRQ.
CheatEnabled EQU $71f0
CheatKeys EQU $71f1
CheatMenuKeys:
 ld a,(KeyLine1)
 and $28
 jp z,CheatStartEnabled
 ld a,(KeyLine2)
 rrca
 jp c,JoystickMenuStart
CheatStartNormal:
 xor a
 ld (CheatEnabled),a
 jp CheatStartReset
CheatStartEnabled:
 ld a,1
 ld (CheatEnabled),a
CheatStartReset:
 ld a,$3d ; DEC A at the life-loss site; G toggles it with OR A ($b7).
 ld (live_dec),a
 xor a
 ld (CheatKeys),a
 ret
CheatPoll:
 ld a,(CheatEnabled)
 or a
 ret z
 ld a,(KeyLine4)
 cpl
 rlca
 and 1
 ld b,a
 ld a,(KeyLine5)
 cpl
 and $10
 or b
 ld b,a
 ld a,(CheatKeys)
 cpl
 and b
 ld c,a
 ld a,b
 ld (CheatKeys),a
 ld a,c
 and 1
 jp z,CheatNoGodEdge
 ld a,(live_dec)
 xor $8a
 ld (live_dec),a
CheatNoGodEdge:
 ld a,c
 and $10
 ret z
 scf
 ret

SoloJoystick2: db 0
; Fire starts a normal game and selects the firing device's control column.
JoystickMenuStart:
 ld a,(JoystickP)
 cpl
 and $c0
 jp z,JoystickMenuSecond
 ld a,1
 ld (ctrl_type_1up),a
 xor a
 ld (SoloJoystick2),a
 jp CheatStartNormal
JoystickMenuSecond:
 ld a,(JoystickP2)
 cpl
 and $c0
 jp z,L93F8_0
 ld a,1
 ld (SoloJoystick2),a
 ld (ctrl_type_2up),a
 ld a,(game_mode)
 or a
 jp nz,CheatStartNormal
 ld a,1
 ld (ctrl_type_1up),a
 jp CheatStartNormal
