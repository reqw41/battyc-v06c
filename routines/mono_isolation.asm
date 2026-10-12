; Conservative fast path: the union of this owner's old/new footprint must
; be disjoint from every other owner's union. No saved background required.
MonoFindIsolated:
 xor a
 ld (MonoActiveCount),a
 ld hl,MonoActiveRegions
 ld (MonoActivePtr),hl
 ld hl,MonoRegions
 ld (MonoRegionPtr),hl
 ld hl,(mono_new_base+1)
 ld (MonoPtr),hl
 ld hl,(mono_old_base+1)
 ld (MonoOldPtr),hl
 ld a,11
 ld (MonoBuildCount),a
mfi_build:
 ld hl,(MonoRegionPtr)
 ld (hl),$ff
 inc hl
 ld (hl),0
 inc hl
 ld (hl),0
 inc hl
 ld (hl),$ff
 inc hl
 ld (hl),1
 ld hl,(MonoPtr)
 call MonoIncludeRegion
 ld hl,(MonoOldPtr)
 call MonoIncludeRegion
 ld hl,(MonoRegionPtr)
 inc hl
 ld a,(hl)
 or a
 jp z,mfi_next
 ; Align vertical bounds to the eight-row dirty tiles. Classification
 ; includes this expansion so a cleared tile cannot erase an isolated owner.
 inc hl
 ld a,(hl)
 or 7
 ld (hl),a
 inc hl
 ld a,(hl)
 and $f8
 ld (hl),a
 ld hl,(MonoRegionPtr)
 ex de,hl
 ld hl,(MonoActivePtr)
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld (MonoActivePtr),hl
 ld hl,MonoActiveCount
 inc (hl)
mfi_next:
 ld a,(MonoPtr)
 add a,7
 ld (MonoPtr),a
 ld a,(MonoOldPtr)
 add a,7
 ld (MonoOldPtr),a
 ld a,(MonoRegionPtr)
 add a,5
 ld (MonoRegionPtr),a
 ld hl,MonoBuildCount
 dec (hl)
 jp nz,mfi_build
 ld a,(MonoActiveCount)
 dec a
 ret z
 ret m
 ld (MonoOuterCount),a
 ld hl,MonoActiveRegions
 ld (MonoActivePtr),hl
mfi_outer:
 ld hl,(MonoActivePtr)
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld (MonoPairPtr),hl
 ld (MonoActivePtr),hl
 ex de,hl
 ld (MonoPairOuter),hl
 ld a,(MonoOuterCount)
 ld (MonoPairCount),a
mfi_pair:
 ld hl,(MonoPairPtr)
 ld e,(hl)
 inc hl
 ld d,(hl)
 inc hl
 ld (MonoPairPtr),hl
 ld hl,(MonoPairOuter)
 call MonoRegionsIntersect
 or a
 jp z,mfi_pair_next
 inc de
 xor a
 ld (de),a
 ld hl,(MonoPairOuter)
 ld de,4
 add hl,de
 ld (hl),0
mfi_pair_next:
 ld hl,MonoPairCount
 dec (hl)
 jp nz,mfi_pair
 ld hl,MonoOuterCount
 dec (hl)
 jp nz,mfi_outer
 ret

; Old columns that remain inside the new rectangle are already final.
; Clear just the top/bottom fringes, or the whole retiring column.
MonoEraseFringes:
 ; Identical old/new geometry has no retiring pixels.
 ld hl,(MonoOldPtr)
 ex de,hl
 ld hl,(MonoPtr)
 ld b,4
mef_same:
 ld a,(de)
 cp (hl)
 jp nz,mef_changed
 inc de
 inc hl
 dec b
 jp nz,mef_same
 ret
mef_changed:
 ld hl,(MonoPtr)
 ld a,(hl)
 ld (MonoNewTop),a
 inc hl
 ld a,(hl)
 ld (mono_fringe_left+1),a
 inc hl
 ld b,(hl)
 add a,b
 ld (MonoNewRight),a
 inc hl
 ld a,(MonoNewTop)
 sub (hl)
 inc a
 ld (MonoSpanBottom),a
 ld a,(MonoTop)
 ld b,a
 ld a,(MonoRows)
 ld c,a
 ld a,b
 sub c
 inc a
 ld (MonoOldBottom),a
 ; A zero new width retires the old object; ignore its stale coordinates.
 ld hl,(MonoPtr)
 inc hl
 inc hl
 ld a,(hl)
 or a
 jp nz,mef_column
 ld (MonoNewRight),a
mef_column:
 ld a,(MonoColumn)
mono_fringe_left:
 cp 0
 jp c,mef_zero
 ld b,a
 ld a,(MonoNewRight)
 cp b
 jp c,mef_zero
 jp z,mef_zero
 ld a,(MonoTop)
 ld b,a
 ld a,(MonoNewTop)
 cp b
 jp nc,mef_bottom
 ld c,a
 ld a,b
 sub c
 ld b,a
 ld a,(MonoRows)
 cp b
 jp c,mef_zero
 ld a,(MonoColumn)
 ld h,a
 ld a,(MonoTop)
 ld l,a
 call MonoZeroRange
mef_bottom:
 ld a,(MonoOldBottom)
 ld b,a
 ld a,(MonoSpanBottom)
 sub b
 jp c,mef_next
 jp z,mef_next
 ld b,a
 ld a,(MonoRows)
 cp b
 jp c,mef_zero
 ld a,(MonoSpanBottom)
 dec a
 ld l,a
 ld a,(MonoColumn)
 ld h,a
 call MonoZeroRange
 jp mef_next
mef_zero:
 call MonoZeroColumn
mef_next:
 ld hl,MonoColumn
 inc (hl)
 ld hl,MonoCols
 dec (hl)
 jp nz,mef_column
 ret
