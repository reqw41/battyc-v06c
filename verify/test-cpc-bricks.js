'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);
const w=(a,v)=>E.memory.write(a,v),ptr=(a,v)=>{w(a,v);w(a+1,v>>8);};
function call(n){E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;ptr(E.cpu.sp,256);E.cpu.iff=false;let t=0,k=0;while(E.cpu.pc!==256){assert(++k<2e6,n);E.cpu.instruction();E.io.commit();t+=E.cpu.vcycles;}assert.equal(E.cpu.sp,E.L.stack);return t;}
const rgb=(x,y)=>{let c=0;for(const [p,b]of[[0xa000,4],[0xc000,2],[0xe000,1]])if(E.rd(p+(x>>3)*256+224-y)&(128>>(x&7)))c|=b;return c;};
// CPC's 12x11 relief is adapted to the existing 16x8 collision cell:
// white upper/left edge, solid body, paper in the last column and row.
const inks=[4,7,6,5,0,3,4,7,7,2,3,4,7,7,2],x=88,y=56;
let staticCases=0,animationCases=0,hitAnimationFrames=0,totalTicks=0;
function check(ink,glint=Buffer.alloc(16)){
 for(let r=0;r<8;r++)for(let c=0;c<16;c++){
  let want=r===7||c===15?1:r===0||c===0?0:ink;
  if(want!==1&&(glint[r*2+(c>>3)]&(128>>(c&7))))want=0;
  assert.equal(rgb(x+c,y+r),want,JSON.stringify({r,c,ink}));
 }
 for(let i=0;i<8192;i++)assert.equal(E.rd(0x8000+i),0,'brick writes moving sprite plane');
}
function setup(type){call('planes_reset');w(0x6d00,type);ptr(E.L.cur_level_ptr,0x6d00);ptr(E.L.brik_attr_buf,0x7bc8);E.cpu.set_rp(4,0x7b38);totalTicks+=call('NativePrintBrick');}
for(let type=1;type<=15;type++){setup(type);check(inks[type-1]);staticCases++;}
for(const type of[6,7,8,9,11,12,13,14])for(let frame=0;frame<8;frame++){
 setup(type);ptr(E.L.anim_brik_ptr,E.L.anim_brik+2*frame);E.cpu.set_rp(4,0xcba8);call('print_frame_metal_brik');
 const source=E.rd(E.L.anim_brik+2*frame)+256*E.rd(E.L.anim_brik+2*frame+1),glint=source===E.L.spr_brik_1?Buffer.alloc(16):Buffer.from(Array.from({length:16},(_,i)=>E.rd(source+i)));
 check(inks[type-1],glint);animationCases++;
}
// Exercise the complete live damage-animation slot through its clean final frame.
for(const type of[6,7,11]){
 setup(type);const before=Buffer.from(Array.from({length:24576},(_,i)=>E.rd(0xa000+i))),o=E.L.briks_data;
 w(o,1);ptr(o+1,0xcba8);ptr(o+3,0x7b38);ptr(o+5,0x6d00);
 for(let step=1;step<=15;step++){
  const n=(step+1)&254,source=E.rd(E.L.anim_brik-2+n)+256*E.rd(E.L.anim_brik-1+n),glint=source===E.L.spr_brik_1?Buffer.alloc(16):Buffer.from(Array.from({length:16},(_,i)=>E.rd(source+i)));
  E.cpu.set_rp(4,o);call('metal_brik_anim');check(inks[type-1],glint);hitAnimationFrames++;
 }
 assert.equal(E.rd(o),0,'damage animation slot does not finish');
 assert(before.equals(Buffer.from(Array.from({length:24576},(_,i)=>E.rd(0xa000+i)))),'final animation changes solid brick');
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),staticCases,animationCases,hitAnimationFrames,solidBody:true,whiteTopAndLeft:true,paperRightAndBottom:true,overlayUntouched:true,finalAnimationRestoresSolidBrick:true,meanStaticTicks:totalTicks/(staticCases+animationCases+3),passed:true};
fs.writeFileSync('outputs/batty-cpc-bricks-pixels.json',JSON.stringify(result,null,2));console.log(result);
