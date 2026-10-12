# Natural three-Smash gameplay and enemy-shot measurement

Measured ROM SHA256 `d7aaeb54825140ea787354940548bdb15f0ceedda7b37e3b45652bc9d877d2d9` (80aaf36),Vector06JS,i8080 at3MHz,strict64KB. No game-code changes.

Six deterministic starts,900 raster intervals each (~108 seconds of gameplay total). The fixture uses native ball release and native pickup processing for Triple followed by Smash once. Afterwards only arrow/Space keyboard input is supplied. Paddle and ball coordinates are not forced. Smash expires naturally; balls can be lost. Enemies appear through the ordinary<44-bricks rule and shoot through the normal random/busy-bonus checks. The runs produced9 enemy shots in total. The native stack is restored after fixture setup; unexpected CPU restarts and stack overflow are rejected.

Draw-to-draw timing includes native movement,collisions,brick updates,SFX,IRQ entry and waiting. Intervals crossing death,round-window,full-reset or actual pause transitions are excluded. Both interval endpoints must still contain three active balls,Smash and a live enemy for the heavy aggregate. Enemy-shot intervals additionally contain a live bomb at either endpoint.

| Natural scene | Samples | Mean cycles | Maximum cycles | Mean time | Maximum time | Frames over40ms |
|---|---:|---:|---:|---:|---:|---:|
| Three Smash + live enemy |243|107115.28|178544|35.705ms|59.515ms|66|
| Same, with enemy bomb |66|109701.27|156132|36.567ms|52.044ms|21|

Average cadence is ~28.0Hz and ~27.3Hz respectively, but neither scene maintains25Hz on every frame. The earlier14 controlled scenes did not cover natural simultaneous brick destruction and every overlap/movement state.

Worst natural frame (run3,tick104),two bricks destroyed:

| Frame block | Cycles | Time |
|---|---:|---:|
| Logic |112164|37.388ms|
| Drawing |65500|21.833ms|
| Waiting |156|0.052ms|
| Remaining loop work |724|0.241ms|
| Total |178544|59.515ms|

Within logic,three `handling_ball` calls consumed104380 inclusive cycles;two `NativeRestoreBrick` calls consumed68148 inclusive cycles (22.716ms). These nested totals must not be added to the frame table. `DrawMovingObjects` consumed64468 cycles. Brick-background restoration is the first concrete optimization target indicated by this measurement.

Raster verification compares actual beam output to completed native object poses. It includes lookahead to the next three raster intervals when the renderer had not finished at the sampling point,avoiding false partial images due to motion. It checks the preceding five intervals as well. An exact best match does not prove a tear-free frame; overlapping white objects may also conceal a missing pixel. No wholly blank object samples were found.

| Object | Eligible raster samples | No complete pose match | Worst matched fraction |
|---|---:|---:|---:|
| Ball1 |455|0|100%|
| Ball2 |455|1|96.875%|
| Ball3 |455|1|93.75%|
| Enemy |437|17|21.538%|
| Bomb |115|0|100%|

Thus the balls and bomb show no complete disappearance in this run set;the enemy retains partial raster images. These counts include motion/animation transitions and must not be advertised as a universal no-flicker guarantee.

`outputs/batty-natural-heavy.json` contains aggregate timings,worst-frame routine profiles and raster results. `outputs/batty-natural-heavy.gif` is64 consecutive actual rasters at20ms/frame (native period19.968ms),with vertical pixel scaling corrected to match logical square pixels. GIF loops;the loop boundary is not a gameplay reset. Paired `batty-natural-heavy-run0-raster.png` / `...-memory.png` distinguish scanned output from a completed-memory preview.

Reproduce:

```
BATTY_HEAVY_RUNS=6 BATTY_HEAVY_RASTERS=900 node verify/measure-natural-heavy.js
```

The initial diagnostic with an enemy forced before its brick-count gate and a raster comparison against the wrong descriptor bank was superseded;only the final normal-spawn,completed-descriptor result above is used.
