'use strict';
// Smoke test of real gameplay on magnet levels: the ball is launched and the paddle follows it; brick hits beside
// a magnet mark it and its touched rows are repainted from the cache at once. Checks the stack floor, absence of CPU restarts and
// that no marked magnet is left when the draw phase begins.
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const reports=[];
for(const level of[1,5,13]){
 const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const inst=E.cpu.instruction.bind(E.cpu),w=(a,v)=>E.memory.write(a,v);
 let started=false,frames=0,redraws=0,toggles=0,minSP=65535,bricks0=null,pendingAtDraw=0;
 E.cpu.instruction=function(){const pc=this.pc;
  if(pc===E.L.LB9E8_1&&!started)w(E.L.current_level_number_1up,level);
  if(pc===E.L.LB9E8_2){started=true;frames++;if(bricks0===null)bricks0=E.rd(E.L.briks_quantity_1up);w(E.L.lives_1up,5);
   // keep the paddle under the first ball; hold fire
   const bx=E.rd(E.L.object_ball_1+2),px=E.rd(E.L.object_bat_1+2)+12;E.key(37,bx<px-2?1:0);E.key(39,bx>px+2?1:0);E.key(32,frames%20<10?1:0);
   if(frames>=2500)throw 'done';}
  if(pc===E.L.MagnetPaint)redraws++;if(pc===E.L.MagnetPaintFull)redraws--;if(pc===E.L.print_one_magnet)toggles++;
  if(pc===E.L.GameplayDrawBegin)pendingAtDraw+=[0,1,2,3].filter(i=>E.rd(E.L.MagnetRedrawFlags+i)).length;
  if(started){assert(pc!==0x100,'CPU restart');if(this.sp<minSP&&this.sp>0x6b00&&this.sp<=E.L.stack)minSP=this.sp;}
  inst();};
 try{for(let f=0;f<40000;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='done')throw e;}
 assert(frames>=2500,'gameplay did not run');assert(minSP>=E.L.StackFloor,'stack floor crossed: '+minSP.toString(16));assert.equal(pendingAtDraw,0,'a marked magnet reached the draw phase');
 reports.push({level:level+1,frames,bricksDestroyed:bricks0-E.rd(E.L.briks_quantity_1up),magnetToggles:toggles,repaintsAfterBricks:redraws,minSP:minSP.toString(16)});
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),reports,passed:true};
fs.writeFileSync('outputs/batty-magnet-gameplay.json',JSON.stringify(result,null,2));console.log(JSON.stringify(result,null,1));
