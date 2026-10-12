brq_enqueue_store:
 push hl
 ld hl,(LB28F+1)
 ex de,hl
 pop hl
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 push hl
 ld hl,(cur_level_ptr)
 ld a,l
 ld hl,(current_level_addr)
 sub l
 pop hl
 ld (hl),a
 ld hl,wins_counter
 inc (hl)
 ret
brq_pop:
 ld hl,wins_counter
 dec (hl)
 ld a,(hl)
 ld b,a
 add a,a
 add a,b
 or a
 jp z,brq_return
 ld c,a
 ld b,0
 ld hl,wins_recovery_data+3
 ld de,wins_recovery_data
 call LDIR8080B
 jp brq_return
