'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const reports=[];
for(const scene of ['normal-locked','g-toggle-loss','l-edge']){
 const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const inst=E.cpu.instruction.bind(E.cpu),w=(a,v)=>E.memory.write(a,v);let ticks=0,ready=false,losses=0,lastLoss=null,finished=false,gRelease=null,lStage=0,lRelease=null,lPress=null,lossResume=null,levels=new Set(),enabled=null;
 E.cpu.instruction=function(){const pc=this.pc;
  if(this.sp>=0x6900&&this.sp<=E.L.stack)assert(this.sp>=E.L.StackFloor);
  if(pc===E.L.live_dec){lastLoss=E.rd(E.L.lives_1up);losses++;assert.equal(E.rd(E.L.live_dec),losses===1?0xb7:0x3d,'G lost/toggled while held');}
  if(pc===E.L.LB9E8_2){ticks++;const level=E.rd(E.L.current_level_number_1up);levels.add(level);
   if(!ready){ready=true;enabled=E.rd(E.L.CheatEnabled);assert.equal(enabled,scene==='normal-locked'?0:1);}
   if(scene==='normal-locked'){
    if(ticks===20){E.key(71,1);E.key(76,1);}if(ticks===60){assert.equal(level,0);assert.equal(E.rd(E.L.live_dec),0x3d);finished=true;throw 'done';}
   }
   if(scene==='g-toggle-loss'){
    if(ticks===20)E.key(71,1);if(ticks===30)E.key(71,0);if(ticks===40){assert.equal(E.rd(E.L.live_dec),0xb7);w(E.L.balls_quantity,0);}
    if(losses===1&&lossResume===null){assert.equal(E.rd(E.L.lives_1up),lastLoss);lossResume=ticks;E.key(71,1);gRelease=ticks+10;}
    if(ticks===gRelease)E.key(71,0);if(lossResume!==null&&ticks===lossResume+20){assert.equal(E.rd(E.L.live_dec),0x3d);w(E.L.balls_quantity,0);}
    if(losses===2){assert.equal(E.rd(E.L.lives_1up),lastLoss-1);finished=true;throw 'done';}
   }
   if(scene==='l-edge'){
    if(ticks===20){E.key(76,1);lStage=1;}
    if(lStage===1&&level===1){lRelease=ticks+25;lStage=2;}
    if(lStage===2){assert.equal(level,1,'held L advanced multiple levels');if(ticks===lRelease){E.key(76,0);lPress=ticks+10;lStage=3;}}
    if(lStage===3&&ticks===lPress){E.key(76,1);lStage=4;}
    if(lStage===4&&level===2){E.key(76,0);finished=true;throw 'done';}
   }
  }
  inst();
 };
 try{for(let frame=0;frame<4000;frame++){
  if(scene==='normal-locked'){if(frame===100)E.key(48,1);if(frame===110)E.key(48,0);}
  else {if(frame===100)E.key(112,1);if(frame===180){assert(!ready,'F1 alone started the game');E.key(114,1);}if(frame===195){E.key(112,0);E.key(114,0);}}
  E.run(1);
 }}catch(e){if(e!=='done')throw e;}
 assert(finished,scene+' unfinished '+JSON.stringify({ticks,ready,losses,lStage,levels:[...levels]}));
 // A normal start must clear the session lock, edge latch and modified life opcode.
 E.cpu.pc=E.L.CheatStartNormal;E.cpu.sp=E.L.stack-2;w(E.cpu.sp,0);w(E.cpu.sp+1,1);E.cpu.iff=false;let n=0;while(E.cpu.pc!==256){assert(++n<200);E.cpu.instruction();E.io.commit();}assert.equal(E.rd(E.L.CheatEnabled),0);assert.equal(E.rd(E.L.CheatKeys),0);assert.equal(E.rd(E.L.live_dec),0x3d);
 reports.push({scene,enabled,ticks,losses,levels:[...levels],normalStartResetsSession:true,passed:true});
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),strict64KB:true,reports,passed:true};fs.writeFileSync('outputs/batty-vector-colors-cheats.json',JSON.stringify(result,null,2));console.log(result);
