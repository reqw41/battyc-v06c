'use strict';
// The ZX field frame, checked pixel by pixel against an independent colour model:
// top band lit from above, side walls lit from the left; everything else in video memory must stay untouched.
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const F=require('./generate-zx-frame.js');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);
const before=Buffer.alloc(32768);for(let i=0;i<before.length;i++){before[i]=(i*71+(i>>8)*13)&255;E.memory.write(0x8000+i,before[i]);}
const expected=Buffer.from(before);let pixels=0;
const WHITE=0,PAPER=1,GREY=3,CYAN=7,T=0,C=1,K=2;
// position 0..7: row from the top (top band) or pixel from the left (side walls)
const topInk=(m,r)=>m===T?(r<2?WHITE:r<7?CYAN:GREY):m===C?(r<2?WHITE:GREY):(r<4?WHITE:CYAN);
const sideInk=(m,p)=>m===T?(p<3?WHITE:p<6?CYAN:GREY):m===C?(p<4?WHITE:GREY):(p<4?WHITE:CYAN);
function put(x,y,c){const offset=(x>>3)*256+224-y,mask=128>>(x&7);for(const [p,bit] of [[8192,4],[16384,2],[24576,1]])expected[p+offset]=(expected[p+offset]&~mask)|(c&bit?mask:0);pixels++;}
for(let cell=0;cell<32;cell++){const mirror=cell>=16,seq=F.topSeq[mirror?31-cell:cell],material=seq&3,base=(seq>>2)*8;
 for(let r=0;r<8;r++){const bits=mirror?F.rev(F.top[base+r]):F.top[base+r];for(let b=0;b<8;b++)put(cell*8+b,r,bits&(128>>b)?topInk(material,r):PAPER);}}
// ScreenScroll=5 puts logical Y=218 at the last visible screen row, 255.
for(let y=8;y<219;y++){const k=(y-8)%56,cell=k>>3,material=F.sideSeq[cell],left=F.side[cell*8+(k&7)],right=F.rev(left);
 for(let b=0;b<8;b++){put(b,y,left&(128>>b)?sideInk(material,b):PAPER);put(248+b,y,right&(128>>b)?sideInk(material,b):PAPER);}}
E.cpu.pc=E.L.DrawFieldFrame;E.cpu.sp=E.L.stack-2;E.memory.write(E.cpu.sp,0);E.memory.write(E.cpu.sp+1,1);E.cpu.iff=false;
let instructions=0,ticks=0;while(E.cpu.pc!==256){assert(++instructions<4e5);E.cpu.instruction();E.io.commit();ticks+=E.cpu.vcycles;}
for(let i=0;i<32768;i++)assert.equal(E.rd(0x8000+i),expected[i],'frame or untouched pixel at '+(0x8000+i).toString(16));
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),pixelComparisons:pixels,videoBytesCompared:32768,overlayUntouched:true,bottomOpen:true,oneTimeDrawTicks:ticks,oneTimeDrawMs:ticks/3000,passed:true};
fs.writeFileSync('outputs/batty-zx-frame-pixels.json',JSON.stringify(result,null,2));console.log(result);
