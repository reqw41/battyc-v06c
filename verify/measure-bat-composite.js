'use strict';
const fs=require('fs'),assert=require('assert'),{make}=require('./vector_harness');
const before=make(process.env.BATTY_TRANSFORM_BEFORE_ROM||'../../outputs/batty-three-plus-one-fast-paced.rom',process.env.BATTY_TRANSFORM_BEFORE_SYM||'../../outputs/batty-three-plus-one-fast-paced.sym'),after=make('batty.rom','batty.sym');
for(const E of [before,after]){E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);}
function call(E,name){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;E.memory.write(E.cpu.sp,0);E.memory.write(E.cpu.sp+1,1);E.cpu.iff=false;let t=0,n=0;while(E.cpu.pc!==256){assert(++n<2e6,name);E.cpu.instruction();E.io.commit();t+=E.cpu.vcycles;}return t;}
const reports=[];
for(const offset of [8,10,14,18,22,26,30])for(let phase=0;phase<8;phase++){
 let oldTicks,newTicks,oldPixels;
 for(const E of [before,after]){
  const w=(a,v)=>E.memory.write(a,v);for(let i=0;i<242;i++)w(E.L.object_ball_1+i,0);
  for(const [o,x,frame] of [[E.L.object_bat_1,96+phase,2],[E.L.object_bat_temp,96+phase+offset,3]]){w(o,1);w(o+1,frame);w(o+2,x);w(o+4,173);w(o+20,255);w(o+21,0);}
  call(E,'planes_reset');call(E,'DrawMovingObjects');const t=call(E,'DrawMovingObjects'),pixels=Buffer.from(Array.from({length:8192},(_,i)=>E.rd(0x8000+i)));
  if(E===before){oldTicks=t;oldPixels=pixels;}else{newTicks=t;assert(pixels.equals(oldPixels),'native composite changed pixels');}
 }
 reports.push({offset,phase,oldTicks,newTicks});
}
const report={romSHA256:require('crypto').createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),cases:reports.length,oldMeanTicks:reports.reduce((t,r)=>t+r.oldTicks,0)/reports.length,newMeanTicks:reports.reduce((t,r)=>t+r.newTicks,0)/reports.length,oldMaxTicks:Math.max(...reports.map(r=>r.oldTicks)),newMaxTicks:Math.max(...reports.map(r=>r.newTicks)),method:'Two native renders per independent phased split-paddle fixture; second render measured; source selection, composition and erase included; logic and raster wait excluded.',reports,passed:true};fs.writeFileSync('outputs/batty-transform-composite-speed.json',JSON.stringify(report,null,2));console.log({...report,reports:undefined});
