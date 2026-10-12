brq_full:
 ld hl,QueueOverflow
 inc (hl)
 jp NativeRestoreBrick ; never lose a repair when the queue is full

brq_return:
 xor a
 ld (QueueMode),a
 ld (QueueInStep),a
 pop hl
 ld (cur_level_ptr),hl
 ret

NativeRestoreQueueFlush:
 ld a,(wins_counter)
 or a
 ret z
 call NativeRestoreQueueStep
 jp NativeRestoreQueueFlush
NativeRestoreQueueFresh:
 push hl
 ld hl,QueueFresh
 inc (hl)
 pop hl
 ret
brq_level_index:
 ld a,(wins_recovery_data+2)
 ld hl,(current_level_addr)
 jp hl_add_a
brq_advance:
 ld hl,wins_recovery_data
 inc (hl)
 ld a,(QueueMode)
 cp 5
 jp nz,brq_return
 inc (hl) ; the no-magnet grouped step restores two columns
 jp brq_return
