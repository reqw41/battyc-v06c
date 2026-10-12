'use strict';
// Read the supplied archive as data; execute only its Z80 game in this sandbox.
// Usage: node verify/extract-cpc-screen.js /path/to/Batty_Amstrad-CPC_EN.zip
const fs=require('fs'),crypto=require('crypto'),{execFileSync}=require('child_process'),Z80=require('/Users/boris/Projects/kvalley-v06c/legacy/tools/vendor/Z80.js');
const archive=process.argv[2];if(!archive)throw Error('Supply the original CPC ZIP path');
const files=JSON.parse(execFileSync('python3',['-c','import sys,zipfile,json,base64; z=zipfile.ZipFile(sys.argv[1]); print(json.dumps({n.rsplit("/",1)[-1].upper():base64.b64encode(z.read(n)).decode() for n in z.namelist() if n.upper().endswith(("BATTY1.BIN","BATTY2.BIN"))}))',archive],{encoding:'utf8'}));
const mem=new Uint8Array(65536);function load(n,at){const b=Buffer.from(files[n],'base64');mem.set(b.subarray(128,128+b.readUInt16LE(24)),at??b.readUInt16LE(21));}
load('BATTY1.BIN');load('BATTY2.BIN',0xc000);mem[0x38]=0xfb;mem[0x39]=0xc9;
const counts=new Map(),palette=[],ports=[];let ticks=0,lastPC=0,row=0,ink=0,hardware=new Uint8Array(17);
const cpu=new Z80({mem_read:a=>mem[a&65535],mem_write:(a,v)=>{mem[a&65535]=v;},io_read:p=>{if((p>>8)===0xf5)return((ticks>>11)&1)|0xfe;if((p>>8)===0xf4 && row===7 && ticks>300000 && ticks<600000)return 0xef;return 255;},io_write:(p,v)=>{if((p>>8)===0xf6)row=v&15;if((p>>8)===0x7f){palette.push([ticks,p,v]);if(v<32)ink=v&31;else if((v&0xc0)===0x40&&ink<17)hardware[ink]=v&31;}if(ports.length<200)ports.push([p,v]);}});
let s=cpu.getState();s.pc=0x4268;s.sp=0xbff0;cpu.setState(s);
for(ticks=0;ticks<2e6;ticks++){const pc=cpu.getState().pc;counts.set(pc,(counts.get(pc)||0)+1);lastPC=pc;if(pc>=0xbc00&&pc<0xc000){s=cpu.getState();s.pc=mem[s.sp]+256*mem[(s.sp+1)&65535];s.sp=(s.sp+2)&65535;cpu.setState(s);continue;}cpu.run_instruction();}
fs.writeFileSync('outputs/cpc-memory.bin',mem);console.log({pc:lastPC.toString(16),state:cpu.getState(),hot:[...counts.entries()].sort((a,b)=>b[1]-a[1]).slice(0,12).map(([a,n])=>[a.toString(16),n]),hardware:Array.from(hardware),palette:palette.slice(-40),ports:ports.slice(0,12)});
const pixel=(x,y)=>{const v=mem[0xc000+(y&7)*2048+(y>>3)*80+(x>>1)];return x&1?((v>>6)&1)|((v>>1)&2)|((v>>2)&4)|((v<<3)&8):((v>>7)&1)|((v>>2)&2)|((v>>3)&4)|((v<<2)&8);};
// Condense the 12-row CPC top into the existing 8-row Vector collision wall.
const sourceRows=[2,3,4,5,7,8,9,11],sampleRow=(x,y)=>Array.from({length:8},(_,i)=>pixel(x+i,y));
const fixture={sourceArchiveSHA256:crypto.createHash('sha256').update(fs.readFileSync(archive)).digest('hex'),source:'Original CPC VRAM after running BATTY1.BIN and BATTY2.BIN; mode 0, 160x200',nativeInks:{0:'black',13:'bright white',15:'gray'},sourceRows,leftTop:sourceRows.map(y=>sampleRow(0,y)),rightTop:sourceRows.map(y=>sampleRow(152,y)),middleTop:sourceRows.map(y=>sampleRow(64,y)),leftSide:sampleRow(0,20),rightSide:sampleRow(152,20)};
fs.writeFileSync('verify/fixtures/cpc/frame.json',JSON.stringify(fixture,null,2)+'\n');
// Black outside the frame (the run of ink 0 at the outer edge of a side piece) takes the HUD paper, index 1;
// black inside it stays the level-texture shade, index 2.
const mapping={0:2,13:0,15:3},outside=(r,side)=>{let n=0;if(side==='L')while(n<8&&r[n]===0)n++;if(side==='R')while(n<8&&r[7-n]===0)n++;return i=>side==='L'?i<n:side==='R'?i>=8-n:false;};
const pair=(r,side)=>{const out=outside(r,side);return[2,1].map(bit=>r.reduce((v,c,i)=>{if(mapping[c]===undefined)throw Error('Unexpected CPC frame ink '+c);return v|((out(i)?1:mapping[c])&bit?128>>i:0);},0));};
let asm='; CPC frame, native C/E row pairs. A is zero throughout.\n; 13 white -> Vector 0; 15 gray -> 3; 0 black -> level-texture shade 2, outside the frame -> HUD paper 1.\n';
for(const [name,rows]of[['LeftTop',fixture.leftTop],['MiddleTop',fixture.middleTop],['RightTop',fixture.rightTop],['LeftSide',[fixture.leftSide]],['RightSide',[fixture.rightSide]]])asm+='CpcFrame'+name+':\n DEFB '+rows.flatMap(r=>pair(r,name[0]==='L'?'L':name[0]==='R'?'R':'M')).map(v=>'$'+v.toString(16).padStart(2,'0')).join(',')+'\n';
fs.writeFileSync('gfx/cpc_frame.asm',asm);
