; Save previous records by owner. New records live in the other owner bank.
CGPrepare:
 ld hl,CGOld
 ld b,66
 xor a
cgp_zero:
 ld (hl),a
 inc hl
 dec b
 jp nz,cgp_zero
 ld a,(CGFormat)
 or a
 jp nz,cgp_copy
 call SUInvalidate
 jp cgp_geometry
cgp_copy:
 ld a,(SUCount)
 or a
 jp z,cgp_geometry
 ld b,a
 ld hl,SURecords
 ld de,CGOwners
cgp_old:
 push bc
 push hl
 ld a,(de)
 inc de
 push de
 add a,a
 ld c,a
 add a,a
 add a,c
 ld hl,CGOld
 call hl_add_a
 ex de,hl
 pop bc
 pop hl
 push bc
 ld b,6
cgp_oldbytes:
 ld a,(hl)
 ld (de),a
 inc hl
 inc de
 dec b
 jp nz,cgp_oldbytes
 pop de
 pop bc
 dec b
 jp nz,cgp_old
cgp_geometry:
 xor a
 ld (CGFallback),a
 ld (CGActiveCount),a
 ld (SUCount),a
 ld hl,SURecords
 ld (SURecordNext),hl
 ld hl,0
 add hl,sp
 ld (cgp_clear_sp+1),hl
 di
 ld sp,CGDesc+132
 ld de,0
 ld b,11
cgp_clear_desc:
 DUP 6
 push de
 EDUP
 dec b
 jp nz,cgp_clear_desc
cgp_clear_sp:
 ld sp,0
 ei
 xor a
cgp_owner:
 call CGPointers
 xor a
 ld (color_valid),a
 ld (color_enemy),a
 ld hl,(IXobj)
 ld a,(hl)
 or a
 jp z,cgp_no_new
 and $7f
 cp 8
 jp c,cgp_kind
 cp 11
 jp nc,cgp_kind
 ld a,1
 ld (color_enemy),a
cgp_kind:
 call plane_object_fast
 ld a,(color_valid)
 or a
 jp z,cgp_no_new
 ld a,(direct_rows)
 inc a
 and $fe
 ld b,a
 ld a,(plane_dst)
 sub b
 inc a
 ld e,a
 ld a,(plane_dst+1)
 ld d,a
 ld hl,(CGDPtr)
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld a,(direct_columns)
 ld (hl),a
 inc hl
 ld (hl),b
 inc hl
 push hl
 ld a,(CGIndex)
 add a,a
 ld hl,CGSlots
 call hl_add_a
 ld e,(hl)
 inc hl
 ld d,(hl)
 ld hl,(CGOPtr)
 inc hl
 inc hl
 ld a,(hl)
 or a
 jp z,cgp_bank_ready
 inc hl
 inc hl
 inc hl
 ld a,(hl)
 cp $85
 jp nc,cgp_bank_ready
 ld a,d
 add a,5
 ld d,a
cgp_bank_ready:
 pop hl
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld a,(direct_source)
 ld (hl),a
 inc hl
 ld a,(direct_source+1)
 ld (hl),a
 inc hl
 ld a,(direct_shift)
 ld (hl),a
 inc hl
 ld a,(direct_width)
 ld (hl),a
 inc hl
 ld a,(direct_rows)
 ld (hl),a
 inc hl
 ld a,(color_enemy)
 ld (hl),a
 ; Asset maxima are proved by JS; unusual editor/test owner kinds fall back.
 ld a,(CGIndex)
 ld hl,CGCapacity
 call hl_add_a
 ld b,(hl)
 ld hl,(IXobj)
 ld a,(hl)
 and $7f
 ld hl,CGKindMax
 call hl_add_a
 ld a,(hl)
 cp b
 jp c,cgp_no_new
 jp z,cgp_no_new
 ld a,1
 ld (CGFallback),a
cgp_no_new:
 ld hl,(CGRectPtr)
 ld b,4
 xor a
cgp_rzero:
 ld (hl),a
 inc hl
 dec b
 jp nz,cgp_rzero
 ld hl,(CGOPtr)
 call CGIncludeRect
 ld hl,(CGDPtr)
 call CGIncludeRect
 ld hl,(CGRectPtr)
 inc hl
 ld a,(hl)
 or a
 jp z,cgp_inactive
 ld a,(CGActiveCount)
 ld hl,CGActive
 call hl_add_a
 ld a,(CGIndex)
 ld (hl),a
 ld a,(CGActiveCount)
 inc a
 ld (CGActiveCount),a
cgp_inactive:
 ld a,(CGIndex)
 ld hl,CGLabels
 call hl_add_a
 ld a,(CGIndex)
 ld (hl),a
 inc a
 cp 11
 jp c,cgp_owner
 ret
; Rect = column start/end, ascending video low start/end.
CGIncludeRect:
 ld c,(hl)
 inc hl
 ld a,(hl)
 sub $e0
 ld e,a
 inc hl
 ld a,(hl)
 or a
 ret z
 add a,e
 ld d,a
 inc hl
 ld a,(hl)
 add a,c
 ld b,a
 ld hl,(CGRectPtr)
 push hl
 inc hl
 ld a,(hl)
 or a
 pop hl
 jp nz,cgir_union
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 ld (hl),c
 inc hl
 ld (hl),b
 ret
cgir_union:
 ld a,e
 cp (hl)
 jp nc,cgir_x0
 ld (hl),a
cgir_x0:
 inc hl
 ld a,d
 cp (hl)
 jp c,cgir_x1
 ld (hl),a
cgir_x1:
 inc hl
 ld a,c
 cp (hl)
 jp nc,cgir_y0
 ld (hl),a
cgir_y0:
 inc hl
 ld a,b
 cp (hl)
 ret c
 ld (hl),a
 ret
; Pairwise rectangle intersections; union all labels in each connected group.
CGGroups:
 ld a,(CGActiveCount)
 cp 2
 jp c,cgg_sizes
 xor a
 ld (CGActiveI),a
cgg_i:
 ld a,(CGActiveI)
 ld hl,CGActive
 call hl_add_a
 ld a,(hl)
 ld (CGIndex),a
 add a,a
 add a,a
 add a,CGRect%256
 ld l,a
 ld h,CGRect/256
 ld (CGRectPtr),hl
 ld a,(CGActiveI)
 inc a
 ld (CGActiveJ),a
cgg_j:
 ld a,(CGActiveJ)
 ld b,a
 ld a,(CGActiveCount)
 cp b
 jp z,cgg_nexti
 ld a,b
 ld hl,CGActive
 call hl_add_a
 ld a,(hl)
 ld (CGTemp),a
 add a,a
 add a,a
 add a,CGRect%256
 ld e,a
 ld d,CGRect/256
 ld hl,(CGRectPtr)
 ld b,(hl)
 inc hl
 push hl
 ex de,hl
 inc hl
 ld a,(hl)
 cp b
 jp c,cgg_disjoint_pop
 jp z,cgg_disjoint_pop
 dec hl
 ld a,(hl)
 ex de,hl
 cp (hl)
 jp nc,cgg_disjoint_pop
 inc hl
 ld b,(hl)
 inc hl
 ex de,hl
 inc hl
 inc hl
 inc hl
 ld a,(hl)
 cp b
 jp c,cgg_disjoint_pop
 jp z,cgg_disjoint_pop
 dec hl
 ld a,(hl)
 ex de,hl
 cp (hl)
 jp nc,cgg_disjoint_pop
 pop hl
 ld a,(CGIndex)
 ld hl,CGLabels
 call hl_add_a
 ld b,(hl)
 ld a,(CGTemp)
 ld hl,CGLabels
 call hl_add_a
 ld a,(hl)
 cp b
 jp z,cgg_nextj
 ld c,a
 ld hl,CGLabels
 ld d,11
cgg_relabel:
 ld a,(hl)
 cp c
 jp nz,cgg_keep
 ld (hl),b
cgg_keep:
 inc hl
 dec d
 jp nz,cgg_relabel
 jp cgg_nextj
cgg_disjoint_pop:
 pop hl
cgg_nextj:
 ld a,(CGActiveJ)
 inc a
 ld (CGActiveJ),a
 jp cgg_j
cgg_nexti:
 ld a,(CGActiveI)
 inc a
 ld (CGActiveI),a
 inc a
 ld b,a
 ld a,(CGActiveCount)
 cp b
 jp nz,cgg_i
cgg_sizes:
 ld hl,CGSizes
 ld b,11
 xor a
cgg_zero_size:
 ld (hl),a
 inc hl
 dec b
 jp nz,cgg_zero_size
 ld a,(CGActiveCount)
 or a
 ret z
 ld b,a
 ld de,CGActive
cgg_count_size:
 ld a,(de)
 inc de
 ld hl,CGLabels
 call hl_add_a
 ld a,(hl)
 ld hl,CGSizes
 call hl_add_a
 inc (hl)
 dec b
 jp nz,cgg_count_size
 ret
CGKindMax: db 0,160,60,0,128,32,224,32,160,128,120,80
; Fixed owner ranges can cross a RAM page; all background increments are 16-bit.
; A words, HL source, DE destination; source-SP unrolled pair copy.
CGCopyPacked:
 push hl
 ld c,a
 add a,a
 add a,a
 add a,c
 ld c,a
 ld a,cgp_words_end%256
 sub c
 ld l,a
 ld a,cgp_words_end/256
 sbc a,0
 ld h,a
 ld (cgp_dispatch+1),hl
 pop hl
 ex de,hl
 ld (cgp_destination+1),hl
 ld hl,0
 add hl,sp
 ld (cgp_sp+1),hl
 ex de,hl
 di
 ld sp,hl
cgp_destination:
 ld hl,0
cgp_dispatch:
 jp cgp_words_end
 DUP 32
 pop de
 ld (hl),e
 inc hl
 ld (hl),d
 inc hl
 EDUP
cgp_words_end:
cgp_sp:
 ld sp,0
 ei
 ret
