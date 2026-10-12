'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym'),B=make('../../outputs/batty-three-plus-one-transform.rom','../../outputs/batty-three-plus-one-transform.sym');
for(const Q of[E,B]){Q.memory.bytes=Q.memory.bytes.slice(0,65536);Q.run(100);}
// The old painter is compared using the current attribute-to-ink mapping.
write(B,B.L.background_colors+2,E.rd(E.L.background_colors+2));
function write(Q,a,v){Q.memory.write(a,v);}function ptr(Q,a,v){write(Q,a,v);write(Q,a+1,v>>8);}
function call(Q,n){Q.cpu.pc=Q.L[n];Q.cpu.sp=Q.L.stack-2;ptr(Q,Q.cpu.sp,256);Q.cpu.iff=false;let k=0,t=0;while(Q.cpu.pc!==256 && !(n==='SetPaletteLevel' && Q.cpu.pc===Q.L.SetPaletteGame)){assert(++k<2e6,n);Q.cpu.instruction();Q.io.commit();t+=Q.cpu.vcycles;}return t;}
const video=Q=>Buffer.from(Array.from({length:24576},(_,i)=>Q.rd(0xa000+i)));let magnets=0,magnetTicks=0,oldMagnetTicks=0;
// Magnets, independent pixel oracle. Both states share one 25x24 disc (the top-left quadrant of the ZX mask
// mirrored, no shadow) and a thin grey ring: every disc pixel further than 10.8 from the centre.
// On: cyan body (7), red arrows and core (4); the arrows stop one pixel short of the ring.
// Off: grey marks (3) on paper (1), cyan ball (7); the wide ZX ring of the off picture is dropped.
const sprite=name=>{const b=[];for(const line of fs.readFileSync('gfx/sprites_no_shadows_2.asm','utf8').match(new RegExp('^'+name+':([\\s\\S]*?)(?=^spr_\\w+:)','m'))[1].split('\n')){const m=line.split(';')[0].match(/^\s*DEFB\s+(.+)/i);if(m)for(const v of m[1].split(','))b.push(parseInt(v.trim().slice(1),16));}const w=b[0];return{cover:(r,x)=>r<b[1]&&x<8*w?b[2+2*(r*w+(x>>3))]>>(7-(x&7))&1:0,lit:(r,x)=>r<b[1]&&x<8*w?(b[2+2*(r*w+(x>>3))]&b[3+2*(r*w+(x>>3))])>>(7-(x&7))&1:0};};
const magnetOn=sprite('spr_magnet_circle_on'),magnetOff=sprite('spr_magnet_circle_off'),disc=(r,x)=>r<24&&x<25&&magnetOn.cover(Math.min(r,23-r),Math.min(x,24-x));
const coreOn=[0x00,0x1c,0x3e,0x3e,0x3e,0x3e,0x1c,0x00],coreOff=[0x1c,0x26,0x4f,0x5f,0x5f,0x7f,0x3e,0x1c],core=(t,r,x)=>r>=8&&r<16&&x>=8&&x<16&&t[r-8]>>(15-x)&1;
for(let r=8;r<16;r++)for(let x=8;x<16;x++){if(core(coreOn,r,x))assert(magnetOn.lit(r,x),'on core must lie on lit pixels');if(core(coreOff,r,x))assert(magnetOff.lit(r,x),'off core must lie on lit pixels');}
const far=(r,x)=>Math.hypot(x-12,(r-11.5)*25/24)>10.8,ringAt=(r,x)=>r>=0&&x>=0&&disc(r,x)&&far(r,x);
const oldRing=new Set();{const queue=[];for(let r=0;r<24;r++)for(let x=0;x<25;x++)if(magnetOff.lit(r,x)&&far(r,x)){oldRing.add(r*32+x);queue.push([r,x]);}
 while(queue.length){const [r,x]=queue.pop();for(const [dr,dx]of[[1,0],[-1,0],[0,1],[0,-1]]){const rr=r+dr,xx=x+dx;if(rr>=0&&rr<24&&xx>=0&&xx<25&&magnetOff.lit(rr,xx)&&!oldRing.has(rr*32+xx)){oldRing.add(rr*32+xx);queue.push([rr,xx]);}}}}
function magnetIndex(frame,r,x){
 if(ringAt(r,x))return 3;
 if(frame===6){const fr=Math.min(r,23-r),fx=Math.min(x,24-x);if(fx===5&&fr===6)return 4;if(fx===5&&fr===7)return 7; // straightened diagonal tips
  let near=false;for(let dr=-1;dr<=1;dr++)for(let dx=-1;dx<=1;dx++)if(ringAt(r+dr,x+dx))near=true;return !near&&(!magnetOn.lit(r,x)||core(coreOn,r,x))?4:7;}
 if(core(coreOff,r,x))return 7;
 return magnetOff.lit(r,x)&&!oldRing.has(r*32+x)?3:1;
}
// The cache is built from the sprite and painted over arbitrary video; a partial repaint touches only its rows.
const callA=(n,a,bc)=>{E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;ptr(E,E.cpu.sp,256);E.cpu.iff=false;E.cpu.set_reg(7,a);if(bc!==undefined)E.cpu.set_rp(0,bc);let k=0,t=0;while(E.cpu.pc!==256){assert(++k<2e6,n);E.cpu.instruction();E.io.commit();t+=E.cpu.vcycles;}return t;};
let magnetBuildTicks=0;const savedProps=Array.from({length:16},(_,i)=>E.rd(E.L.magnet_properties+i)),savedCount=E.rd(E.L.magnets_quantity);
for(const frame of[6,7])for(let phase=0;phase<8;phase++)for(const y of[48,51,55,56,63])for(const [first,rows] of[[0,24],[0,4],[7,10],[19,5]]){
 const x=64+phase,w=(a,v)=>write(E,a,v),o=E.L.magnet_properties;
 for(let i=0;i<16;i++)w(o+i,0);w(o,3);w(o+1,frame);w(o+2,x+5);w(o+4,y+5);w(E.L.magnets_quantity,1);w(E.L.SUWindowValid,0);
 magnetBuildTicks+=call(E,'MagCacheBuildAll');
 for(let i=0;i<24576;i++)w(0xa000+i,(i*17+(i>>13)*71)&255);
 const want=video(E);
 for(let r=first;r<first+rows;r++)for(let px0=0;px0<25;px0++)if(disc(r,px0)){
  const index=magnetIndex(frame,r,px0);
  const px=x+px0,at=(px>>3)*256+224-y-r,m=128>>(px&7);
  for(const [plane,bit]of[[0,4],[8192,2],[16384,1]])if(index&bit)want[plane+at]|=m;else want[plane+at]&=~m;
 }
 // A partial off-state repaint also restores the whole cyan ball in planes A and C: it only ever sets its own bits.
 if(frame===7)for(let r=8;r<16;r++)for(let px0=8;px0<16;px0++)if(core(coreOff,r,px0)){const px=x+px0,at=(px>>3)*256+224-y-r;want[at]|=128>>(px&7);want[8192+at]|=128>>(px&7);}
 const ticks=callA('MagnetPaint',0,first<<8|rows);if(rows===24)magnetTicks+=ticks;assert(video(E).equals(want),'magnet colours '+JSON.stringify({frame,phase,y,first,rows}));magnets++;
}
savedProps.forEach((v,i)=>write(E,E.L.magnet_properties+i,v));write(E,E.L.magnets_quantity,savedCount);
// Recolouring must select actual A/C ink bits, independently of E.
const attr8=E.rd(E.L.background_colors+8);let recolourCases=0;
for(let ink=0;ink<8;ink++){
 call(E,'planes_reset');write(E,E.L.background_colors+8,ink);write(E,E.L.NativeAttrs+8*24+7,0x80);
 for(let r=0;r<8;r++){const v=(r*37+0x55)&255;write(E,0xc800+224-56-r,v);write(E,0xe800+224-56-r,v^255);}
 E.cpu.set_rp(4,0x78c7);call(E,'NativeRecolorCell');
 for(let r=0;r<8;r++){const v=(r*37+0x55)&255,a=0x800+224-56-r;assert.equal(E.rd(0xa000+a),ink&4?v:0,'recolour A '+ink);assert.equal(E.rd(0xc000+a),ink&2?v:0,'recolour C '+ink);assert.equal(E.rd(0xe000+a),ink&1?255:v^255,'recolour E '+ink);}recolourCases++;
}
write(E,E.L.background_colors+8,attr8);
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
assert.equal(E.rd(E.L.briks_colors+4),0xf0);assert.equal(E.rd(E.L.background_colors+15),0);assert.equal(E.rd(E.L.PaletteGame),0xff);assert.equal(E.rd(E.L.PaletteGame+3),0xad);assert.equal(E.rd(E.L.background_colors+2),3);
// A real type-5 brick must render white ink index 0 and paper index 1.
call(E,'planes_reset');write(E,0x6d00,0x15);ptr(E,E.L.cur_level_ptr,0x6d00);ptr(E,E.L.brik_attr_buf,0x7bc8);E.cpu.set_rp(4,0x7b38);call(E,'NativePrintBrick');
const brickPaper=Buffer.alloc(8192,255);
for(let r=0;r<8;r++)for(let c=0;c<2;c++)brickPaper[(11+c)*256+224-56-r]=(r<7?(c===0?255:254):0)^255;
for(let i=0;i<8192;i++){assert.equal(E.rd(0xa000+i),0,'white brick A');assert.equal(E.rd(0xc000+i),0,'white brick C');assert.equal(E.rd(0xe000+i),brickPaper[i],'white brick E');}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),magnets,magnetFullPaintMeanTicks:magnetTicks/(magnets/4),magnetCacheBuildMeanTicks:magnetBuildTicks/magnets,magnetOn:'grey ring, cyan body, red arrows and core',magnetOff:'grey ring and marks on paper, cyan ball',magnetShadow:false,menuCases,menuInkIndices:16,headingCases,paperAcrossScreen:true,brightGreenBrick:true,whiteBrick:true,grayFrameIndex:3,recolourCases,headingCoreUsesPaper:true,passed:true};fs.writeFileSync('outputs/batty-vector-colors.json',JSON.stringify(result,null,2));console.log(result);
