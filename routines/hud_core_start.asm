; Persistent headings: draw the white contour, then set paper/black core.
NativeOutlinedHeading:
 call plane_static_object
HudClearCore:
 ld hl,0
 add hl,sp
 ld (hud_core_restore+1),hl
 ld hl,(MonoDrawSource)
 di
 ld sp,hl
 jp HudClearCoreBody
