; No save-under. Use local erase/draw only when all footprints are separate.
SparksRender:
 xor a
 ld (SparksUnsafe),a
 ld hl,SparksClassify
 call call_hl_for_all_obj
 ld a,(SparksUnsafe)
 or a
 jp z,SparksLocalRender
 call planes_begin
 ld hl,print_obj_from_buf_to_scr
 jp call_hl_for_all_obj
SparksUnsafe: db 0
