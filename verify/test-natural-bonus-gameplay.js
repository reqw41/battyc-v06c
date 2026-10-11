const {make}=require('./vector_harness'),assert=require('assert'),fs=require('fs');
const root=process.argv[2]||'.',E=make(root+'/batty.rom',root+'/batty.sym');
const romSHA256=require('crypto').createHash('sha256').update(fs.readFileSync(root+'/batty.rom')).digest('hex');
const frameLimit=Number(process.env.BATTY_GAMEPLAY_FRAMES||6000);
const startFrame=Number(process.env.BATTY_GAMEPLAY_START_FRAME||100);
E.memory.bytes=E.memory.bytes.slice(0,65536);
const w=(a,v)=>E.memory.bytes[E.memory.tobank(a&65535)]=v,inst=E.cpu.instruction.bind(E.cpu);
let ticks=0,frame=0,launchTick=0,lastBonus=0,enemySeen=false,bombsSeen=0,created=[],caught=[],started=false;
const cadenceOut=process.env.BATTY_GAMEPLAY_CADENCE_OUT;
let machineCycles=0,draw=null,transition=false,phase='setup',periods=[];
const watched=new Map(['print_one_magnet','get_left_player_ctrl_state','enemy_prepare','random_generate','handling_bat','call_hl_for_all_obj','fill_briks_data','play_sounds_queue','MonoComposeColumn','MonoSelectCandidates','SpriteCacheBuild','MonoDrawPrepared'].filter(n=>n in E.L).map(n=>[E.L[n],n]));
let calls=[];
if(cadenceOut){
 assert(E.L.GameplayDrawBegin,'draw-start label required');
 const irq=E.v06c.checkInterrupt.bind(E.v06c);
 E.v06c.checkInterrupt=function(){const accepted=this.irq&&E.cpu.iff;irq();if(accepted){machineCycles+=16;if(draw)draw.phases[phase]=(draw.phases[phase]||0)+16;}};
}
E.cpu.instruction=function(){if(E.L.StackFloor&&this.sp>=0x6900&&this.sp<=E.L.stack)assert(this.sp>=E.L.StackFloor,'stack reaches classifier code');
 if(cadenceOut){
  const pc=this.pc;
  while(calls.length&&calls.at(-1).ret===pc&&calls.at(-1).sp+2===this.sp){const c=calls.pop(),r=draw.routines[c.name]||={calls:0,inclusiveCycles:0};r.calls++;r.inclusiveCycles+=machineCycles-c.start;}
  if([E.L.show_window_round_number,E.L.planes_reset,E.L.SparksRender,E.L.pause_game_0].includes(pc))transition=true;
  if(pc===E.L.GameplayDrawBegin){
   assert.equal(calls.length,0,'unfinished native profile call');
   if(draw&&!transition){draw.cycles=machineCycles-draw.start;delete draw.start;assert.equal(Object.values(draw.phases).reduce((a,b)=>a+b,0),draw.cycles);periods.push(draw);}
   draw={start:machineCycles,tick:ticks,frame,phases:{},routines:{},objects:Array.from({length:11},(_,i)=>[E.rd(E.L.object_ball_1+22*i),E.rd(E.L.object_ball_1+22*i+1)])};transition=false;phase='setup';
  }
  if(pc===E.L.LB9E8_2)phase='logic';
  if(pc===E.L.WaitGameplayFrame){phase='wait';if(draw)draw.workBoundCycles=64*(E.rd(E.L.PaceWork)+256*E.rd(E.L.PaceWork+1));}
  if(pc===E.L.planes_begin)phase='render';
  if(pc===E.L.GameplayDrawBegin+9)phase='dots';
  if(pc===E.L.direct_dots_done)phase='tail';
  if(draw&&watched.has(pc))calls.push({name:watched.get(pc),ret:E.rd(this.sp)+256*E.rd(this.sp+1),sp:this.sp,start:machineCycles});
 }
 if(started){assert(this.pc<0x8000||(E.L.CGCodeBegin&&this.pc>=E.L.CGCodeBegin&&this.pc<E.L.CGCode1End)||(E.L.CGCode2Begin&&this.pc>=E.L.CGCode2Begin&&this.pc<E.L.CGCodeEnd),'execution escaped into video RAM');assert(this.pc!==0&&this.pc!==256&&this.pc!==E.L.start_bin,'unexpected CPU restart');}
 if(this.pc===E.L.LB9E8_2){
  ticks++;started=true;
  for(const o of [E.L.object_ball_1,E.L.object_ball_2,E.L.object_ball_3])assert([0,2,128,130].includes(E.rd(o)),'ball type corrupted');
  const bonus=E.rd(E.L.object_bonus),id=E.rd(E.L.object_bonus+1),y=E.rd(E.L.object_bonus+4);
  const x=bonus===4&&id!==10&&y>145?E.rd(E.L.object_bonus+2)+8:E.rd(E.L.object_ball_1+2);
  w(E.L.object_bat_1+2,Math.max(8,Math.min(220,x-12)));
  if(E.rd(E.L.object_ball_1+20)===0xc0||ticks===21){E.key(32,1);launchTick=ticks;}
  if(ticks===launchTick+10)E.key(32,0);
  if(bonus!==lastBonus){if(bonus===4){if(id===10)bombsSeen++;else{assert(id<10);created.push({frame,id});}}if(bonus===11)caught.push({frame,id:E.rd(E.L.object_bonus+20)});lastBonus=bonus;}
  enemySeen ||= E.rd(E.L.object_enemy)!==0;
 }
 inst();if(cadenceOut){machineCycles+=this.vcycles;if(draw)draw.phases[phase]=(draw.phases[phase]||0)+this.vcycles;}
};
for(frame=0;frame<frameLimit;frame++){if(frame===startFrame)E.key(48,1);if(frame===startFrame+10)E.key(48,0);E.run(1);}
if(cadenceOut){
 assert(periods.length>0,'no normal gameplay intervals sampled');
 const sorted=periods.map(p=>p.cycles).sort((a,b)=>a-b),over=periods.filter(p=>p.cycles>119868);
 const cadence={romSHA256,frames:frameLimit,startFrame,ticks,method:'Native autoplay; draw-to-draw synchronized cycles including IRQ entry. Intervals containing a round window, full plane reset, death sparks or actual keyboard pause are excluded. Brick hits, enemies and bonus effects remain. No random-bonus coverage assertion is implied by this timing report.',samples:periods.length,meanCycles:sorted.reduce((a,b)=>a+b,0)/sorted.length,p99Cycles:sorted[Math.floor(sorted.length*.99)],maxCycles:sorted.at(-1),overBudget:over.length,worst:over.sort((a,b)=>b.cycles-a.cycles).slice(0,20)};
 fs.writeFileSync(cadenceOut,JSON.stringify(cadence,null,2));console.log(cadence);
}
console.log({ticks,created,caught,enemySeen,bombsSeen}); assert(created.length>=4&&caught.length>=3);assert(created.some(v=>v.id===4));if(process.env.BATTY_GAMEPLAY_REQUIRE_SMASH!=='0')assert(caught.some(v=>v.id===7));assert(enemySeen&&bombsSeen>0);
const result={romSHA256,frames:frameLimit,startFrame,ticks,naturalBonuses:created,pickedBonuses:caught,enemySeen,bombsSeen,unexpectedResets:0,physicalRAM:65536,naturalSmashObserved:caught.some(v=>v.id===7),requiredNaturalSmash:process.env.BATTY_GAMEPLAY_REQUIRE_SMASH!=='0',passed:true};
console.log(result);if(process.env.BATTY_GAMEPLAY_OUT||!process.argv[2])fs.writeFileSync(process.env.BATTY_GAMEPLAY_OUT||'outputs/batty-natural-bonus-verification.json',JSON.stringify(result,null,2));
