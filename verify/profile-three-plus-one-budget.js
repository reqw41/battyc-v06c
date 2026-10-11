'use strict';
// Exact instruction-cycle profiling. No ROM mutations; same controlled scene as measure-object-speed.js.
const fs=require('fs'),assert=require('assert'),crypto=require('crypto');
const {make}=require('./vector_harness');
const watched=`CGRender CGPrepare CGGroups CGPointers CGIncludeRect CGIntersect CGLoad CGIsolated CGOutside CGOutsideSpan CGCopyPacked CGRestoreVideo CGShadeSaved CGSnapshot CGRestoreSpan CGSaveSpan CGDrawSpan CGCommit CGRestoreWhole SUInvalidate SUSaveObject SUCopySave SUCopyRestore WaitVideoFrame RCBegin planes_begin FastEraseOld FastErasePlain DrawMovingObjects RCFlush RCCompose
 handling_bat handling_ball handling_bonus handling_ufo handling_object call_hl_for_all_obj
 enemy_prepare random_generate get_left_player_ctrl_state fill_briks_data play_sounds_queue
 print_obj_from_buf_to_scr plane_object plane_object_fast SpriteCachePrepare SpriteCacheBuild
 PreparedDraw PreparedCanOverwrite RCRecord running_dot restore_objs_and_magnet pause_game
 LAFFC LAD69 LACF9 hl_bc_calc_direction sprite_search scr_buff_addr_calc ix_buf_addr_calc
 obj_compare check_margins bounce_wall bomb_appear LAA7D LAAD2 NativeReadHL NativeWriteHL
 KEYINT MusicTick SfxTick MonoRender MonoCachePrepare MonoCacheAddress MonoDraw MonoComposeColumn MonoSingleCommit MonoZeroColumn MonoZeroRange MonoSelectCandidates MonoFindIsolated MonoIncludeRegion MonoRegionsIntersect MonoEraseFringes MonoDrawPrepared MonoShiftDraw hl_add_a`.trim().split(/\s+/);
function profile(base,motion='reference') {
 const E=make(base+'/batty.rom',base+'/batty.sym');
 for(const line of fs.readFileSync(base+'/batty0.sym','latin1').split('\n')) {
  const m=line.match(/^(\S+):\s+EQU\s+0x([\da-f]+)/i);if(m&&!(m[1]in E.L))E.L[m[1]]=parseInt(m[2],16);
 }
 E.memory.bytes=E.memory.bytes.slice(0,65536);
 const control=E.memory.control_write.bind(E.memory);E.memory.control_write=v=>{assert.equal(v,0);control(v);};
 const entries=new Map(watched.filter(n=>n in E.L).map(n=>[E.L[n],n]));
 let cycles=0,tick=0,template,frame,stack=[],frames=[],executing=false,videoStore=false,stage='setup';
 const w=(a,v)=>E.memory.write(a,v),put=(o,a)=>a.forEach((v,i)=>w(o+i,v));
 const irq=E.v06c.checkInterrupt.bind(E.v06c);
 E.v06c.checkInterrupt=function(){const accepted=this.irq&&E.cpu.iff;irq();if(accepted&&frame)frame.irqEntryCycles+=16;};
 const write=E.memory.write.bind(E.memory);
 E.memory.write=function(a,v,s) {
  a&=65535;
  if(frame&&executing&&frame.phase==='render') {
   // In the three-plane variant 8000..9fff is hidden code/cache, not visible video.
   const first=E.L.MonoRender?0x8000:0xa000;
   if(a>=first) {
    videoStore=true;
    const plane=(a&0xe000).toString(16);
    const stagePlane=stage+':'+plane;frame.videoByStage[stagePlane]=(frame.videoByStage[stagePlane]||0)+1;
    frame.videoWrites[plane]=(frame.videoWrites[plane]||0)+1;
    const group=renderGroup();frame.writesByGroup[group]=(frame.writesByGroup[group]||0)+1;
    if(stack.some(s=>s.name==='MonoDraw'||s.name==='MonoShiftDraw'))frame.drawAddresses.add(a);
    else if(stage==='restore'&&frame.drawAddresses.has(a))frame.repeatWrites++;
   }
  }
  write(a,v,s);
 };
 function renderGroup() {
  const has=n=>stack.some(s=>s.name===n);
  if(has('KEYINT'))return 'IRQ';
  if(has('SpriteCacheBuild'))return 'SpriteCacheBuild';
  if(has('MonoCachePrepare'))return 'MonoCachePrepare';
  if(has('plane_object_fast'))return 'plane_object_fast';
  if(has('MonoFindIsolated'))return 'MonoFindIsolated';
  if(has('MonoShiftDraw'))return 'MonoShiftDraw';
  if(has('MonoDraw'))return 'MonoDraw';
  if(has('MonoDrawPrepared'))return 'MonoDrawPrepared';
  if(has('MonoSelectCandidates'))return 'MonoSelectCandidates';
  if(has('MonoZeroRange')||has('MonoZeroColumn'))return 'MonoZeroRange';
  if(has('MonoSingleCommit'))return 'MonoSingleCommit';
  if(has('MonoComposeColumn'))return 'MonoComposeColumn';
  if(has('MonoEraseFringes'))return 'MonoEraseFringes';
  if(has('CGRender')) {
   for(const n of ['CGPrepare','CGGroups','CGShadeSaved','CGSnapshot','CGCommit','CGRestoreWhole','CGRestoreVideo','CGDrawSpan'])if(has(n))return n;
   return 'CGRender_control';
  }
  return (E.L.MonoRender?'MonoRender_':'pipeline_')+stage;
 }
  function inject() {
    // A second run removes the benchmark's 7 -> 0 coordinate jump.
    const step=(tick-40)%14;
    const offset=motion==='smooth' ? (step<=7?step:14-step) : tick%8;
    if (!template) template = Array.from({ length: 22 }, (_, i) => E.rd(E.L.object_ball_1 + i));
    for (let i = 0; i < 11; i++) {
      const o = E.L.object_ball_1 + 22 * i;
      if (o !== E.L.object_bat_1) w(o, 0);
    }
    w(E.L.object_bat_1, 1); w(E.L.object_bat_1 + 2, 116 + offset);
    w(E.L.object_bat_1 + 20, 255);
    for (let i = 0; i < 3; i++) {
      const a = template.slice();
      a[0]=2; a[2]=80+50*i+offset; a[3]=0; a[4]=130+10*i; a[5]=0;
      a[6]=8+8*i; a[7]=3; a[18]&=0x7f; a[21]=0;
      put(E.L.object_ball_1+22*i, a);
    }
    w(E.L.balls_quantity, 3);
    const bonus = Array(22).fill(0);
    bonus[0]=4; bonus[2]=55+offset; bonus[4]=112; bonus[8]=2; bonus[9]=8;
    bonus[12]=16; bonus[13]=8; bonus[18]=0xf0; bonus[19]=0x60;
    put(E.L.object_bonus, bonus);
    const enemy = Array(22).fill(0);
    enemy[0]=8; enemy[2]=180+offset; enemy[4]=108; enemy[6]=16; enemy[7]=1;
    enemy[8]=3; enemy[9]=16; enemy[12]=24; enemy[13]=16; enemy[14]=16;
    enemy[18]=0x60; enemy[19]=0x90;
    put(E.L.object_enemy, enemy);
  }

 function finish() {
  assert.equal(stack.length,0,'unclosed: '+stack.map(s=>s.name));
  frame.total=cycles-frame.start;
  assert.equal(Object.values(frame.phases).reduce((a,b)=>a+b,0),frame.total);
  assert.equal(Object.values(frame.routines).reduce((a,b)=>a+b.exclusive,0)+frame.unattributed,frame.total);
  assert.equal(Object.values(frame.render).reduce((a,b)=>a+b,0),frame.phases.render||0);
  frame.drawUniqueAddresses=frame.drawAddresses.size;delete frame.drawAddresses;
  frames.push(frame);
 }
 const instruction=E.cpu.instruction.bind(E.cpu);
 E.cpu.instruction=function() {
  const pc=this.pc;
  if(frame)while(stack.length&&stack.at(-1).ret===pc&&stack.at(-1).sp+2===this.sp) {
   const call=stack.pop();frame.routines[call.name].inclusive+=cycles-call.start;
   if(call.detail)call.detail.cycles=cycles-call.start;
   if(call.name==='WaitVideoFrame')frame.phase='setup';
   if(call.name==='DrawMovingObjects')frame.phase='dots';
  }
  if(pc===E.L.LB9E8_2) {
   tick++;if(tick===21)E.key(32,1);if(tick===31)E.key(32,0);
   if(tick>=40) {
    if(frame)finish();if(tick===105)throw 'done';
    inject();stage='setup';
    frame={tick,shift:tick%8,start:cycles,phase:'logic',phases:{},routines:{},render:{},unattributed:0,cacheBuilds:0,cacheDecisions:{},builds:[],irqEntryCycles:0,
     videoWrites:{},videoByStage:{},videoStoreCycles:0,writesByGroup:{},drawAddresses:new Set(),repeatWrites:0,selectChecks:0,candidateCounts:[],columns:{},stageCycles:{}};
   }
  }
  if(frame) {
   if(pc===E.L.WaitVideoFrame)frame.phase='wait';
   if(pc===E.L.planes_begin)frame.phase='render';
   if(pc===E.L.direct_dots_done)frame.phase='tail';
   if(pc===E.L.MonoRender)stage='prepare';
   if(pc===E.L.mono_draw_all)stage='draw';
   if(pc===E.L.mono_erase_all)stage='restore';
   if(pc===E.L.mono_copy_old)stage='copy';
   if(pc===E.L.mono_select)frame.selectChecks++;
   if(pc===E.L.mono_old_column){const n=E.rd(E.L.MonoCandidateCount);frame.columns[n]=(frame.columns[n]||0)+1;}
   if(pc===E.L.MonoComposeColumn)frame.candidateCounts.push(E.rd(E.L.MonoCandidateCount));
   const name=entries.get(pc);
   if(name) {
    const ret=E.rd(this.sp)+256*E.rd(this.sp+1);
    const stat=frame.routines[name]||={calls:0,inclusive:0,exclusive:0};stat.calls++;
    stack.push({name,ret,sp:this.sp,start:cycles});
    if(name==='MonoCachePrepare') {
     const source=E.rd(E.L.direct_source)+256*E.rd(E.L.direct_source+1)-2;
     const shift=E.rd(E.L.direct_shift),height=E.rd(E.L.direct_rows),owner=E.rd(E.L.MonoOwner),tag=E.L.MonoTags+owner*4;
     const kind=E.rd(E.rd(E.L.IXobj)+256*E.rd(E.L.IXobj+1));
     let reason;
     if(kind!==3&&shift===0&&height===E.rd(source+1))reason='direct_ROM';
     else if(source!==E.rd(tag)+256*E.rd(tag+1))reason='source_miss';
     else if(shift!==E.rd(tag+2))reason='shift_miss';
     else if(height!==E.rd(tag+3))reason='height_miss';
     else reason='hit';
     frame.cacheDecisions[reason]=(frame.cacheDecisions[reason]||0)+1;
    }
    if(name==='SpriteCacheBuild') {
     frame.cacheBuilds++;
     const detail={owner:E.L.MonoOwner?E.rd(E.L.MonoOwner):E.rd(E.L.SpriteCacheIndex),kind:E.rd(E.rd(E.L.IXobj)+256*E.rd(E.L.IXobj+1)),shift:E.rd(E.L.SpriteCacheShift),height:E.rd(E.L.SpriteCacheHeight)};
     frame.builds.push(detail);stack.at(-1).detail=detail;
    }
   }
  }
  const group=frame&&frame.phase==='render'?renderGroup():null;
  videoStore=false;executing=true;instruction();executing=false;
  const c=this.vcycles;
  if(frame) {
   frame.phases[frame.phase]=(frame.phases[frame.phase]||0)+c;
   if(stack.length)frame.routines[stack.at(-1).name].exclusive+=c;else frame.unattributed+=c;
   if(videoStore)frame.videoStoreCycles+=c;
   if(group){frame.render[group]=(frame.render[group]||0)+c;frame.stageCycles[stage]=(frame.stageCycles[stage]||0)+c;}
  }
  cycles+=c;
 };
 try{for(let f=0;f<1800;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='done')throw e;}
 assert.equal(frames.length,65);
 const warm=frames.slice(20);
 const ref=JSON.parse(fs.readFileSync(base+'/outputs/'+(E.L.MonoRender?(process.env.BATTY_MONO_REFERENCE||'batty-three-plus-one-speed.json'):'batty-local-speed.json')));
 const hash=crypto.createHash('sha256').update(fs.readFileSync(base+'/batty.rom')).digest('hex');
 assert.equal(hash,ref.romSHA256);
 const avg=warm.reduce((s,f)=>s+f.total/warm.length,0);
 if(motion==='reference')assert(Math.abs(avg/3000-ref.reports.find(r=>r.name==='three_balls_bonus_enemy').warmMeanMs)<1e-8,'timing differs from speed bench');
 function aggregate(list) {
  const out={steps:list.length,total:0,irqEntryCycles:0,phases:{},render:{},stageCycles:{},routines:{},videoWrites:{},videoByStage:{},videoStoreCycles:0,writesByGroup:{},cacheBuilds:0,cacheDecisions:{},buildsByKind:{},repeatWrites:0,drawUniqueAddresses:0,selectChecks:0,columns:{}};
  for(const f of list) {
   for(const n of ['videoStoreCycles','total','irqEntryCycles','cacheBuilds','repeatWrites','drawUniqueAddresses','selectChecks'])out[n]+=f[n]/list.length;
   for(const b of ['phases','render','stageCycles','videoWrites','videoByStage','cacheDecisions','writesByGroup','columns'])for(const[n,c]of Object.entries(f[b]))out[b][n]=(out[b][n]||0)+c/list.length;
   for(const[n,c]of Object.entries(f.routines)){const r=out.routines[n]||={calls:0,inclusive:0,exclusive:0};for(const k of ['calls','inclusive','exclusive'])r[k]+=c[k]/list.length;}
   for(const b of f.builds){const r=out.buildsByKind[b.kind]||={calls:0,cycles:0};r.calls+=1/list.length;r.cycles+=b.cycles/list.length;}
  }
  out.routines=Object.fromEntries(Object.entries(out.routines).sort((a,b)=>b[1].exclusive-a[1].exclusive));
  out.modeledTotal=out.total+out.irqEntryCycles;
  return out;
 }
 const worst=warm.reduce((a,b)=>a.total>b.total?a:b);
 return {base,motion,romSHA256:hash,warm:aggregate(warm),warmWorst:aggregate([worst]),worstTick:worst.tick,all:aggregate(frames),frames};
}
const reports=['reference','smooth'].flatMap(m=>['.','../vector06c-batty-three-plane'].map(b=>profile(b,m)));
const result={cpu:'i8080 3 MHz, vanilla 64 KB; Vector machine cycles from cpu.vcycles (bus-synchronized timings), not bare nominal cpu_cycles',method:'Same injection as measure-object-speed.js: 65 steps, 45 warm. Paddle, 3 balls, bonus, UFO. Reference offset=tick%8; smooth offset=0..7..0. No forced impacts. Instruction cycles charged to exactly one main phase and one renderer group. Renderer groups are mutually exclusive; they include helper calls, with separately listed children and IRQ removed. MonoSingleCommit excludes its MonoZeroRange fringe calls. Routine inclusive/exclusive costs are reported separately. IRQ entry (16 cycles) outside instruction() is separate. Frame budget 119808 cycles.',reports};
fs.writeFileSync(process.env.BATTY_BUDGET_OUT||'outputs/batty-three-plus-one-budget.json',JSON.stringify(result,null,2));
for(const r of reports)console.log(JSON.stringify({base:r.base,motion:r.motion,warm:r.warm,worst:r.warmWorst.total},null,2));
