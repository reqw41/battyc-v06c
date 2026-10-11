'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);
const put=(a,v)=>E.memory.write(a,v),word=(a,v)=>{put(a,v&255);put(a+1,v>>8);},read=a=>E.rd(a)+256*E.rd(a+1);
const cases=[];
const dispatch=[];
for(const owners of [4,5,11,2]){
 put(E.L.MonoActiveCount,owners);E.cpu.pc=E.L.PaceStart;E.cpu.sp=E.L.stack-2;word(E.cpu.sp,256);E.cpu.iff=false;
 let steps=0;while(E.cpu.pc!==256){assert(++steps<100);E.cpu.instruction();E.io.commit();}
 const detailed=owners>=5;
 assert.equal(read(E.L.mono_pace_draw_call+1),detailed?E.L.PaceAccountDraw:E.L.RCBegin);
 assert.equal(read(E.L.mono_pace_old_call+1),detailed?E.L.PaceAccountOld:E.L.RCBegin);
 assert.equal(read(E.L.PaceWork),231+4*owners*(owners-1)/2);
 dispatch.push({owners,detailed});
}
for(const work of [0,935,936,937,65535])for(const changedIRQ of [false,true]){
 word(E.L.PaceWork,work);put(E.L.IntCount,41);put(E.L.WaitVideoFrameLast+1,changedIRQ?40:41);
 E.cpu.pc=E.L.WaitGameplayFrame;E.cpu.sp=E.L.stack-2;word(E.cpu.sp,256);E.cpu.iff=false;
 let cycles=0,steps=0;
 while(![E.L.WaitVideoFrame,E.L.wvf_ready].includes(E.cpu.pc)){
  assert(++steps<30,'wait dispatch did not finish');assert.notEqual(E.rd(E.cpu.pc),0x76,'unexpected HALT in work dispatch');
  E.cpu.instruction();E.io.commit();cycles+=E.cpu.vcycles;
 }
 assert.equal(read(E.L.PaceWork),0,'work must be consumed once');
 assert.equal(E.cpu.pc,work>=936?E.L.wvf_ready:E.L.WaitVideoFrame);
 if(work>=936){assert(E.cpu.iff,'IRQ must be enabled');assert.equal(E.cpu.a(),41);}
 cases.push({work,changedIRQ,skipRasterWait:work>=936,dispatchCycles:cycles});
}
// Even all eleven maximum-width descriptors fit the 16-bit accumulator.
assert(231+220+11*(60+32*68+12)<65536);
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),dispatch,cases,strict64KB:true,passed:true};
fs.writeFileSync('outputs/batty-three-plus-one-pacing-dispatch.json',JSON.stringify(result,null,2));console.log(result);
