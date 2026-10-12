NativeRestoreAddressSetup:
 ld a,(NativeRestoreRowClip)
 or a
 jp nz,NativeRestoreSetupVideo
 ld a,(NativeRestoreLeftClip)
 cp $ff
 jp nz,NativeRestoreSetupVideo
NativeRestoreStampAttrs:
 ld hl,(NativeRestoreXY)
 call scr_buff_attr_calc
 call NativeAttrAddress
 ld (hl),$d0
 ld de,24
 add hl,de
 ld (hl),$d0
NativeRestoreSetupVideo:
 ld hl,(NativeRestoreXY)
 ld a,l
 rrca
 rrca
 rrca
 and 31
 or $c0
 ld d,a
 ld a,224
 sub h
 ld e,a
 ret
