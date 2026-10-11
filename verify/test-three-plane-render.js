'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const root=process.env.BATTY_TEST_BASE||'.';
const E=make(root+'/batty.rom',root+'/batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);
const w=(a,v)=>E.memory.write(a,v),word=(a,v)=>{w(a,v&255);w(a+1,v>>8)},range=(a,n)=>Buffer.from(Array.from({length:n},(_,i)=>E.rd(a+i)));
let maxStack=0;
function call(name){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;word(E.cpu.sp,256);E.cpu.iff=false;let n=0;while(E.cpu.pc!==256&&n++<2e6){if(E.cpu.sp>=E.L.StackFloor&&E.cpu.sp<=E.L.stack)maxStack=Math.max(maxStack,E.L.stack-E.cpu.sp);assert(E.cpu.pc<0x8000,'code escaped');E.cpu.instruction();E.io.commit();}assert(n<2e6,name);assert.equal(E.memory.cw,0);}
call('planes_reset');
const bg=[Buffer.alloc(8192),Buffer.alloc(8192),Buffer.alloc(8192)];
for(let p=0;p<3;p++)for(let i=0;i<8192;i++){bg[p][i]=((i*73+(i>>3)*17+p*61)^0xa5)&255;w([0xa000,0xc000,0xe000][p]+i,bg[p][i]);}
const attrs=range(E.L.NativeAttrs,768);
function clearObjs(){for(let i=0;i<11;i++)for(let j=0;j<22;j++)w(E.L.object_ball_1+i*22+j,0);w(E.L.object_bat_1+20,255);w(E.L.object_bat_2+20,255);word(E.L.counter_misc,1);}
function obj(i,k,x,y,frame=0){const o=E.L.object_ball_1+22*i;w(o,k);w(o+1,frame);w(o+2,x);w(o+4,y);w(o+20,255);w(o+21,0);return o;}
function oracle(){const out=bg.map(b=>Buffer.from(b));let list=Array.from({length:11},(_,i)=>E.L.object_ball_1+22*i);list=[E.L.object_bonus,...list.filter(o=>o!==E.L.object_bonus)];for(const o of list){const k=E.rd(o),x=E.rd(o+2),y=E.rd(o+4),s=E.rd(o+21)&128?0:x&7;if(!k||k&128||y>=192)continue;word(E.L.IXobj,o);E.cpu.set_rp(4,o);call('sprite_search');const a=E.cpu.de(),width=E.rd(a),height=E.rd(a+1),rows=Math.min(height,192-y);assert(width<=10&&height<=30,'invalid test frame');for(let r=0;r<rows;r++){const masks=new Uint8Array(width+1),pixels=new Uint8Array(width+1);for(let c=0;c<width;c++){const m=E.rd(a+2+2*(r*width+c)),v=m&~E.rd(a+3+2*(r*width+c));masks[c]|=m>>>s;pixels[c]|=v>>>s;if(s){masks[c+1]|=m<<(8-s);pixels[c+1]|=v<<(8-s);}}for(let c=0;c<width+(s?1:0)&&(x>>3)+c<32;c++){const pos=((x>>3)+c)*256+((224-y-r)&255),m=masks[c],v=pixels[c],enemy=k>=8&&k<=10&&r>=(height>>1);for(let p=0;p<3;p++){if(E.L.SUObjectPlanes===2){if(p===0)continue;out[p][pos]=(out[p][pos]&~m)|(p===2||enemy?v:0);}else out[p][pos]=(out[p][pos]&~m)|(enemy&&p!==2?0:v);}}}}return out;}
let scenes=0,checks=0;
function step(scene){const expect=oracle();call('planes_begin');call('DrawMovingObjects');call('RCFlush');assert.equal(E.rd(E.L.SUDropped),0,'save-under capacity');for(let p=0;p<3;p++){const got=range([0xa000,0xc000,0xe000][p],8192);if(!got.equals(expect[p])){const i=got.findIndex((v,i)=>v!==expect[p][i]);throw Error(JSON.stringify({scene,p,i,got:got[i],want:expect[p][i]}));}checks++;}assert(range(E.L.NativeAttrs,768).equals(attrs));scenes++;}
// Every valid dynamic asset, shifts 0..7, bottom/right clipping, frame changes.
const sets=[{k:1,n:20},{k:2,n:9},{k:4,n:11},{k:5,n:6},{k:6,n:3},{k:7,n:5},{k:8,n:6},{k:9,n:11},{k:10,n:10},{k:11,n:1}];
for(const {k,n} of sets)for(let f=0;f<n;f++)for(let shift=0;shift<8;shift++)for(const [x,y] of [[64+shift,72],[248+shift,187]]){clearObjs();obj(0,k,x,y,f);step({k,f,shift,x,y});}
// Intersections, changing footprints, disappearing objects, two bats, all 11 slots.
for(let t=0;t<160;t++){clearObjs();const s=t%8;obj(6,1,160+s,Math.min(170,102+t%32),t%16);obj(7,1,176+(7-s),111,t%16);for(let i=0;i<3;i++)obj(i,2,174+s+3*i,108+2*i,t%9);obj(3,5,183+s,112,t%2);obj(4,5,184+s,113,t%2);obj(5,6,172+s,110,t%2);obj(8,4,176+s,108,t%11);obj(9,8,176+s,108,t%6);obj(10,11,171+s,105,0);step({overlap:t});}
for(let t=0;t<4;t++){clearObjs();step({empty:t});}
call('SUInvalidate');for(let p=0;p<3;p++)assert(range([0xa000,0xc000,0xe000][p],8192).equals(bg[p]));
// Round window restores precisely, even its black outline on patterned background.
call('show_window_round_number');assert.equal(E.rd(E.L.SUWindowValid),1);call('win_bg_recovery');for(let p=0;p<3;p++){const got=range([0xa000,0xc000,0xe000][p],8192);assert(got.equals(bg[p]),'round window restoration plane '+p);}
// Background modification invalidates live save-under before changing pixels.
clearObjs();obj(0,2,64,72,0);step({backgroundEvent:true});
const virtual=E.L.scr_buff+8*256+72;E.cpu.set_rp(4,virtual);E.cpu.set_a(0x5a);call('NativeWriteHL');
const native=8*256+224-72;bg[0][native]=0;bg[1][native]=0x5a;bg[2][native]=0;
call('planes_begin');for(let p=0;p<3;p++)assert(range([0xa000,0xc000,0xe000][p],8192).equals(bg[p]),'background event plane '+p);
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync(root+'/batty.rom')).digest('hex'),scenes,planeComparisons:checks,reverseRestore:true,roundWindowRestored:true,backgroundEventRestored:true,maxStack,strict64K:true,passed:true};
fs.writeFileSync(process.env.BATTY_TEST_OUT||'outputs/batty-three-plane-render.json',JSON.stringify(result,null,2));console.log(result);
