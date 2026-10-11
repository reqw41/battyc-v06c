SUWindowSave:
 xor a
 ld (UiActive),a
 call MonoRemove
 call MonoWindowSetup
 call MonoWindowCopySave
 ld a,1
 ld (SUWindowValid),a
 ret
SUWindowRestore:
 ld a,(SUWindowValid)
 or a
 ret z
 call MonoWindowSetup
 call MonoWindowCopyRestore
 xor a
 ld (SUWindowValid),a
 ld (OverlayActive),a
 jp SpriteCacheReset
MonoWindowSetup:
 ld hl,$8158
 call screen_addr_calc
 ld a,h
 sub $40
 ld h,a
 ld (MonoDrawVideo),hl
 ld hl,$7a00
 ld (MonoDrawSource),hl
 ret
MonoWindowCopySave:
 ld a,0
 ld (mono_window_mode+1),a
 jp MonoWindowCopy
MonoWindowCopyRestore:
 ld a,1
 ld (mono_window_mode+1),a
MonoWindowCopy:
 ld hl,(MonoDrawSource)
 ex de,hl
 ld hl,(MonoDrawVideo)
 ld b,10
mono_window_col:
 ld c,40
mono_window_row:
mono_window_mode:
 ld a,0
 or a
 jp nz,mono_window_restore
 ld a,(hl)
 ld (de),a
 xor a
 ld (hl),a
 jp mono_window_next
mono_window_restore:
 ld a,(de)
 ld (hl),a
mono_window_next:
 inc de
 dec l
 dec c
 jp nz,mono_window_row
 ld a,l
 add a,40
 ld l,a
 inc h
 dec b
 jp nz,mono_window_col
 ret
