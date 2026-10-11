SpriteCacheReset:
 ld hl,MonoTags
 ld b,48
 xor a
mcr_zero:
 ld (hl),a
 inc hl
 dec b
 jp nz,mcr_zero
 ret
