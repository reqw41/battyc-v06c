mcb_build:
 ld (MonoOwner),a
 ld hl,MonoShifts
 call hl_add_a
 ld a,(hl)
 ld (SpriteCacheShift),a
 ld a,10
 ld (SpriteCacheHeight),a
 ld hl,(mono_new_base+1)
 ld a,(MonoOwner)
 cp 8
 ld de,53
 jp nz,mcb_source
 ld de,60
mcb_source:
 add hl,de
 ld e,(hl)
 inc hl
 ld d,(hl)
 ex de,hl
 dec hl
 dec hl
 ld (SpriteCacheOriginal),hl
 call MonoCacheAddress
 jp SpriteCacheBuild
