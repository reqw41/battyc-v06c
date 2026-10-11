; Предварительная подготовка к запуску

	DI
	LD SP,stack
	;LD A,c00  ; Чёрный
	;CALL cls ;DEBUG

; Dynamic masks are shifted lazily in the sprite cache.
 IFDEF NO_SPRITE_SHADOWS
 ; Compact phases are generated offline into fixed reservations.
 nop
 nop
 nop
 ELSE
	CALL spr_shift_gen	; Генерация сдвинутых спрайтов шарика и всех видов кареток
 ENDIF

; Native masks and legacy static XOR pairs are converted offline.
 jp L6800_6

L6800_6:
; Rocket source has an immutable 27-row column pitch; bonus clips to 12.
	LD A,$c3
	LD (start_bin),A
	LD HL,WarmStart
	LD (start_bin+1),HL
	ei
	JP game_start		; Запуск игры

; Used by the routine at 6800.
; Формирование сдвинутых спрайтов для мяча и разных видов кареток
spr_shift_gen:
 ret ; native phases are generated offline
 INCLUDE "routines/mono_composite_geometry.asm"
 INCLUDE "routines/mono_draw_pair.asm"
 INCLUDE "routines/mono_draw_dispatch.asm"

; The former shift generator is permanent native code now. Reserve its
; current 259-byte bank so subsequent asset addresses cannot silently move.
 ASSERT $ <= start_bin+259
 IF $ < start_bin+259
 DS start_bin+259-$,0
 ENDIF
