# Rotation for all three balls, including Smash

ROM SHA256 `d7aaeb54825140ea787354940548bdb15f0ceedda7b37e3b45652bc9d877d2d9`,32512 bytes. Native i8080,3MHz,ordinary64KB only. Four phases change every four gameplay steps. All three moving balls rotate; held balls use phase0. Smash has four larger frames. Collision dimensions, speed, bonuses and the lowered paddle stay unchanged.

The JS prototype splits a rotated lit byte into two video bytes. `verify/measure-ball-blit.js` checks1792 byte/shift combinations and98 native cases, including clipped heights. The dedicated i8080 path uses POP to read the column pairs and writes both destination bytes without a scratch column. Full-height costs:

| Sprite | General shifted blit | Dedicated blit | Saved |
|---|---:|---:|---:|
| Normal, shift1..7 |2312..2456|1212..1356|1100 cycles|
| Smash, shift1..7 |2800..2992|1468..1660|1332 cycles|

The fast path applies to isolated ball owners1..3. Overlapping objects retain shifted caches and the compositor. This preserves the compositing contract. Right-edge clipping retains the general path. Smash's unused white column was removed; additional frames occupy reclaimed, bounded asset tails. No framebuffer or disk-RAM allocation was added.

Additional native savings remove repeated indexed-table helper calls, skip the bonus-height helper outside the bonus owner, avoid storing the inner rectangle for nonintersecting pairs, hoist XOR out of the erase loop and share the normal/Smash phase selector. Raster lower-bound accounting was recalibrated after shortening those loops. The1955-scene pixel check verifies that accounting remains a lower bound, with a minimum observed margin628 cycles.

`outputs/batty-all-ball-rotation-speed.json` contains14 controlled scenes ×65 steps. `BATTY_REQUIRE_25=1` checks every machine frame, including IRQ entry overhead. Worst119808 cycles=39.936ms; zero over-budget frames. Three Smash plus the expanding paddle, bonus and UFO peak119472 cycles=39.824ms. Three Smash plus an enemy bomb also stay within39.936ms. These are controlled-scene measurements, not an assertion about every possible game state.

Verification also includes384 rotating pixel scenes (normal/Smash,1/2/3 balls,isolated/overlapping,all4 phases,all8 shifts),24 held-ball checks,1955 renderer scenes,28 bonus cases,4 life-resume modes,rocket transition,game-over sound and panels,160 paddle-dot frames and both joystick ports. Source and native execution are compared to the JS pixel oracle, including preservation of RGB background and removal of old animation pixels.

Code ends at6AE4 (28 bytes before the6B00 data boundary); renderer ends at79C6. Stack floor stays6BA0. Frames are placed below6900 so SP source reads do not overlap the guarded stack range.

Build: `sh build-three-plus-one.sh`. Run `node verify/measure-ball-blit.js`, `node verify/test-ball-rotation.js`, `node verify/test-three-plus-one.js` and `BATTY_REQUIRE_25=1 BATTY_BENCH_OUT=outputs/batty-all-ball-rotation-speed.json node verify/measure-object-speed.js`.

Uploaded and launched `/media/fat/Batty-3plus1-rotation-fast.mgl`; remote SHA256 matches the measured ROM. Prior adaptive-rotation ROM and reports remain available separately.
