'use strict';
const fs=require('fs'),assert=require('assert'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);
const w=(a,v)=>E.memory.write(a,v),word=(a,v)=>{w(a,v&255);w(a+1,v>>8)},read=(a,n)=>Buffer.from(Array.from({length:n},(_,i)=>E.rd(a+i)));
function call(name){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;word(E.cpu.sp,256);E.cpu.iff=false;let n=0;while(E.cpu.pc!==256){assert(++n<2e6);E.cpu.instruction();E.io.commit();}}
let cases=0;const original=fs.readFileSync('gfx/sprites_with_masks_1.asm','utf8');
for(const [frame,name,x] of [[1,'spr_1up',28],[2,'spr_2up',204],[3,'spr_hi',120]]){
 call('planes_reset');const o=E.L.object_score_indicator;w(o,3);w(o+1,frame);w(o+2,x);w(o+4,232);w(o+21,0);word(E.L.IXobj,o);call('NativeStaticObject');
 const block=original.match(new RegExp('^'+name+':([\\s\\S]*?)(?=^spr_)','m'))[1],bytes=[];for(const line of block.split('\n')){const m=line.split(';')[0].match(/^\s*DEFB\s+(.+)/i);if(m)for(const v of m[1].split(','))bytes.push(parseInt(v.trim().slice(1),16));}
 const [width,height]=bytes,want=Buffer.alloc(8192),phase=x&7;
 for(let r=0;r<height;r++)for(let c=0;c<width;c++){const at=2+2*(r*width+c),lit=bytes[at]&bytes[at+1],dst=((x>>3)+c)*256+((224-232-r)&255);want[dst]|=lit>>>phase;if(phase)want[dst+256]|=lit<<(8-phase);}
 assert(read(0x8000,8192).equals(want),'HUD transpose '+name);cases++;
}
// The white cross contour with the background in its core is tested on a patterned background, then the
// round-window save restores all four planes, including its last 64 bytes.
for(let p=0;p<4;p++)for(let i=0;i<8192;i++)w(0x8000+p*8192+i,(i*13+p*41)&255);
call('MonoReset');const before=read(0x8000,32768);call('show_window_round_number');assert(read(0xa000,24576).equals(before.subarray(8192)),'text changed the RGB background');call('win_bg_recovery');assert(read(0x8000,32768).equals(before),'outlined window did not restore all planes');
const result={cases,scoreHeadings:true,outlinedWindowRestoresFourPlanes:true,passed:true};fs.writeFileSync('outputs/batty-transform-hud.json',JSON.stringify(result,null,2));console.log(result);
