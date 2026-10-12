'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym'),B=make('../../outputs/batty-three-plus-one-transform.rom','../../outputs/batty-three-plus-one-transform.sym');
for(const Q of[E,B]){Q.memory.bytes=Q.memory.bytes.slice(0,65536);Q.run(100);}
function write(Q,a,v){Q.memory.write(a,v);}function ptr(Q,a,v){write(Q,a,v);write(Q,a+1,v>>8);}
function call(Q,n){Q.cpu.pc=Q.L[n];Q.cpu.sp=Q.L.stack-2;ptr(Q,Q.cpu.sp,256);Q.cpu.iff=false;let k=0,t=0;while(Q.cpu.pc!==256 && !(n==='SetPaletteLevel' && Q.cpu.pc===Q.L.SetPaletteGame)){assert(++k<2e6,n);Q.cpu.instruction();Q.io.commit();t+=Q.cpu.vcycles;}return t;}
const video=Q=>Buffer.from(Array.from({length:24576},(_,i)=>Q.rd(0xa000+i)));let magnets=0,magnetTicks=0,oldMagnetTicks=0;
for(const frame of[6,7])for(let phase=0;phase<8;phase++)for(const y of[48,51,55,56,63])for(const h of(frame===6?[23,30]:[23])){
 const x=64+phase;
 for(const Q of[B,E]){const w=(a,v)=>write(Q,a,v),o=Q.L.magnet_properties;
  for(let i=0;i<16;i++)w(o+i,0);w(o,3);w(o+1,frame);w(o+2,x);w(o+4,y);w(Q.L.spr_magnet_circle_on+1,h);ptr(Q,Q.L.IXobj,o);call(Q,'ix_buf_addr_calc');
  for(let c=0;c<32;c++)for(let r=0;r<24;r++)w(Q.L.NativeAttrs+c*24+r,((c+r)%15)<<4);
  for(let i=0;i<24576;i++)w(0xa000+i,(i*17+(i>>13)*71)&255);
 }
 oldMagnetTicks+=call(B,'NativeStaticObject');const want=video(B),src=B.L[frame===6?'spr_magnet_circle_on':'spr_magnet_circle_off'],pitch=frame===6?30:23;
 for(let r=8;r<16;r++){const lit=B.rd(src+3+2*(pitch+r));for(let b=0;b<8;b++)if(lit&(128>>b)){
  const px=x+8+b,at=(px>>3)*256+224-y-r,m=128>>(px&7);want[at]|=m;want[8192+at]|=m;
  if(frame===7)want[16384+at]|=m;else want[16384+at]&=~m;
 }}
 magnetTicks+=call(E,'NativeStaticObject');assert(video(E).equals(want),'centre-only magnet colour '+JSON.stringify({frame,phase,y,h}));magnets++;
}
// Every menu ink uses all four planes, on paper index 1.
let menuCases=0;
for(let color=0;color<16;color++)for(const glyph of[0,1,0x55,0x80,0xff]){
 call(E,'planes_reset');write(E,E.L.UiActive,1);write(E,E.L.UiColor,color);E.cpu.set_rp(4,0xc888);E.cpu.set_a(glyph);call(E,'UiPixelWrite');
 for(const [plane,flag]of[[0x8000,8],[0xa000,4],[0xc000,2],[0xe000,1]])assert.equal(E.rd(plane+0x888),flag===1?(color&1?255:glyph^255):(color&flag?glyph:0));menuCases++;
}
// Paper is supplied across the entire screen, including HUD and spare lives.
call(E,'planes_reset');for(let i=0;i<8192;i++){assert.equal(E.rd(0xe000+i),255);for(const p of[0x8000,0xa000,0xc000])assert.equal(E.rd(p+i),0);}
const originals=fs.readFileSync('gfx/sprites_with_masks_1.asm','utf8');let headingCases=0;
for(let theme=0;theme<4;theme++){
 write(E,E.L.current_level_number_1up,theme);call(E,'SetPaletteLevel');assert.equal(E.rd(E.L.PaletteGame+1),E.rd(E.L.LevelPaperColors+theme));
 for(const [frame,name,x]of[[1,'spr_1up',28],[2,'spr_2up',204],[3,'spr_hi',120]]){
  call(E,'planes_reset');const o=E.L.object_score_indicator;[3,frame,x,0,232].forEach((v,i)=>write(E,o+i,v));write(E,o+21,0);ptr(E,E.L.IXobj,o);call(E,'NativeStaticObject');
  const block=originals.match(new RegExp('^'+name+':([\\s\\S]*?)(?=^spr_)','m'))[1],bytes=[];for(const m of block.matchAll(/DEFB\s+(.+)/g))bytes.push(...m[1].split(',').map(v=>parseInt(v.trim().slice(1),16)));
  const core=Buffer.alloc(8192);for(let r=0;r<bytes[1];r++)for(let c=0;c<bytes[0];c++){const i=2+2*(r*bytes[0]+c),bits=bytes[i]&~bytes[i+1];for(let b=0;b<8;b++)if(bits&(128>>b)){const px=x+c*8+b;core[(px>>3)*256+((224-232-r)&255)]|=128>>(px&7);}}
  for(let i=0;i<8192;i++){assert.equal(E.rd(0xe000+i),255,'heading paper/core');assert.equal(E.rd(0xa000+i),0);assert.equal(E.rd(0xc000+i),0);}headingCases++;
 }
}
// Additional ordinary brick shade uses native bright green without changing toughness.
assert.equal(E.rd(E.L.briks_colors+3),0x60);assert.equal(E.rd(E.L.background_colors+6),5);assert.equal(E.rd(E.L.PaletteGame+5),0x38);
assert.equal(E.rd(E.L.briks_colors+4),0xf0);assert.equal(E.rd(E.L.background_colors+15),0);assert.equal(E.rd(E.L.PaletteGame),0);
// A real type-5 brick must render ink index 0 and paper index 1.
call(E,'planes_reset');write(E,0x6d00,0x15);ptr(E,E.L.cur_level_ptr,0x6d00);ptr(E,E.L.brik_attr_buf,0x7ac8);E.cpu.set_rp(4,0x7a38);call(E,'NativePrintBrick');
const blackPaper=Buffer.alloc(8192,255);
for(let r=0;r<8;r++)for(let c=0;c<2;c++)blackPaper[(10+c)*256+224-56-r]=E.rd(E.L.spr_brik_1+r*2+c)^255;
for(let i=0;i<8192;i++){assert.equal(E.rd(0xa000+i),0,'black brick A');assert.equal(E.rd(0xc000+i),0,'black brick C');assert.equal(E.rd(0xe000+i),blackPaper[i],'black brick E');}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),magnets,magnetMeanTicks:magnetTicks/magnets,previousMagnetMeanTicks:oldMagnetTicks/magnets,colourOverheadMeanTicks:(magnetTicks-oldMagnetTicks)/magnets,magnetCenterOn:6,magnetCenterOff:7,ringMatchesPreviousROM:true,menuCases,menuInkIndices:16,headingCases,paperAcrossScreen:true,brightGreenBrick:true,blackBrick:true,headingCoreUsesPaper:true,passed:true};fs.writeFileSync('outputs/batty-vector-colors.json',JSON.stringify(result,null,2));console.log(result);
