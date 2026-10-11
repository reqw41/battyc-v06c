'use strict';
const fs=require('fs'),assert=require('assert'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const w=(a,v)=>E.memory.write(a,v),inst=E.cpu.instruction.bind(E.cpu);
let ticks=0,started=false,injected=false,caught=false,completed=false,rocketFrames=new Set(),minSP=E.L.stack;
E.cpu.instruction=function(){
 if(started){assert(this.pc<0x8000,'execution entered video');assert(this.pc!==0&&this.pc!==256,'unexpected restart');assert.equal(E.rd(E.L.spr_bonus_rocket_1+1),27,'rocket column pitch mutated');if(this.sp>=0x6900&&this.sp<=E.L.stack){minSP=Math.min(minSP,this.sp);assert(this.sp>=E.L.StackFloor);}}
 if(this.pc===E.L.handling_rocket){caught=true;rocketFrames.add(E.rd(E.L.object_rocket+1));}
 if(this.pc===E.L.LB9E8_2){started=true;ticks++;
  if(E.rd(E.L.current_level_number_1up)===1){completed=true;throw 'done';}
  if(ticks===21)E.key(32,1);if(ticks===31)E.key(32,0);
  if(ticks===40){
   for(let i=0;i<16;i++)w(E.L.bonus_table_current+i,6);
   const o=E.L.object_ball_1,at=E.L.LB28F+1;
   w(E.L.IXobj,o&255);w(E.L.IXobj+1,o>>8);w(at,E.rd(E.L.object_bat_1+2)+4);w(at+1,150);
   injected=true;this.sp-=2;w(this.sp,this.pc&255);w(this.sp+1,this.pc>>8);this.pc=E.L.set_bonus;return;
  }
  if(injected&&E.rd(E.L.object_rocket)===6){caught=true;rocketFrames.add(E.rd(E.L.object_rocket+1));}
 }
 inst();
};
try{for(let f=0;f<2400;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='done')throw e;}
assert(completed&&caught,'rocket bonus did not advance level '+JSON.stringify({ticks,injected,caught,rocketFrames:[...rocketFrames],level:E.rd(E.L.current_level_number_1up)}));assert(rocketFrames.has(0)&&rocketFrames.has(1),'rocket animation lost a phase');
const r={romSHA256:require('crypto').createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),caught,completed,nextLevel:1,rocketFrames:[...rocketFrames],immutableSourceHeight:27,stackBytes:E.L.stack-minSP,passed:true};fs.writeFileSync('outputs/batty-transform-rocket.json',JSON.stringify(r,null,2));console.log(r);
