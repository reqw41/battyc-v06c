; Round-window backup: 1600 bytes at 7a00..7fff plus 7100..713f.
; Objects are removed first; cache tags are invalidated on restoration.
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
MonoWindowCopySave:
 ld a,0
 ld (mono_window_mode+1),a
 jp MonoWindowCopy
MonoWindowCopyRestore:
 ld a,1
 ld (mono_window_mode+1),a
MonoWindowCopy:
 ld a,4
 ld (NativeLeft),a
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
 call MonoWindowSaveByte
 jp mono_window_next
mono_window_restore:
 ld a,(de)
 ld (hl),a
mono_window_next:
 inc de
 ld a,d
 cp $80
 jp nz,mono_window_buffer_ready
 ld de,$7100
mono_window_buffer_ready:
 dec l
 dec c
 jp nz,mono_window_row
 ld a,l
 add a,40
 ld l,a
 inc h
 dec b
 jp nz,mono_window_col
 ld a,h
 add a,$16
 ld h,a
 ld a,(NativeLeft)
 dec a
 ld (NativeLeft),a
 ld b,10
 jp nz,mono_window_col
 ret
