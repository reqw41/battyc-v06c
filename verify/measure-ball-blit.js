'use strict';
// JS prototype: direct two-byte output ORed into the white plane (old sprite areas are
// cleared separately by the clear-old/redraw renderer). Compare native 8080 execution against this oracle.
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);const w=(a,v)=>E.memory.write(a,v),word=(a,v)=>{w(a,v);w(a+1,v>>8)},read=()=>Buffer.from(Array.from({length:8192},(_,i)=>E.rd(32768+i)));
const prototype=(v,shift)=>[v>>>shift,(v<<(8-shift))&255];for(let v=0;v<256;v++)for(let s=1;s<8;s++){const r=((v>>>s)|(v<<(8-s)))&255,mask=255>>>s;assert.deepStrictEqual([r&mask,r&(~mask&255)],prototype(v,s));}
function call(n,s){E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;word(E.cpu.sp,256);E.cpu.set_rp(0,s<<8);E.cpu.iff=false;let t=0;for(let i=0;E.cpu.pc!==256;i++){assert(i<1e6);E.cpu.instruction();E.io.commit();t+=E.cpu.vcycles;}return t;}
const video=0x8950,results=[];let cases=0;
for(const [name,source,height] of [['normal',E.L.BallRotation1,6],['smash',E.L.SmashRotation2,8]])for(let shift=1;shift<8;shift++)for(let rows=1;rows<=height;rows++){
 const original=Buffer.from(Array.from({length:8192},(_,i)=>(i*71+17)&255)),expected=Buffer.from(original);
 for(let r=0;r<rows;r++){const [left,right]=prototype(E.rd(source+3+r*2),shift);expected[video-32768-r]|=left;expected[video-32768+256-r]|=right;}
 const times={};for(const proc of['MonoDrawWhiteGeneral','MonoBallShiftDraw']){for(let i=0;i<8192;i++)w(32768+i,original[i]);word(E.L.MonoDrawVideo,video);word(E.L.MonoDrawSource,source+2);w(E.L.MonoDrawRows,rows);w(E.L.MonoDrawCols,2);w(E.L.direct_shift,shift);w(E.L.MonoFastDraw,1);w(E.L.MonoOwner,0);times[proc]=call(proc,shift);{const got=read();if(!got.equals(expected)){const at=got.findIndex((v,i)=>v!==expected[i]);throw Error(proc+' differs '+JSON.stringify({name,shift,rows,at,got:got[at],expected:expected[at],src:Array.from({length:6},(_,r)=>E.rd(source+3+r*2))}));}}}if(rows===height)results.push({name,shift,generalCycles:times.MonoDrawWhiteGeneral,ballCycles:times.MonoBallShiftDraw,savedCycles:times.MonoDrawWhiteGeneral-times.MonoBallShiftDraw});cases++;
}
const report={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),jsRotateCases:1792,nativeOracleCases:cases,results,passed:true};fs.writeFileSync('outputs/batty-rotation-blit.json',JSON.stringify(report,null,2));console.table(results);
