'use strict';
// Name entry in the build language (LangEnglish from the symbols). Russian: digits, all 32 letters and
// '.', ',', ' ', '-', never '=' or Latin Y (46 codes). English: digits, A-Z and '.', ',', ' ', '-',
// never '_', 'II' or '=' (40 codes). The cycle wraps in both directions.
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');const EN=!!E.L.LangEnglish;
const ABC=EN?'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ., -_I=':'0123456789АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ., -=Y';
// The picture stops on Z / Я, four steps left of '-'.
const RING=EN?40:46,LAST=RING-1,PIC=LAST-4;E.memory.bytes=E.memory.bytes.slice(0,65536);const inst=E.cpu.instruction.bind(E.cpu);
const wr=(a,v)=>E.memory.write(a,v);
let menu=false;E.cpu.instruction=function(){if(this.pc===E.L.L93F8_0&&!menu){menu=true;throw 'menu';}inst();};
try{for(let f=0;f<800;f++)E.run(1);}catch(e){if(e!=='menu')throw e;}assert(menu,'menu not reached');
// Enter the routine directly with a score that beats the whole table.
wr(E.L.current_score_1up,0x56);wr(E.L.current_score_1up+1,0x34);wr(E.L.current_score_1up+2,0x12);
const row=()=>E.rd(E.L.hs_row_ptr)|E.rd(E.L.hs_row_ptr+1)<<8;
const seen=[];let entered=false,left=true,shot=false;
E.cpu.instruction=function(){
 if(this.pc===E.L.L910C_14)throw 'confirmed';
 if(this.pc===E.L.L910C_9){entered=true;const v=E.rd(row()+9);if(v!==seen.at(-1))seen.push(v);
  if(left&&seen.length>=2&&seen.at(-2)===0&&v===LAST){left=false;E.key(37,0);E.key(39,1);}
  if(!left&&v===0&&seen.lastIndexOf(PIC)>seen.indexOf(LAST)){E.key(39,0);if(!shot){shot=true;throw 'done';}}
 }inst();};
const sp=E.L.stack-2;E.cpu.sp=sp;E.cpu.iff=true;wr(sp,E.L.L93F8_0&255);wr(sp+1,E.L.L93F8_0>>8);E.cpu.pc=E.L.input_new_record_name;
E.key(37,1);
try{for(let f=0;f<20000;f++)E.run(1);}catch(e){if(e!=='done')throw e;}
assert(entered,'name entry was not reached');assert(shot,'letter cycle did not wrap both ways: '+seen.join(' '));
// Stop on a recognisable letter for the picture.
E.cpu.instruction=function(){if(this.pc===E.L.L910C_9&&E.rd(row()+9)===PIC){E.key(37,0);throw 'pic';}inst();};
E.key(37,1);try{for(let f=0;f<400;f++)E.run(1);}catch(e){if(e!=='pic')throw e;}
E.pngFrom(E.idealBmp(),EN?'outputs/batty-english-name-entry.png':'outputs/batty-russian-name-entry.png');
// Every step moves by one position in the ring; every code is reachable; nothing past '-' appears.
for(let i=1;i<seen.length;i++){const d=(seen[i]-seen[i-1]+RING)%RING;assert(d===1||d===LAST,'step '+seen[i-1]+' -> '+seen[i]);}
assert.equal(new Set(seen).size,RING);assert(Math.max(...seen)===LAST);
assert.deepEqual(seen.slice(0,12),[10,9,8,7,6,5,4,3,2,1,0,LAST]);assert.deepEqual(seen.slice(-RING-1),[...Array.from({length:RING},(_,i)=>i),0]);
const rowText=Array.from({length:14},(_,i)=>ABC[E.rd(row()+i)]).join('');assert.equal(rowText,'123456   '+ABC[PIC]+'    ');
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),language:EN?'en':'ru',selectableCodes:RING,firstLetter:ABC[10],lastLetter:ABC[PIC],wrapLeft:'0 -> -',wrapRight:'- -> 0',row:rowText,passed:true};
fs.writeFileSync(EN?'outputs/batty-english-name-entry.json':'outputs/batty-russian-name-entry.json',JSON.stringify(result,null,2));console.log(result);
