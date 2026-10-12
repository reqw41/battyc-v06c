# Solid game font, common panels, paddle dots and Joystick-P

This records the earlier adaptive-rotation build. The current all-ball rotation and Smash changes are described in [ROTATION_FAST.md](ROTATION_FAST.md).

ROM SHA256: `4be81da1e4982868aa3112de54645e3a3380b57e524ab8249de30a736a3bbb04`.
32512 bytes, vanilla 64 KB, i8080 at 3 MHz. Score stays above the frame; paddle stays at Y181.

Gameplay text uses the menu's solid six-row glyph bitmap in the white overlay. HUD digits and 1UP/2UP/HI headings are generated from the same font. A/C/E backgrounds are preserved. ROUND and GAME OVER panels share X64..191, Y135..159 with line baselines143 and158. The round panel saves/restores1600 bytes; it does not consume additional RAM. Running dots calculate their row from the current paddle Y+6 instead of the former constant.

Normal balls have four native frames, changing every four gameplay steps. Held balls remain stationary and Smash uses its existing image. Three-ball scenes keep the original fast sprites: enabling rotation there raised the tested wide-transform peak to41.053ms. The adaptive version meets the40ms budget in all ten controlled scenes, worst39.936ms (119808 cycles). This is a controlled-scene result, not a guarantee for every possible game state.

Joystick-P devices are read independently through port5 selectionsBF/DF and port6. Fire starts from the menu or high-score screen and enables the firing device's joystick control. A/B toggle the control choice for players1/2. Single-player games can start with either joystick. Alternating players use their own selected device. In Double Play, keyboard player1 uses A/D/F and keyboard player2 uses arrows/Space; joystick players use devices1/2. Both can select keyboard, both joystick, or a mixture.

The hardware selection matches [MiSTer Vector-06C RTL](https://github.com/MiSTer-devel/Vector-06C_MiSTer/blob/master/Vector-06C.sv#L631): bits6:5 select both/first/second/none. Input tests emulate that port wiring; actual gamepad buttons have not been exercised by a human in this verification.

Verification reports are `outputs/batty-animation-*.json`: 1955 renderer scenes;64 rotation frames including overlapping balls and restored old positions;160 paddle-dot frames;57 text characters and10 score digits;28 bonus cases;4 life-resume modes;rocket transition;3 game-over modes;identical panel geometry;221 input combinations and separate IRQ samples;fire-start from both devices. The moving raster probe covers24 scenes ×64 samples: zero completely blank object frames, but partial raster images remain, so this does not establish tear-free rendering.

Built with `sh build-three-plus-one.sh`; verified with the scripts `test-ball-rotation.js`, `test-game-panels.js`, `test-joystick-p.js`, `test-white-outline-and-dots.js`, `test-three-plus-one.js`, `test-mono-bonus.js`, `test-mono-resume.js`, `test-mono-rocket.js`, `test-game-over.js`, `measure-object-speed.js` and `test-mono-raster.js` in `verify/`. Code ends at6ABB, below the6B00 data boundary; stack floor remains6BA0.

Uploaded and launched `/media/fat/Batty-3plus1-animation.mgl`; remote ROM SHA256 matches. Hardware screenshot: `outputs/batty-animation-mister.png`.
