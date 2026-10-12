'use strict';
const assert=require('assert'),fs=require('fs'),{make}=require('./vector_harness');
const before=make(process.env.BATTY_TRANSFORM_BEFORE_ROM||'../../outputs/batty-three-plus-one-fast-paced.rom',process.env.BATTY_TRANSFORM_BEFORE_SYM||'../../outputs/batty-three-plus-one-fast-paced.sym'),after=make('batty.rom','batty.sym');
for(const E of [before,after]){E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);}
function call(E,name){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;E.memory.write(E.cpu.sp,0);E.memory.write(E.cpu.sp+1,1);E.cpu.iff=false;let cycles=0,n=0;while(E.cpu.pc!==256){assert(++n<2e6,name);E.cpu.instruction();E.io.commit();cycles+=E.cpu.vcycles;}return cycles;}
const pixels=E=>Buffer.from(Array.from({length:24576},(_,i)=>E.rd(0xa000+i)));
function centreColour(buf,E,frame,x,y){
 const src=E.L[frame===6?'spr_magnet_circle_on':'spr_magnet_circle_off'],pitch=frame===6?30:23;
 for(let r=8;r<16;r++){const lit=E.rd(src+3+2*(pitch+r));for(let b=0;b<8;b++)if(lit&(128>>b)){
  const px=x+8+b,at=(px>>3)*256+224-y-r,m=128>>(px&7);buf[at]|=m;buf[8192+at]|=m;
  if(frame===7)buf[16384+at]|=m;else buf[16384+at]&=~m;
 }}return buf;
}
let magnetCases=0,oldCycles=0,newCycles=0;
for(const frame of [6,7])for(let phase=0;phase<8;phase++)for(const y of [48,51,55,56,63]){
 const x=64+phase,h=23;let expected;
 for(const E of [before,after]){
  const w=(a,v)=>E.memory.write(a,v),o=E.L.magnet_properties;
  for(let i=0;i<16;i++)w(o+i,0);w(o,3);w(o+1,frame);w(o+2,x);w(o+4,y);w(E.L.spr_magnet_circle_on+1,h);w(E.L.IXobj,o&255);w(E.L.IXobj+1,o>>8);call(E,'ix_buf_addr_calc');
  for(let c=0;c<32;c++)for(let r=0;r<24;r++)w(E.L.NativeAttrs+c*24+r,((c+r)%15)<<4);
  for(let p=0;p<3;p++)for(let i=0;i<8192;i++)w(0xa000+p*8192+i,(i*17+p*71)&255);
  if(E===after){expected=pixels(E);const src=E.L[frame===6?'spr_magnet_circle_on':'spr_magnet_circle_off'],width=E.rd(src);
   for(let r=0;r<h;r++){
    const cover=new Uint8Array(width+1),xor=new Uint8Array(width+1);
    for(let c=0;c<width;c++){const at=src+2+2*(c*(frame===6?30:23)+r),m=E.rd(at)^255,v=E.rd(at+1)^m;cover[c]|=m>>>phase;xor[c]|=v>>>phase;if(phase){cover[c+1]|=m<<(8-phase);xor[c+1]|=v<<(8-phase);}}
    for(let c=0;c<width+(phase?1:0);c++){const col=(x>>3)+c,at=col*256+224-y-r,ink=((expected[at]|expected[8192+at])|cover[c])^xor[c],color=E.rd(E.L.background_colors+((col+((y+r)>>3))%15));expected[at]=color&4?ink:0;expected[8192+at]=color&2?ink:0;expected[16384+at]=color&1?255:ink^255;}
   }
  }
  const t=call(E,'NativeStaticObject');if(E===before)oldCycles+=t;else{newCycles+=t;centreColour(expected,E,frame,x,y);const previous=centreColour(pixels(before),E,frame,x,y);if(!pixels(E).equals(previous)){const got=pixels(E),want=previous,i=got.findIndex((v,i)=>v!==want[i]);throw Error(JSON.stringify({frame,phase,y,i,got:got[i],want:want[i],cache:Array.from({length:20},(_,i)=>E.rd(0x7a00+i))}));}assert(pixels(E).equals(expected),'JS magnet mismatch '+JSON.stringify({frame,phase,y}));}
 }
 magnetCases++;
}
// Independent per-pixel oracle for folding phased halves into column pairs.
let composites=0;
const E=after;
for(let phase=0;phase<8;phase++)for(let delta=8;delta<=38;delta+=2){
 const objects=[{src:E.L.spr_bat_left_part,x:phase},{src:E.L.spr_bat_right_part,x:phase+delta}],width=Math.ceil((phase+delta+24)/8),fold=new Uint8Array(width*10),pixel=new Uint8Array(width*10);
 for(const o of objects)for(let c=0;c<3;c++)for(let r=0;r<10;r++){const lit=E.rd(o.src+3+2*(c*10+r)),s=o.x&7,col=o.x>>3;fold[(col+c)*10+r]|=lit>>>s;if(s)fold[(col+c+1)*10+r]|=lit<<(8-s);for(let b=0;b<8;b++)if(lit&(128>>b)){const px=o.x+c*8+b;pixel[(px>>3)*10+r]|=128>>(px&7);}}
 assert.deepStrictEqual(fold,pixel);composites++;
}
const report={romSHA256:require('crypto').createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),magnetCases,composites,oldMagnetMeanTicks:oldCycles/magnetCases,newMagnetMeanTicks:newCycles/magnetCases,passed:true};fs.writeFileSync('outputs/batty-transform-js-model.json',JSON.stringify(report,null,2));console.log(report);
