SpriteCacheReset:
 ld hl,MonoOnlyTags
 ld b,4
 xor a
mcr_zero:
 ld (hl),a
 inc hl
 dec b
 jp nz,mcr_zero
 ret
