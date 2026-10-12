'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const runs=Number(process.env.BATTY_HEAVY_RUNS||6),limit=Number(process.env.BATTY_HEAVY_RASTERS||700),reports=[],periods=[],rasterSamples=[];
for(let run=0;run<runs;run++){
 const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const inst=E.cpu.instruction.bind(E.cpu),w=(a,v)=>E.memory.write(a,v),word=a=>E.rd(a)+256*E.rd(a+1),ptr=(a,v)=>{w(a,v);w(a+1,v>>8)};
 let ready=false;E.cpu.instruction=function(){if(this.pc===E.L.LB9E8_2){ready=true;throw 'ready';}inst();};const start=100+37*run;try{for(let f=0;f<1000;f++){if(f===start)E.key(48,1);if(f===start+10)E.key(48,0);E.run(1);}}catch(e){if(e!=='ready')throw e;}assert(ready);E.key(48,0);E.cpu.instruction=inst;
 const saved={pc:E.cpu.pc,sp:E.cpu.sp,iff:E.cpu.iff,stack:E.memory.bytes.slice(E.L.StackFloor,E.L.stack)};function call(n){E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;ptr(E.cpu.sp,256);E.cpu.iff=false;for(let i=0;E.cpu.pc!==256;i++){assert(i<1e6,n);inst();E.io.commit();}}
 // One-time fixture: native ball release, native catch of Triple then Smash,
 // and normal enemy creation by game rules. No position/state reinjection during gameplay.
 ptr(E.L.IXobj,E.L.object_ball_1);w(E.L.ctrl_btns_pressed,16);call('handling_ball');
 const bonus=E.L.object_bonus,bat=E.L.object_bat_1;
 for(const id of[2,7]){const a=Array(22).fill(0);a[0]=4;a[1]=id;a[2]=E.rd(bat+2)+6;a[4]=E.rd(bat+4)-3;a[8]=2;a[9]=8;a[12]=16;a[13]=8;a[20]=id;a.forEach((v,i)=>w(bonus+i,v));ptr(E.L.IXobj,bonus);call('get_bonus');assert.equal(E.rd(bonus),11,'native bonus not caught');}
 assert.equal(E.rd(E.L.balls_quantity),3);assert.equal(E.rd(bat+20),7);
 // Enemy appearance and shooting now follow the normal brick-count gate.
 E.memory.bytes.set(saved.stack,E.L.StackFloor);
 E.cpu.pc=saved.pc;E.cpu.sp=saved.sp;E.cpu.iff=saved.iff;
 let cycles=0,ticks=0,frame=0,draw=null,phase='tail',transition=false,shots=0,brickEvents=0,smashFrames=0,allThreeFrames=0,prevY=new Map(),poses=new Map(),poseHistory=new Map(),bestScreen=null,bestTargets=null,recording=0,captureCount=0;
 const irq=E.v06c.checkInterrupt.bind(E.v06c);E.v06c.checkInterrupt=function(){const accepted=this.irq&&E.cpu.iff;irq();if(accepted){cycles+=16;if(draw)draw[phase]=(draw[phase]||0)+16;}};
 const state=()=>({balls:[1,2,3].filter(i=>E.rd(E.L['object_ball_'+i])===2).length,smash:E.rd(bat+20)===7,enemy:E.rd(E.L.object_enemy),bomb:E.rd(bonus)===4&&E.rd(bonus+1)===10,bricks:E.rd(E.L.briks_quantity_1up)});
 function pose(owner){const base=word(E.L.mono_old_base+1)+owner*7,width=E.rd(base+2),rows=E.rd(base+3),src=word(base+4),video=word(base);if(!width||!rows)return null;const isolated=E.rd(E.L.MonoRegions+owner*5+4),shift=isolated?E.rd(E.L.MonoShifts+owner):0,pitch=isolated?E.rd(src-1):rows,sourceCols=isolated?E.rd(src-2):width,pixels=[];
  for(let c=0;c<sourceCols;c++)for(let r=0;r<rows;r++){const lit=E.rd(src+1+2*(c*pitch+r));for(let b=0;b<8;b++)if(lit&(128>>b)){const x=((video>>8)-128+c)*8+b+shift,lo=((video&255)-r)&255,y=16+((E.rd(E.L.ScreenScroll)-lo)&255);if(x>=0&&x<256&&y>=16&&y<272)pixels.push(y*576+32+x*2);}}
  return pixels.length?{frame,cycles,pixels}:null;
 }
 E.cpu.instruction=function(){const pc=this.pc;
  while(calls.length&&calls.at(-1).ret===pc&&calls.at(-1).sp+2===this.sp){const c=calls.pop();if(c.owner){const r=c.owner.routines[c.name]||={calls:0,cycles:0};r.calls++;r.cycles+=cycles-c.start;}}
  if(draw&&watched.has(pc))calls.push({name:watched.get(pc),ret:word(this.sp),sp:this.sp,start:cycles,owner:draw});
  if(this.sp>=0x6900&&this.sp<=E.L.stack)assert(this.sp>=E.L.StackFloor);assert(pc<32768,'executing video');assert(pc!==0&&pc!==256&&pc!==E.L.start_bin,'unexpected restart');
  if(pc===E.L.LB9E8_2){ticks++;phase='logic';const candidates=[1,2,3].map(i=>E.L['object_ball_'+i]).filter(o=>E.rd(o)===2);let target=candidates[0],best=Infinity;
   for(const o of candidates){const y=E.rd(o+4),last=prevY.get(o)||{x:E.rd(o+2),y:y-1},dy=y-last.y,dx=E.rd(o+2)-last.x;prevY.set(o,{x:E.rd(o+2),y});if(dy>0){const eta=(174-y)/dy;if(eta<best){best=eta;target=o;}}}
   const tx=target?E.rd(target+2)+4:128,bx=E.rd(bat+2)+E.rd(bat+12)/2;E.key(37,tx<bx-3);E.key(39,tx>bx+3);E.key(32,!!candidates.find(o=>E.rd(o+20)>0));
  }
  if([E.L.show_window_round_number,E.L.planes_reset,E.L.SparksRender,E.L.pause_game_0].includes(pc))transition=true;
  if(pc===E.L.GameplayDrawBegin){const now=state();if(draw&&!transition){draw.cycles=cycles-draw.start;assert.equal(draw.logic+draw.render+draw.wait+draw.tail,draw.cycles);draw.end=now;delete draw.start;periods.push(draw);}draw={run,tick:ticks,frame,start:cycles,state:now,logic:0,render:0,wait:0,tail:0,routines:{}};phase='render';transition=false;}
  if(pc===E.L.WaitGameplayFrame)phase='wait';if(pc===E.L.direct_dots_done){phase='tail';for(const [name,owner]of[['ball1',1],['ball2',2],['ball3',3],['enemy',9],['bomb',0]]){const s=state(),active=name==='enemy'?[8,9].includes(s.enemy):name==='bomb'?s.bomb:E.rd(E.L['object_ball_'+name.at(-1)])===2;if(!active){poses.delete(name);continue;}const p=pose(owner);if(p){const hist=poseHistory.get(name)||[];hist.push(p);poseHistory.set(name,hist);const list=poses.get(name)||[];list.push(p);poses.set(name,list.slice(-3));}}}
  if(pc===E.L.bomb_appear){const ret=word(this.sp);pendingShots.push({ret,was:E.rd(bonus)});}if(pendingShots.length&&pendingShots.at(-1).ret===pc){const p=pendingShots.pop();if(!p.was&&E.rd(bonus)===4&&E.rd(bonus+1)===10)shots++;}
  if(pc===E.L.fill_briks_data)brickEvents++;
  inst();cycles+=this.vcycles;if(draw)draw[phase]+=this.vcycles;
 };
 const pendingShots=[];
 const calls=[],watched=new Map(['DrawMovingObjects','handling_ball','handling_ufo','handling_bird','NativeRestoreBrick','NativePrintBrick','fill_briks_data','play_sounds_queue','restore_objs_and_magnet','running_dot'].map(n=>[E.L[n],n]));
 for(frame=0;frame<limit;frame++){E.run(1);const s=state();if(s.smash)smashFrames++;if(s.balls===3)allThreeFrames++;
    if(recording>0){fs.mkdirSync('outputs/natural-heavy-frames',{recursive:true});E.png('outputs/natural-heavy-frames/run'+run+'-'+String(captureCount++).padStart(3,'0')+'.png');recording--;}
  if(s.balls!==3||!s.smash||![8,9].includes(s.enemy)||frame<6)continue;
  const white=E.io.Palette[8]>>>0,sample={run,frame,bomb:s.bomb,targets:{}};
  for(const[name,list]of poses){if(name==='bomb'&&!s.bomb)continue;const eligible=list.filter(p=>frame-p.frame<=5);if(!eligible.length)continue;let best=0;for(const p of eligible){const n=p.pixels.reduce((n,i)=>n+((E.v06c.bmp[i]>>>0)===white),0);best=Math.max(best,n/p.pixels.length);}sample.targets[name]=best;}
  sample.white=Buffer.alloc(Math.ceil(E.v06c.bmp.length/8));for(let i=0;i<E.v06c.bmp.length;i++)if((E.v06c.bmp[i]>>>0)===white)sample.white[i>>3]|=1<<(i&7);rasterSamples.push(sample);if(s.bomb&&bestScreen===null){recording=64;bestScreen=Uint32Array.from(E.v06c.bmp);bestTargets=sample;E.pngFrom(bestScreen,'outputs/batty-natural-heavy-run'+run+'-raster.png');E.pngFrom(E.idealBmp(),'outputs/batty-natural-heavy-run'+run+'-memory.png');}

 }
 // Offline lookahead includes the next completed pose, avoiding false partial
 // reports when a raster finishes while the native renderer is still running.
 for(const sample of rasterSamples.filter(s=>s.run===run)){for(const name of Object.keys(sample.targets)){const hist=(poseHistory.get(name)||[]).filter(p=>p.frame>=sample.frame-5&&p.frame<=sample.frame+3);let best=0;for(const p of hist){const n=p.pixels.reduce((n,i)=>n+!!(sample.white[i>>3]&(1<<(i&7))),0);best=Math.max(best,n/p.pixels.length);}sample.targets[name]=best;}delete sample.white;}
 reports.push({run,initialSP:saved.sp,captureCount,startFrame:start,ticks,shots,smashRasterFrames:smashFrames,threeBallRasterFrames:allThreeFrames,heavyRasterSamples:rasterSamples.filter(r=>r.run===run).length,bestTargets,finalState:state()});console.log(reports.at(-1));
}
const heavy=periods.filter(p=>p.state.balls===3&&p.state.smash&&[8,9].includes(p.state.enemy)&&p.end.balls===3&&p.end.smash&&[8,9].includes(p.end.enemy)),shotFrames=heavy.filter(p=>p.state.bomb||p.end.bomb),stats=a=>{const v=a.map(p=>p.cycles).sort((a,b)=>a-b);return{samples:a.length,minCycles:v[0],meanCycles:v.reduce((a,b)=>a+b,0)/v.length,p99Cycles:v[Math.floor(v.length*.99)],maxCycles:v.at(-1),over40ms:a.filter(p=>p.cycles>120000).length,overTwoRasters:a.filter(p=>p.cycles>119868).length};};
const flicker={};for(const name of['ball1','ball2','ball3','enemy','bomb']){const a=rasterSamples.filter(s=>name in s.targets).map(s=>s.targets[name]);flicker[name]={samples:a.length,blankFrames:a.filter(v=>v===0).length,partialFrames:a.filter(v=>v>0&&v<1).length,minBestPoseCoverage:Math.min(...a),meanBestPoseCoverage:a.reduce((a,b)=>a+b,0)/a.length};}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),cpu:'i8080 3MHz, physical64KB',method:'One-time native release/catch of Triple and Smash with enemy appearance governed by the normal brick-count gate. Thereafter only arrow/Space input; positions, timers, random values and shots are not reinjected. Natural motion, brick hits, enemy shots, audio, IRQ and raster run normally. Timing is draw-to-draw including IRQ entries; transitions are excluded. Raster compares completed poses from the preceding five and following three raster intervals, including lookahead when the renderer was in progress; partial images can mean tearing or motion, blank images mean disappearance within the tracked pose window. This metric is not a proof of tear-free output.',reports,heavy:stats(heavy),heavyWithBomb:stats(shotFrames),worst:heavy.sort((a,b)=>b.cycles-a.cycles).slice(0,12),flicker};fs.writeFileSync('outputs/batty-natural-heavy.json',JSON.stringify(result,null,2));console.log(JSON.stringify({heavy:result.heavy,heavyWithBomb:result.heavyWithBomb,flicker},null,2));assert(heavy.length&&shotFrames.length,'requested heavy scene was not observed');
