; Same reverse-order save-under renderer also handles crossing sparks.
SparksRender:
 call planes_begin
 ld hl,print_obj_from_buf_to_scr
 jp call_hl_for_all_obj
SparksUnsafe: db 0
