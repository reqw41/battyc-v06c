; Game clock: VI53 channel 2 (port 09h), unused during play. Mode 0 counts
; down at 1.5 MHz, wraps every 65536 counts and keeps its output high after
; the first terminal count, so it is silent. One raster is 59904 CPU cycles,
; 29952 counts: exactly 117 steps of the counter's high byte.
; Raster IRQs can be lost while SP blits run under DI; this clock cannot.
PaceRepeat EQU $71e3 ; logic steps owed: game time not yet played
 ASSERT PaceRepeat+1 <= PreparedCover
PaceClockStart:
 ei
 halt ; start on a raster boundary, where the one-ball wait used to end
 ld a,$b0 ; channel 2, LSB then MSB, mode 0, binary
 out ($08),a
 xor a
 out ($09),a
 out ($09),a
 ld (ps_prev+1),a
 ld (ps_acc+1),a
 ld (pt_mark+1),a
 inc a
 ld (PaceRepeat),a
 ld (pw_steps+1),a ; one logic step per draw
 ret
 DS 4,0 ; free, keeps the sprite pads at their old addresses

 INCLUDE "routines/game_over_player_line.asm"
