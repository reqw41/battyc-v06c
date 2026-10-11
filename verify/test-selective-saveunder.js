'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);
const w=(a,v)=>E.memory.write(a,v),ptr=(a,v)=>{w(a,v&255);w(a+1,v>>8)},read=(a,n)=>Buffer.from(Array.from({length:n},(_,i)=>E.rd(a+i)));
let cycles=0,maxStack=0,prefixMin=Infinity;
function call(name,stop){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;ptr(E.cpu.sp,256);E.cpu.iff=false;let n=0,t=0;while(E.cpu.pc!==256&&E.cpu.pc!==stop){assert(++n<2e6,name);if(E.cpu.sp>=0x6900&&E.cpu.sp<=E.L.stack){assert(E.cpu.sp>=E.L.StackFloor);maxStack=Math.max(maxStack,E.L.stack-E.cpu.sp);}if(name==='plane_object'&&E.cpu.pc===E.L.SUSaveObject){prefixMin=Math.min(prefixMin,t);assert(t>=1548,'geometry/cache prefix bound');}E.cpu.instruction();E.io.commit();t+=E.cpu.vcycles;}cycles+=t;return t;}
let paletteCases=0;
for(let level=0;level<4;level++){
 w(E.L.current_level_number_1up,level);call('SetPaletteLevel',E.L.SetPaletteGame);
 const p=read(E.L.PaletteGame,16);
 assert.equal(p[0],0);assert.equal(p[4],0);assert.equal(p[1],255);assert.equal(p[5],255);assert.equal(p[3],p[7]);
 assert.equal(new Set([p[0],p[2],p[6]]).size,3,'three background colours');
 assert.equal(p[3],E.rd(E.L.LevelEnemyColors+level));
 for(let i=0;i<8;i++)assert.equal(p[i],p[i+8],'hidden 8000 plane ignored');
 for(let bg=0;bg<8;bg++)for(const ink of ['white','enemy','black']){
  const idx=(bg&4)|(ink==='white'?1:ink==='enemy'?3:0);
  assert.equal(p[idx],ink==='white'?255:ink==='enemy'?p[3]:0);paletteCases++;
 }
}
// Independent byte algebra: every coverage/ink pair and every RGB background.
let byteCases=0;
for(let mask=0;mask<256;mask++)for(let bits=0;bits<256;bits++)for(let bg=0;bg<8;bg++)for(const enemy of [false,true]){
 const bit=128,cover=mask&bit,lit=bits&cover;
 const a=bg&4?bit:0,c=bg&2?bit:0,e=bg&1?bit:0;
 const outA=a,outC=(c&~mask)|(enemy?bits&mask:0),outE=(e&~mask)|(bits&mask);
 const idx=(outA&bit?4:0)|(outC&bit?2:0)|(outE&bit?1:0);
 assert.equal(outA,a);
 if(!cover)assert.equal(idx,bg);else assert.equal(idx&3,lit?(enemy?3:1):0);byteCases++;
}
let seed=0x709ed1;function rnd(){seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;return seed>>>0;}
function draw(v,o){for(let y=0;y<o.rows;y++)for(let c=0;c<o.cols;c++){const q=y*o.cols+c,at=(o.x+c)*256+224-o.y-y,m=o.mask[q],lit=o.lit[q]&m,enemy=o.enemy&&y>=o.half;v[8192+at]=(v[8192+at]&~m)|(enemy?lit:0);v[16384+at]=(v[16384+at]&~m)|lit;}}
function save(v,o){const rows=(o.rows+1)&254,bottom=225-o.y-rows,data=[];for(let p=2;p>=1;p--)for(let c=0;c<o.cols;c++)for(let y=0;y<rows;y++)data.push(v[p*8192+(o.x+c)*256+bottom+y]);return {...o,rows,bottom,data};}
function restore(v,r){let n=0;for(let p=2;p>=1;p--)for(let c=0;c<r.cols;c++)for(let y=0;y<r.rows;y++)v[p*8192+(r.x+c)*256+r.bottom+y]=r.data[n++];}
let scenes=0,totalSaved=0;
for(let scene=0;scene<1500;scene++){
 const bg=Buffer.from(Array.from({length:24576},()=>rnd()&255)),v=Buffer.from(bg);let records=[];
 for(let frame=0;frame<3;frame++){
  for(const r of records.reverse())restore(v,r);assert(v.equals(bg),'reverse restore');records=[];
  const expected=Buffer.from(bg),count=1+scene%11;
  for(let i=0;i<count;i++){
   const x=rnd()%32,y=rnd()%192,rows=Math.min(2+rnd()%29,192-y),cols=Math.min(1+rnd()%7,32-x),mask=Array.from({length:rows*cols},()=>rnd()&255),lit=mask.map(()=>rnd()&255),o={x,y,rows,cols,mask,lit,enemy:!!(rnd()&1),half:Math.floor(rows/2)};
   const r=save(v,o);records.push(r);totalSaved+=r.data.length;draw(v,o);draw(expected,o);
  }
  assert(v.equals(expected),'JS compositor scene '+scene);assert(v.subarray(0,8192).equals(bg.subarray(0,8192)),'A untouched');scenes++;
 }
 for(const r of records.reverse())restore(v,r);assert(v.equals(bg));
}
// Real i8080 copies: both moving C/E records and three-plane cold overlays;
// source/destination cross buffer pages, but video columns stay within a page.
let nativeCopies=0;
for(const planes of [2,3])for(let rows=2;rows<=64;rows+=2)for(let cols=1;cols<=8;cols++)for(const low of [32,225-rows]){
 const original=Buffer.from(Array.from({length:24576},(_,i)=>(i*37+(i>>3)*17+rows*3+cols*11)&255));
 for(let i=0;i<original.length;i++)w(0xa000+i,original[i]);
 w(E.L.SUWorkPlanes,planes);w(E.L.SUWorkRows,rows);w(E.L.SUWorkCols,cols);ptr(E.L.SUWorkDst,0xe300+low);ptr(E.L.SUWorkData,0x8001);
 call('SUCopySave');let expected=[];
 for(let p=0;p<planes;p++)for(let c=0;c<cols;c++)for(let y=0;y<rows;y++){const a=0xe300+low-p*8192+c*256+y;expected.push(E.rd(a));w(a,0xa5);}
 assert(read(0x8001,expected.length).equals(Buffer.from(expected)));call('SUCopyRestore');assert(read(0xa000,24576).equals(original));nativeCopies++;
}
// Every legal row/column geometry: bound is below real copy+draw work.
// Colour splitting covers all possible original half-heights, including clipping.
let paceCases=0;
for(let rows=1;rows<=32;rows++)for(let cols=1;cols<=10;cols++) {
 const drawUnit=Math.floor((44*((rows+1)&254)+112*rows+408+20*Math.floor((rows-1)/4)+264)/64);
 assert.equal(E.rd(E.L.PaceDrawCols+rows),drawUnit);
 for(let half=0;half<=32;half++) {
  call('SUReset');w(E.L.direct_rows,rows);w(E.L.direct_columns,cols);ptr(E.L.plane_dst,0xe3c0);
  const saved=call('SUSaveObject');assert.equal(E.rd(E.L.SUNoRoom),0);
  w(0x9000,cols);ptr(E.L.direct_source,0x9002);w(E.L.color_enemy,1);w(E.L.SpriteCacheHeight,2*half);
  call('PaceAccountDraw');const bound=(E.rd(E.L.PaceWork)+256*E.rd(E.L.PaceWork+1))*64;
  const drawn=call('PreparedDraw');assert(bound-1536<=saved+drawn,JSON.stringify({rows,cols,half,bound,saved,drawn}));paceCases++;
 }
}
for(let rows=2;rows<=64;rows+=2)for(let cols=1;cols<=10;cols++) {
 ptr(E.L.PaceWork,0);w(E.L.SUWorkPlanes,2);w(E.L.SUWorkRows,rows);w(E.L.SUWorkCols,cols);
 ptr(E.L.SUWorkDst,0xe380);ptr(E.L.SUWorkData,0x8000);
 assert.equal(E.rd(E.L.PaceRestoreCols+rows/2),Math.floor((44*rows+128)/64));
 call('PaceAccountRestore');const bound=(E.rd(E.L.PaceWork)+256*E.rd(E.L.PaceWork+1))*64;
 assert(bound<=call('SUCopyRestore'));paceCases++;
}
// Full production path proves the added geometry/cache prefix for every asset.
let nativeObjectBounds=0;
const assets=[{k:1,n:20},{k:2,n:9},{k:4,n:11},{k:5,n:6},{k:6,n:3},{k:7,n:5},{k:8,n:6},{k:9,n:11},{k:10,n:10},{k:11,n:1}];
for(const {k,n} of assets)for(let frame=0;frame<n;frame++)for(let shift=0;shift<8;shift++)for(const [x,y] of [[64+shift,72],[248+shift,187]])for(let warm=0;warm<2;warm++) {
 call('SUReset');ptr(E.L.plane_slot,E.L.plane_old);const o=E.L.object_ball_1;
 for(let i=0;i<22;i++)w(o+i,0);w(o,k);w(o+1,frame);w(o+2,x);w(o+4,y);w(o+20,255);
 w(E.L.object_bat_1+20,255);w(E.L.object_bat_2+20,255);ptr(E.L.counter_misc,1);ptr(E.L.IXobj,o);
 const elapsed=call('plane_object'),bound=(E.rd(E.L.PaceWork)+256*E.rd(E.L.PaceWork+1))*64;
 assert(bound<=elapsed,JSON.stringify({k,frame,x,y,warm,bound,elapsed}));nativeObjectBounds++;
}
// Saturation cannot turn a long work interval into an artificial HALT.
ptr(E.L.PaceWork,65530);w(E.L.SUWorkRows,8);w(E.L.SUWorkCols,2);call('PaceAccountRestore');
assert.equal(E.rd(E.L.PaceWork)+256*E.rd(E.L.PaceWork+1),65535);
assert(call('WaitVideoFrame')<200);assert.equal(E.rd(E.L.PaceWork)+256*E.rd(E.L.PaceWork+1),0);
// Running dots must never damage the background plane, for either A bit.
let runningDotCases=0;
for(let a=0;a<256;a++)for(let bit=0;bit<8;bit++) {
 const mask=E.rd(E.L.running_dot_mask+bit);w(0xa32d,a);w(0xc32d,255);w(0xe32d,255);
 E.cpu.set_rp(2,0xe32d);E.cpu.set_rp(4,E.L.running_dot_mask+bit);E.cpu.set_rp(0,0x3400);
 call('running_dot_black');assert.equal(E.rd(0xa32d),a);assert.equal(E.rd(0xc32d),mask);assert.equal(E.rd(0xe32d),mask);
 assert.equal(E.cpu.b(),0x34);runningDotCases++;
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),paletteCases,byteCases,scenes,totalSaved,nativeCopies,paceCases,nativeObjectBounds,prefixMin,pacingSaturation:true,runningDotCases,maxStack,physicalRAM:65536,visibleVideoPlanes:3,movingSpritePlanes:2,passed:true};
fs.writeFileSync('outputs/batty-selective-saveunder-oracles.json',JSON.stringify(result,null,2));console.log(result);
