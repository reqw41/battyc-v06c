; Only the digit cache and two render flags remain from isolation storage.
MonoRegions: ds 32,0
MonoActiveRegions EQU MonoRegions
MonoActiveCount: db 0
MonoFastDraw: db 0
MonoRegionPtr EQU MonoRegions
MonoActivePtr EQU MonoRegions
MonoPairPtr EQU MonoRegions
MonoPairOuter EQU MonoRegions
MonoPairInner EQU MonoRegions
MonoPairCount EQU MonoRegions
MonoOuterCount EQU MonoRegions
MonoBuildCount EQU MonoRegions
MonoNewRight EQU MonoRegions
 INCLUDE "routines/brick_restore_queue_lower.asm"
