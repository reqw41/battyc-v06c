QueueOverflow: db 0
QueueInStep: db 0
; Heavy play defers RGB brick repair; ball collision/score/SFX remain immediate.
; Ten FIFO records: X (low two bits are the column phase), Y, level index.
; An idle no-magnet job finishes in one pass; busy jobs restore one column.
NativeRestoreQueued:
 call NativeRestoreQueueFresh
 ld a,(wins_counter)
 cp 10
 jp nc,brq_full
 ld b,a
 add a,a
 add a,b
 call brq_get_slot
 jp brq_enqueue_store
NativeRestoreQueueStep:
 ld a,(wins_counter)
 or a
 ret z
 ld a,1
 ld (QueueInStep),a
 ld hl,(cur_level_ptr)
 push hl
 ld hl,(wins_recovery_data)
 ld a,l
 and 3
 inc a
 ld (QueueMode),a
 ld a,l
 and $fc
 ld l,a
 ld (LB28F+1),hl
 ld a,l
 rrca
 rrca
 rrca
 and 31
 or $c0
 ld b,a
 ld a,(QueueMode)
 add a,b
 dec a
 dec a
 ld (QueueCut),a
 call brq_level_index
 ld (cur_level_ptr),hl
 call NativeRestoreBrick
 ld a,(QueueMode)
 and 3
 jp z,brq_pop
 jp brq_advance

; Whole no-magnet repair fits a busy frame only when at least two neighbor
; cells are still present. Otherwise defer the second pair of columns.
NativeRestoreQueueSparseGate:
 ld a,(QueueInStep)
 or a
 ret z
 ld a,(QueueMode)
 or a
 ret nz
 ld a,(QueueFresh)
 or a
 ret z
 ld hl,NativeRestoreGrid+1
 ld a,(hl)
 inc hl
 inc hl
 add a,(hl)
 inc hl
 inc hl
 add a,(hl)
 inc hl
 inc hl
 add a,(hl)
 or a
 jp z,brq_sparse_group
 cp $ff
 ret nz
brq_sparse_group:
 ld a,(wins_recovery_data)
 and 3
 cp 2
 ld a,8
 jp nc,brq_sparse_store
 ld a,5
brq_sparse_store:
 ld (QueueMode),a
 ret
