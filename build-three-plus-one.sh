#!/bin/sh
# Build the colour version. BATTY_LANG=ru (default) or en picks the language:
# font, strings and HUD headings come from lang/<language>/.
set -eu
cd -- "$(dirname -- "$0")"
assembler=${SJASMPLUS:-../sjasmplus/sjasmplus}
lang=${BATTY_LANG:-ru}
case $lang in ru|en) ;; *) echo "BATTY_LANG must be ru or en" >&2; exit 1;; esac
export BATTY_LANG=$lang
"$assembler" --nologo --i8080 batty0.asm --exp=batty0.inc --sym=batty0.sym
node verify/generate-no-shadows.js
node verify/generate-mono-assets.js
node verify/generate-zx-frame.js
"$assembler" --nologo --i8080 --nofakes -DNO_SPRITE_SHADOWS=1 --inc=lang/$lang batty.asm --raw=batty8080.bin --sym=batty.sym
cat batty0.bin batty8080.bin > batty.rom
node verify/make-splash-rom.js
mkdir -p rom
cp batty.rom rom/battyc-$lang.rom
cp batty-splash.rom rom/battyc-$lang-splash.rom
