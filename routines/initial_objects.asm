; Restore 242 bytes from an immutable snapshot, outside the hot game loop.
InitialObjectsRestore:
 ld hl,InitialObjectsData
 ld de,object_ball_1
 ld a,11
 ld (ior_records+1),a
ior_record:
 ld b,(hl)
 inc hl
 ld c,(hl)
 inc hl
 ld a,(hl)
 inc hl
 push af
 push bc
 ld c,8
 call ior_bytes
 pop bc
 ld b,c
 ld c,8
 call ior_bytes
 pop af
 ld b,a
 ld c,6
 call ior_bytes
ior_records:
 ld a,11
 dec a
 ld (ior_records+1),a
 jp nz,ior_record
 ret
ior_bytes:
 ld a,b
 rrca
 ld b,a
 ld a,0
 jp nc,ior_zero
 ld a,(hl)
 inc hl
ior_zero:
 ld (de),a
 inc de
 dec c
 jp nz,ior_bytes
 ret
