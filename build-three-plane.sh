#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"
assembler=${SJASMPLUS:-../sjasmplus/sjasmplus}
"$assembler" --nologo --i8080 batty0.asm --exp=batty0.inc --sym=batty0.sym
"$assembler" --nologo --i8080 --nofakes batty.asm --raw=batty8080.bin --sym=batty.sym
cat batty0.bin batty8080.bin > batty.rom
