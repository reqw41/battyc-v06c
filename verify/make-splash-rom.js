'use strict';
// batty-splash.rom = batty.rom (0100..7FFF) + the title picture, which the loader puts straight
// into the screen memory (8000..FFFF). The start code shows it only when SplashPresent is set.
const fs=require('fs');
const rom=fs.readFileSync('batty.rom'),pic=fs.readFileSync('gfx/splash/splash.bin');
if(rom.length!==32512||pic.length!==32768)throw Error('unexpected sizes '+rom.length+' '+pic.length);
const m=fs.readFileSync('batty0.sym','utf8').match(/^SplashPresent:\s+EQU\s+0x([0-9A-F]+)/mi);
if(!m)throw Error('SplashPresent not found');
const out=Buffer.concat([rom,pic]);out[parseInt(m[1],16)-0x100]=1;
fs.writeFileSync('batty-splash.rom',out);
