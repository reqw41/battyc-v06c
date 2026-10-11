MonoZeroColumn:
 ld a,(MonoColumn)
 ld h,a
 ld a,(MonoTop)
 ld l,a
 ld a,(MonoRows)
 ld b,a
 jp MonoZeroRange
