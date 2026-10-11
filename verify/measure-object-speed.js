"use strict";
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const p=process.env.BATTY_BENCH_BASE||'.',reports=[];
for(const sc of [{name:'one_ball',balls:1},{name:'ball_bonus',balls:1,bonus:true},{name:'ball_ufo',balls:1,enemy:8},{name:'ball_bird',balls:1,enemy:9},{name:'three_balls',balls:3},{name:'three_balls_bonus_enemy',balls:3,bonus:true,enemy:8},{name:'three_balls_enemy_bomb',balls:3,bonus:true,bonusFrame:10,enemy:8},{name:'wide_transform',balls:3,bonus:true,enemy:8,resize:true}]){
 if(process.env.BATTY_BENCH_SCENE&&process.env.BATTY_BENCH_SCENE!==sc.name)continue;
 const E=make(p+'/batty.rom',p+'/batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);
 const control=E.memory.control_write.bind(E.memory);E.memory.control_write=v=>{assert.equal(v,0,'RAM disk mapping');control(v);};
 const legacyDraw=process.env.BATTY_BENCH_DRAW_ANCHOR==='1'&&!E.L.GameplayDrawBegin;
 if(legacyDraw)assert.equal(E.rd(E.L.LBAED_5),0xcd,'legacy wait must be CALL');
 const anchor=E.L.GameplayDrawBegin||(legacyDraw?E.L.LBAED_5+3:E.L.LB9E8_2),waitEntry=E.L.WaitGameplayFrame||E.L.WaitVideoFrame;
 let cacheBuilds=0,warmCacheBuilds=0,t=0,tick=0,start=null,drawStart=0,handleStart=null,lastDraw=0,lastHandle=0,template,frames=[],waitCycles=0,waitStart=null,waitReturn=null,irqCycles=0;
 const w=(a,v)=>E.memory.write(a,v),put=(o,a)=>a.forEach((v,i)=>w(o+i,v));
 const irq=E.v06c.checkInterrupt.bind(E.v06c);E.v06c.checkInterrupt=function(){const accepted=this.irq&&E.cpu.iff;irq();if(accepted&&start!==null)irqCycles+=16;};
 const orig=E.cpu.instruction.bind(E.cpu);E.cpu.instruction=function(){
  const pc=this.pc;
  if(E.L.StackFloor&&this.sp>=0x6900&&this.sp<=E.L.stack)assert(this.sp>=E.L.StackFloor,'stack crosses reserved RAM');
  if(pc===E.L.SpriteCacheBuild){cacheBuilds++;if(tick>=60)warmCacheBuilds++;}
  if(waitStart!==null&&pc===waitReturn){waitCycles+=t-waitStart;waitStart=null;waitReturn=null;}
  if(pc===E.L.LB9E8_2){tick++;if(tick===21)E.key(32,1);if(tick===31)E.key(32,0);if(tick>=40){
if(!template)template=Array.from({length:22},(_,i)=>E.rd(E.L.object_ball_1+i));for(let i=0;i<11;i++){if(E.L.object_ball_1+22*i!==E.L.object_bat_1)w(E.L.object_ball_1+22*i,0);}w(E.L.object_bat_1,1);w(E.L.object_bat_1+2,116+(tick%8));for(let i=0;i<sc.balls;i++){let a=template.slice();a[0]=2;a[2]=80+50*i+(tick%8);a[3]=0;a[4]=130+10*i;a[5]=0;a[6]=8+8*i;a[7]=3;a[18]&=0x7f;a[21]=0;put(E.L.object_ball_1+22*i,a);}w(E.L.balls_quantity,sc.balls);w(E.L.object_bat_1+20,255);if(sc.resize){w(E.L.object_bat_1+1,2);w(E.L.object_bat_1+21,0x24);w(E.L.object_bat_1+12,36);const b=Array(22).fill(0);b[0]=1;b[1]=3;b[2]=132;b[4]=173;b[8]=3;b[9]=10;b[12]=24;b[13]=10;put(E.L.object_bat_temp,b);}if(sc.bonus){let a=Array(22).fill(0);a[0]=4;a[1]=sc.bonusFrame||0;a[2]=55+(tick%8);a[4]=112;a[8]=2;a[9]=8;a[12]=16;a[13]=8;a[18]=0xf0;a[19]=0x60;put(E.L.object_bonus,a);}if(sc.enemy){let a=Array(22).fill(0);a[0]=sc.enemy;a[2]=180+(tick%8);a[4]=108;a[6]=16;a[7]=1;a[8]=3;a[9]=sc.enemy===8?16:12;a[12]=24;a[13]=a[9];a[14]=16;a[18]=sc.enemy===8?0x60:0xf0;a[19]=sc.enemy===8?0x90:0x70;put(E.L.object_enemy,a);}
   handleStart=t;
  }}
  if(pc===anchor&&tick>=40){
   if(start!==null)frames.push({ms:(t-start)/3000,machineMs:(t-start+irqCycles)/3000,irqEntryCycles:irqCycles,activeMs:(t-start-waitCycles)/3000,waitMs:waitCycles/3000,renderMs:lastDraw/3000,logicMs:lastHandle/3000});
   if(frames.length===65)throw 'done';
   start=t;lastHandle=lastDraw=0;waitCycles=irqCycles=0;waitStart=waitReturn=null;handleStart=anchor===E.L.LB9E8_2?t:null;
  }
  if(start!==null){
   if(pc===E.L.GameplayLogicDone&&handleStart!==null){lastHandle=t-handleStart;handleStart=null;}
   if(pc===waitEntry){waitStart=t;waitReturn=E.rd(this.sp)+256*E.rd(this.sp+1);if(handleStart!==null)lastHandle=t-handleStart;}
   if(pc===E.L.planes_begin)drawStart=t;
   if(pc===E.L.direct_dots_done)lastDraw=t-drawStart;
  }
  orig();t+=this.vcycles;
 };
 try{for(let f=0;f<1800;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='done')throw e;}
 assert.equal(frames.length,65,sc.name);if(process.env.BATTY_REQUIRE_25==='1'){assert(Math.max(...frames.map(r=>r.machineMs))<=119808/3000+0.02,sc.name+' exceeds two rasters');if(process.env.BATTY_REQUIRE_FIXED25==='1'&&sc.name==='three_balls_bonus_enemy'&&E.L.GameplayDrawBegin)assert(frames.slice(20).every(r=>Math.abs(r.machineMs-119808/3000)<=0.02),'heavy cadence is not two rasters');}
 const avg=(list,k)=>list.reduce((s,r)=>s+r[k],0)/list.length,warm=frames.slice(20);
 reports.push({...sc,worstFrame:frames.reduce((a,b)=>a.machineMs>b.machineMs?a:b),cacheBuilds,warmCacheBuilds,steps:65,warmMeanMs:avg(warm,'ms'),meanMs:avg(frames,'ms'),activeMs:avg(frames,'activeMs'),waitMs:avg(frames,'waitMs'),warmActiveMs:avg(warm,'activeMs'),stepsPerSecond:1000/avg(frames,'ms'),renderMs:avg(frames,'renderMs'),logicMs:avg(frames,'logicMs'),minMs:Math.min(...frames.map(r=>r.ms)),maxMs:Math.max(...frames.map(r=>r.ms)),warmMaxMs:Math.max(...warm.map(r=>r.ms)),warmMachineMeanMs:avg(warm,'machineMs'),warmMachineMaxMs:Math.max(...warm.map(r=>r.machineMs)),warmMachineMinMs:Math.min(...warm.map(r=>r.machineMs)),maxMachineMs:Math.max(...frames.map(r=>r.machineMs)),warmOverBudget: warm.filter(r=>r.machineMs>119808/3000+0.02).length});
}
fs.writeFileSync(process.env.BATTY_BENCH_OUT||'outputs/batty-vector-matched-object-speed.json',JSON.stringify({romSHA256:crypto.createHash('sha256').update(fs.readFileSync(p+'/batty.rom')).digest('hex'),cpu:'i8080 3 MHz, 64 KB',method:'65 controlled moving steps; positions injected at the unchanged logic entry before handling; actual native logic and rendering run. Frame timing starts at GameplayDrawBegin when present; legacy ROM uses LB9E8_2, or the instruction after its normal wait CALL with BATTY_BENCH_DRAW_ANCHOR=1. IRQ entry is reported separately in machineMs; activeMs excludes the complete gameplay wait call. 25 Hz budget: 119808 cycles, cadence tolerance 0.02 ms for IRQ/instruction boundary jitter.',reports},null,2));console.log(reports);
