; A rows, HL E video top, DE interleaved background top. Preserve B.
CGOutsideSpan:
 or a
 ret z
 push bc
 ld b,a
 ld a,(CGRecord)
 or a
 jp nz,cgos_restore
 call CGCaptureVideo
 pop bc
 ret
cgos_restore:
 call CGRestoreVideo
 pop bc
 ret
