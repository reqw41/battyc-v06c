; Common A/C/E framebuffer. Index 0 black, 1 enemy, 7 white.
; Prepared E/F pairs are a source encoding only, never separate video layers.
plane_object:
 xor a
 ld (PreparedFlag),a
 ld (color_valid),a
 ld (color_enemy),a
 ld hl,(IXobj)
 ld a,(hl)
 and $7f
 cp 8
 jp c,tp_kind_ready
 cp 11
 jp nc,tp_kind_ready
 ld a,1
 ld (color_enemy),a
tp_kind_ready:
 call plane_object_fast
 ld a,(color_valid)
 or a
 ret z
 call SpriteCachePrepare
 ld a,(SUStatic)
 or a
 jp nz,PreparedDraw
 call SUSaveObject
 ld a,(SUNoRoom)
 or a
 ret nz
 jp PreparedDraw
color_valid: db 0
color_enemy: db 0
color_height: db 0
color_white_limit: db 0

WarmStart:
 ld sp,stack
 jp game_start
