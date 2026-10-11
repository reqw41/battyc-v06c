MonoCacheAddress:
 ld a,(MonoOwner)
 add a,a
 ld hl,MonoSlots
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 ld (SpriteCacheBuffer),hl
 ret
