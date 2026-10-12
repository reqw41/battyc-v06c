'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const source=JSON.parse(fs.readFileSync('verify/fixtures/cpc/frame.json'));
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);
const before=Buffer.alloc(32768);
for(let i=0;i<before.length;i++){before[i]=(i*71+(i>>8)*13)&255;E.memory.write(0x8000+i,before[i]);}
const expected=Buffer.from(before),ink={0:2,13:0,15:3};let pixels=0;
function put(x,y,cpc){const c=ink[cpc];assert(c!==undefined);const offset=(x>>3)*256+224-y,mask=128>>(x&7);
 for(const [p,bit] of [[8192,4],[16384,2],[24576,1]])expected[p+offset]=(expected[p+offset]&~mask)|(c&bit?mask:0);pixels++;
}
for(let y=0;y<8;y++)for(let x=0;x<256;x++)put(x,y,x<8?source.leftTop[y][x]:x>=248?source.rightTop[y][x-248]:source.middleTop[y][x&7]);
// ScreenScroll=5 puts logical Y=218 at the last visible screen row, 255.
for(let y=8;y<219;y++)for(let x=0;x<8;x++){put(x,y,source.leftSide[x]);put(248+x,y,source.rightSide[x]);}
E.cpu.pc=E.L.DrawCpcFieldFrame;E.cpu.sp=E.L.stack-2;E.memory.write(E.cpu.sp,0);E.memory.write(E.cpu.sp+1,1);E.cpu.iff=false;
let instructions=0,ticks=0;while(E.cpu.pc!==256){assert(++instructions<1e5);E.cpu.instruction();E.io.commit();ticks+=E.cpu.vcycles;}
for(let i=0;i<32768;i++)assert.equal(E.rd(0x8000+i),expected[i],'CPC frame or untouched pixel at '+(0x8000+i).toString(16));
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),sourceArchiveSHA256:source.sourceArchiveSHA256,sourcePixelComparisons:pixels,videoBytesCompared:32768,overlayUntouched:true,bottomOpen:true,sideWallsEndAtScreenRow:255,oneTimeDrawTicks:ticks,oneTimeDrawMs:ticks/3000,passed:true};
fs.writeFileSync('outputs/batty-cpc-frame-pixels.json',JSON.stringify(result,null,2));console.log(result);
