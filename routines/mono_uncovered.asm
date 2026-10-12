; Eight-row dirty bitmap is the active deduplication method.
; Retired interval labels remain only for old profiling tools.
MonoDoneBottom EQU $7f00 ; unused twelfth cache slot; eleven live owners
MonoOriginalTop EQU $7f20
MonoOriginalBottom EQU $7f21
MonoOriginalRows EQU $7f22
MonoCachedTop EQU $7f23
MonoCachedBottom EQU $7f24
MonoDirtyBitmap EQU $7f80 ; 32 columns x 32 eight-row tiles = 128 bytes
MonoDirtyMasks: db 1,2,4,8,16,32,64,128
MonoCommitColumn EQU RCBegin
MonoAccountComposition EQU RCBegin

MonoActiveDescs EQU $7f40
MonoActiveDescPtr EQU $7f56
MonoActiveDescCount EQU $7f58
MonoSelectedDesc EQU $7f5a
MonoErasePass EQU $7f5c ; reserved
MonoRectangleTop EQU $7f5d
MonoRectangleRows EQU $7f5e
MonoRemainingRows EQU $7f5f
MonoSelectCandidates:
 ret
; Clear the shared sprite-plane dirt once, then draw every intersecting
; current descriptor once. RGB backgrounds never participate.
MonoClearColumn:
 ld hl,0
 add hl,sp
 ld (mono_clear_sp+1),hl
 ld a,(MonoColumn)
 ld h,a
 ld a,(MonoTop)
 ld l,a
 inc l
 ld a,(MonoRows)
 ld b,a
 ld de,0
 di
 ld sp,hl
 rra
 jp nc,mono_clear_pairs
 dec sp
 dec b
 dec l
 xor a
 ld (hl),a
mono_clear_pairs:
 ld a,b
 or a
 jp z,mono_clear_sp
 rra
 ld b,a
mono_clear_pair:
 push de
 dec b
 jp nz,mono_clear_pair
mono_clear_sp:
 ld sp,0
 ei
 ret
