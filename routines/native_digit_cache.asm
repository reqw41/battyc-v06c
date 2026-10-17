; Only the fixed HUD row is cached. Other score/menu rows always draw.
NativeDigitCache EQU MonoRegions ; obsolete isolation workspace, initialized by reset
NativeDigitInvalidate:
 ld hl,NativeDigitCache
 ld b,32
 ld a,$ff
ndc_reset:
 ld (hl),a
 inc hl
 dec b
 jp nz,ndc_reset
 ret
NativeDigitCheck:
 push af
 ld hl,(score_screen_ptr)
 ld a,l
 cp $f0
 jp nz,ndc_always
 ld a,h
 sub $70
 ld hl,NativeDigitCache
 call hl_add_a
 pop af
 cp (hl)
 jp z,ndc_same
 ld (hl),a
 jp NativePrintDigitDraw
ndc_always:
 pop af
 jp NativePrintDigitDraw
ndc_same:
 ld hl,(score_screen_ptr)
 inc h
 ld (score_screen_ptr),hl
 ret

