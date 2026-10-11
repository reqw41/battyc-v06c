; Reclaimed ordinary RAM below the guarded stack. Rebuilt every render.
MonoRegions: ds 55,0 ; left, exclusive right, top, inclusive bottom, isolated
MonoActiveRegions: ds 22,0
MonoActiveCount: db 0
MonoRegionPtr: dw 0
MonoActivePtr: dw 0
MonoPairPtr: dw 0
MonoPairOuter: dw 0
MonoPairInner: dw 0
MonoPairCount: db 0
MonoOuterCount: db 0
MonoBuildCount: db 0
MonoFastDraw: db 0
MonoNewRight: db 0
