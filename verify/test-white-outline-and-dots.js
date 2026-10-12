'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);
const w=(a,v)=>E.memory.write(a,v),word=(a,v)=>{w(a,v&255);w(a+1,v>>8)},read=(a,n)=>Buffer.from(Array.from({length:n},(_,i)=>E.rd(a+i)));
let minSP=E.L.stack;
function call(n){E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;word(E.cpu.sp,256);E.cpu.iff=false;let k=0;while(E.cpu.pc!==256){assert(++k<2e6,n);assert(E.cpu.pc<0x8000,'executing video');if(E.cpu.sp>=0x6900&&E.cpu.sp<=E.L.stack){minSP=Math.min(minSP,E.cpu.sp);assert(E.cpu.sp>=E.L.StackFloor,'stack overflow');}E.cpu.instruction();E.io.commit();}}
const background=()=>Array.from({length:3},(_,p)=>Buffer.from(Array.from({length:8192},(_,i)=>(i*73+(i>>3)*17+p*61)&255)));
const putBG=bg=>{for(let p=0;p<3;p++)for(let i=0;i<8192;i++)w(0xa000+p*8192+i,bg[p][i]);};
const at=(x,y)=>(x>>3)*256+((224-y)&255),bit=x=>128>>(x&7),coreBit=(buf,x,y)=>{if(x>=0&&x<256)buf[at(x,y)]|=bit(x);};
let textCases=0,characters=0;
for(const chars of [Array.from({length:16},(_,i)=>i),Array.from({length:16},(_,i)=>16+i),Array.from({length:11},(_,i)=>32+i),[0x16,0x20,0x16,0x20,0x0A,0x0A], [0x19,0x15,0x0a,0x22,0x0e,0x1b,0x26,1]]){
 call('planes_reset');const bg=background();putBG(bg);w(E.L.UiActive,0);
 const msg=0x6d00,x0=24,y0=100;[x0,y0,0,chars.length,...chars].forEach((v,i)=>w(msg+i,v));
 const core=Buffer.alloc(8192),dilation=Buffer.alloc(8192);
 for(let c=0;c<chars.length;c++)for(let r=0;r<6;r++)for(let b=0;b<8;b++)if(E.rd(E.L.font+chars[c]*6+5-r)&(128>>b)){
  const x=x0+c*8+b,y=y0-r;coreBit(core,x,y);for(const [dx,dy] of [[0,0],[-1,0],[1,0],[0,-1],[0,1]])coreBit(dilation,x+dx,y+dy);
 }
 E.cpu.set_rp(2,msg);call('print_line');
 const expected=Buffer.from(core);{const got=read(0x8000,8192);if(!got.equals(expected)){const i=got.findIndex((v,i)=>v!==expected[i]);throw Error(JSON.stringify({chars,i,col:i>>8,row:i&255,got:got[i],want:expected[i],core:core[i],dilation:dilation[i],pass:E.rd(E.L.UiStencilPass)}));}}
 for(let p=0;p<3;p++)assert(read(0xa000+p*8192,8192).equals(bg[p]),'text changed background plane '+p);
 assert.equal(E.rd(E.L.UiStencilPass),0,'stencil pass leaked');textCases++;characters+=chars.length;
}
// Digits are a distinct legacy source: white = coverage minus the ink core.
let digitCases=0;
for(let d=0;d<10;d++){
 call('planes_reset');const digitBG=background();putBG(digitBG);const dst=0x7800+232;word(E.L.score_screen_ptr,dst);E.cpu.set_a(d*16);call('NativePrintDigit');const want=Buffer.alloc(8192);
 for(let r=0;r<8;r++){const src=E.L.spr_score_digits+2+d*16+r*2;assert.equal(E.rd(src+1)&~E.rd(src),0);want[8*256+((224-232-r)&255)]=r<6?E.rd(E.L.font+d*6+r):0;}
 assert(read(0x8000,8192).equals(want),'outlined score digit '+d);for(let p=0;p<3;p++)assert(read(0xa000+p*8192,8192).equals(digitBG[p]),'digit changed background plane '+p);digitCases++;
}
// Moving dots must touch the sprite plane only. Repainting the paddle must
// also remove every old hole, including across byte boundaries and resize.
const bg=background();call('planes_reset');putBG(bg);for(let i=0;i<242;i++)w(E.L.object_ball_1+i,0);
function object(o,x,f,width){w(o,1);w(o+1,f);w(o+2,x);w(o+4,E.L.BatHomeY);w(o+12,width);w(o+20,255);w(o+21,0);}
function oracle(){const out=Buffer.alloc(8192);for(const o of [E.L.object_bat_1,E.L.object_bat_2,E.L.object_bat_temp]){
 if(!E.rd(o))continue;const x=E.rd(o+2),y=E.rd(o+4),phase=x&7;word(E.L.IXobj,o);E.cpu.set_rp(4,o);call('sprite_search');const src=E.cpu.de(),cols=E.rd(src),height=E.rd(src+1);
 for(let c=0;c<cols;c++)for(let r=0;r<height;r++)for(let b=0;b<8;b++)if(E.rd(src+3+2*(c*height+r))&(128>>b))coreBit(out,x+c*8+b,y+r);
 }return out;}
let dotFrames=0;
for(const mode of ['normal','wide','gun','split','double'])for(let t=0;t<32;t++){
 for(const o of [E.L.object_bat_1,E.L.object_bat_2,E.L.object_bat_temp])w(o,0);
 const width=mode==='wide'||mode==='split'?44:28,x=32+(t*5)%120;
 object(E.L.object_bat_1,x,mode==='wide'?4:mode==='gun'?10:mode==='split'?2:0,width);
 if(mode==='split')object(E.L.object_bat_temp,x+22,3,24);
 if(mode==='double')object(E.L.object_bat_2,176+(t%8),0,28);
 word(E.L.counter_misc,t+1);const expected=oracle();call('DrawMovingObjects');assert(read(0x8000,8192).equals(expected),'old dot hole survived paddle repaint '+mode);
 for(const [o,phase] of [[E.L.object_bat_1,(t%12)+9],...(mode==='double'?[[E.L.object_bat_2,(t%8)+10]]:[])]){
  w(E.L.running_dot_frame_1up,phase);const px=E.rd(o+2),width=E.rd(o+12),p=((width-phase)&255)>=9?phase:width-11;
  for(const dx of [p,width-p-1])expected[((px+dx)>>3)*256+((224-E.rd(o+4)-6)&255)]&=~bit(px+dx);
  E.cpu.set_rp(4,o+2);call('running_dot');
 }
 assert(read(0x8000,8192).equals(expected),'moving dot pixels '+mode);
 for(let p=0;p<3;p++)assert(read(0xa000+p*8192,8192).equals(bg[p]),'dot left a background trail '+mode+' plane '+p);
 dotFrames++;
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),textCases,characters,digitCases,dotFrames,solidMenuGlyphs:true,textAndDigitsPreserveRGB:true,backgroundUnchangedByDots:true,oldDotHolesRestored:true,maxStack:E.L.stack-minSP,passed:true};fs.writeFileSync('outputs/batty-white-outline-and-dots.json',JSON.stringify(result,null,2));console.log(result);
