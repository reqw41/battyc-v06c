; Consume old compact footprints separately from the new compact list.
; A retiring object consumes an old slot but does not allocate a new slot.
SparksLocalRender:
 ld hl,plane_old
 ld (plane_slot),hl
 ld (sl_old+1),hl
 call ClearShapeFlags
 ld hl,SparksEraseDraw
 jp call_hl_for_all_obj
SparksEraseDraw:
sl_old:
 ld hl,plane_old
 ld d,(hl)
 inc hl
 ld e,(hl)
 inc hl
 ld b,(hl)
 ld (hl),0
 inc hl
 ld c,(hl)
 inc hl
 ld (sl_old+1),hl
 ld a,b
 or a
 call nz,plane_erase_dual
 jp plane_object
