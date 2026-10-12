'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
function measure(rom,sym){
 const E=make(rom,sym);E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);
 const w=(a,v)=>E.memory.write(a,v),ptr=(a,v)=>{w(a,v);w(a+1,v>>8);};
 const call=n=>{E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;ptr(E.cpu.sp,256);E.cpu.iff=false;let t=0,k=0;while(E.cpu.pc!==256){assert(++k<1e6,n);E.cpu.instruction();E.io.commit();t+=E.cpu.vcycles;}return t;};
 call('planes_reset');
 for(let i=0;i<5;i++){
  const col=3+4*i,o=E.L.briks_data+7*i;
  w(0x6d00+i,6);ptr(E.L.cur_level_ptr,0x6d00+i);ptr(E.L.brik_attr_buf,0x70c8+col*256);E.cpu.set_rp(4,0x7038+col*256);call('NativePrintBrick');
  w(o,1);ptr(o+1,0xc0a8+col*256);ptr(o+3,0x7038+col*256);ptr(o+5,0x6d00+i);
 }
 const ticks=[];for(let step=0;step<15;step++){
  let t=0;for(let i=0;i<5;i++){E.cpu.set_rp(4,E.L.briks_data+7*i);t+=call('metal_brik_anim');}ticks.push(t);
 }
 return {fiveConcurrentHitAnimations:true,steps:15,meanTicks:ticks.reduce((a,b)=>a+b)/ticks.length,maxTicks:Math.max(...ticks),meanMs:ticks.reduce((a,b)=>a+b)/ticks.length/3000,maxMs:Math.max(...ticks)/3000};
}
const before=measure('../../outputs/batty-three-plus-one-cpc-frame.rom','../../outputs/batty-three-plus-one-cpc-frame.sym'),after=measure('batty.rom','batty.sym');
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),method:'Native i8080 instruction emulation, interrupts disabled to isolate the five damage-animation slots. This measures active animation cost, not a complete gameplay frame.',before,after,meanSavedTicks:before.meanTicks-after.meanTicks,passed:true};
fs.writeFileSync('outputs/batty-cpc-bricks-animation-speed.json',JSON.stringify(result,null,2));console.log(result);
