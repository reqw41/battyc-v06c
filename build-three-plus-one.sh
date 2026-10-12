#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"
assembler=${SJASMPLUS:-../sjasmplus/sjasmplus}
"$assembler" --nologo --i8080 batty0.asm --exp=batty0.inc --sym=batty0.sym
node verify/generate-no-shadows.js
node verify/generate-mono-assets.js
node verify/generate-zx-frame.js
"$assembler" --nologo --i8080 --nofakes -DNO_SPRITE_SHADOWS=1 batty.asm --raw=batty8080.bin --sym=batty.sym
cat batty0.bin batty8080.bin > batty.rom
node verify/make-splash-rom.js
