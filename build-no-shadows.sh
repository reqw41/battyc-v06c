#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"
BATTY_NO_SHADOWS=1 exec ./build-three-plane.sh
