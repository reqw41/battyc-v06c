#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"
assembler=${SJASMPLUS:-../sjasmplus/sjasmplus}
"$assembler" --nologo --i8080 batty0.asm --exp=batty0.inc --sym=batty0.sym
if [ "${BATTY_NO_SHADOWS:-1}" = 1 ]; then
  node verify/generate-no-shadows.js
  "$assembler" --nologo --i8080 --nofakes -DNO_SPRITE_SHADOWS=1 batty.asm --raw=batty8080.bin --sym=batty.sym
else
  "$assembler" --nologo --i8080 --nofakes batty.asm --raw=batty8080.bin --sym=batty.sym
fi
cat batty0.bin batty8080.bin > batty.rom
