; Prepared descriptors retain original source/shift until isolation is known.
; Isolated monochrome objects go straight from ROM to video, without a cache.
MonoDrawPrepared:
 ld a,(MonoOwner)
 cp 7
 jp nz,mdp_normal
 ld a,(MonoPairActive)
 dec a
 jp z,MonoDrawPair
 jp mdp_normal
