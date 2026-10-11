'use strict';
// Instruction-cycle budget; no game code or ROM patching. Matches measure-object-speed.js.
const fs = require('fs'), assert = require('assert'), crypto = require('crypto');
const { make } = require('./vector_harness');
const watched = `SUInvalidate SUSaveObject SUCopySave SUCopyRestore WaitVideoFrame RCBegin planes_begin FastEraseOld FastErasePlain DrawMovingObjects RCFlush RCCompose
 handling_bat handling_ball handling_bonus handling_ufo handling_object call_hl_for_all_obj
 enemy_prepare random_generate get_left_player_ctrl_state fill_briks_data play_sounds_queue
 print_obj_from_buf_to_scr plane_object plane_object_fast SpriteCachePrepare SpriteCacheBuild
 PreparedDraw PreparedCanOverwrite RCRecord running_dot restore_objs_and_magnet pause_game
 LAFFC LAD69 LACF9 hl_bc_calc_direction sprite_search scr_buff_addr_calc ix_buf_addr_calc
 obj_compare check_margins bounce_wall bomb_appear LAA7D LAAD2 NativeReadHL NativeWriteHL
 KEYINT MusicTick SfxTick`.trim().split(/\s+/);

function profile(base, motion='reference') {
  const E = make(base + '/batty.rom', base + '/batty.sym');
  // Boot symbols include the IRQ body; the main symbol file only exports its callees.
  for (const line of fs.readFileSync(base + '/batty0.sym', 'latin1').split('\n')) {
    const m = line.match(/^(\S+):\s+EQU\s+0x([\da-f]+)/i);
    if (m && !(m[1] in E.L)) E.L[m[1]] = parseInt(m[2], 16);
  }
  E.memory.bytes = E.memory.bytes.slice(0, 65536);
  const control = E.memory.control_write.bind(E.memory);
  E.memory.control_write = v => { assert.equal(v, 0, 'RAM disk mapping'); control(v); };
  const entries = new Map(watched.filter(n => n in E.L).map(n => [E.L[n], n]));
  let cycles = 0, tick = 0, template, frame, stack = [], frames = [], maxStack = 0, lastWorkStart = null, paceProofs = 0;
  const checkInterrupt=E.v06c.checkInterrupt.bind(E.v06c);
  E.v06c.checkInterrupt=function() {
    const accepted=this.irq && E.cpu.iff;
    checkInterrupt();
    // vector06js adds its 16-cycle DI/RST entry outside instruction(). Keep
    // it separately so the instruction budget still matches the old bench.
    if(accepted && frame) {
      frame.irqEntryCycles+=16;
      if(frame.phase!=='wait')frame.irqEntryActiveCycles+=16;
    }
  };
  const w = (a, v) => E.memory.write(a, v);
  const put = (o, a) => a.forEach((v, i) => w(o + i, v));
  const phaseChanges = { WaitVideoFrame: 'wait', RCBegin: 'prepare', planes_begin: 'erase',
    DrawMovingObjects: 'draw', RCFlush: 'compose', direct_dots_done: 'tail' };
  const labels = Object.entries(E.L).filter(([n]) => /^[a-zA-Z_]/.test(n)).sort((a,b) => a[1]-b[1]);
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
  function closeCalls(pc, sp) {
    while (stack.length && stack.at(-1).ret === pc && stack.at(-1).sp + 2 === sp) {
      const call = stack.pop();
      const stat = frame.routines[call.name];
      stat.inclusive += cycles - call.start;
      if(call.detail) call.detail.ms=(cycles-call.start)/3000;
      if (call.name === 'WaitVideoFrame') { frame.phase = 'prepare'; lastWorkStart=cycles; }
      if (call.name === 'RCFlush' || (call.name === 'DrawMovingObjects' && !E.L.RCFlush)) frame.phase='dots';
    }
  }
  const instruction = E.cpu.instruction.bind(E.cpu);
  E.cpu.instruction = function () {
    const pc = this.pc;
    if (this.sp>=0x6900 && this.sp<=E.L.stack) {
      assert(this.sp>=E.L.StackFloor, 'stack crossed code/cache');
      maxStack=Math.max(maxStack,E.L.stack-this.sp);
    }
    if (frame) closeCalls(pc, this.sp);
    if(pc===E.L.WaitVideoFrame && frame && E.L.PaceWork && lastWorkStart!==null) {
      const bound=(E.rd(E.L.PaceWork)+256*E.rd(E.L.PaceWork+1))*64;
      assert(bound<=cycles-lastWorkStart,'pacing bound exceeds actual preceding work');
      frame.precedingWorkBound=bound;frame.skipRasterWait=bound>=E.FRAME;paceProofs++;
    }
    if (pc === E.L.LB9E8_2) {
      tick++;
      if (tick===21) E.key(32,1);
      if (tick===31) E.key(32,0);
      if (tick>=40) {
        if (frame) {
          assert.equal(stack.length,0,'unclosed procedure at step boundary: '+stack.map(s=>s.name));
          frame.total=cycles-frame.start;
          assert.equal(Object.values(frame.phases).reduce((a,b)=>a+b,0),frame.total,'phase sum');
          assert.equal(Object.values(frame.routines).reduce((a,b)=>a+b.exclusive,0)+frame.unattributed,frame.total,'exclusive sum');
          frames.push(frame);
        }
        if (tick===105) throw 'done';
        inject();
        frame={tick,shift:tick%8,start:cycles,phase:'logic',phases:{},routines:{},pc:{},unattributed:0,cacheBuilds:0,compose:{},drawBreakdown:{},objects:{},compositions:[],builds:[],spriteModes:[],irqEntryCycles:0,irqEntryActiveCycles:0};
      }
    }
    if (frame) {
      for (const [name, phase] of Object.entries(phaseChanges)) if (pc===E.L[name]) frame.phase=phase;
      const name = entries.get(pc);
      if (name) {
        const ret=E.rd(this.sp)+256*E.rd(this.sp+1);
        const stat=frame.routines[name] ||= {calls:0,inclusive:0,exclusive:0};
        stat.calls++;
        stack.push({name,ret,sp:this.sp,start:cycles});
        if (name==='SpriteCacheBuild') frame.cacheBuilds++;
        if (name==='SpriteCacheBuild') {
          const detail={index:E.rd(E.L.SpriteCacheIndex),height:E.rd(E.L.SpriteCacheHeight)};
          frame.builds.push(detail);stack.at(-1).detail=detail;
        }
        if (name==='RCCompose') {
          const detail={target:E.rd(E.L.RCPair)===0?'bonus':'ufo',rect:Array.from({length:4},(_,i)=>E.rd(E.L.RCRect+i)),descriptors:E.rd(E.L.RCCount),descriptorChecks:0,committedRows:0};
          frame.compositions.push(detail);stack.at(-1).detail=detail;
        }
        if (name==='SpriteCachePrepare') {
          const obj=E.rd(E.L.IXobj)+256*E.rd(E.L.IXobj+1);
          frame.spriteModes.push({kind:E.rd(obj)&127,shift:E.rd(E.L.direct_shift),width:E.rd(E.L.direct_width),rows:E.rd(E.L.direct_rows)});
        }
        if (name==='plane_object') {
          const obj=E.rd(E.L.IXobj)+256*E.rd(E.L.IXobj+1);
          const kind=E.rd(obj)&127;
          stack.at(-1).kind=kind;
          (frame.objects[kind] ||= {cycles:0,calls:0}).calls++;
        }
      }
    }
    const composition=frame && stack.findLast(s=>s.name==='RCCompose');
    if(composition && pc===E.L.rcc_object)composition.detail.descriptorChecks++;
    if(composition && pc===E.L.rcc_commit)composition.detail.committedRows++;
    instruction();
    const c=this.vcycles;
    if (frame) {
      frame.phases[frame.phase]=(frame.phases[frame.phase]||0)+c;
      frame.pc[pc]=(frame.pc[pc]||0)+c;
      if (stack.length) frame.routines[stack.at(-1).name].exclusive+=c;
      else frame.unattributed+=c;
      const obj=stack.findLast(s=>s.name==='plane_object');
      if(obj) {
        frame.objects[obj.kind].cycles+=c;
        let group='setup_and_other';
        if(stack.some(s=>s.name==='plane_object_fast'))group='geometry_and_source';
        else if(stack.some(s=>s.name==='SpriteCachePrepare'))group='cache_prepare';
        else if(stack.some(s=>s.name==='SUSaveObject'))group='save_under';
        else if(stack.some(s=>s.name==='RCRecord'))group='record';
        else if(stack.some(s=>s.name==='PreparedDraw'))group='prepared_draw';
        else if(pc>=E.L.color_cover_8 && pc<E.L.color_black_8)group='aligned_cover_pixels';
        else if(pc>=E.L.color_black_8 && pc<E.L.color_fast_row_end)group='aligned_black_pixels';
        else if(pc>=E.L.color_fast_row_end && pc<E.L.color_cover_table)group='aligned_row_control';
        else if(pc>=E.L.color_row && pc<E.L.color_fast_entry)group='raw_shifted_pixels';
        if(stack.some(s=>s.name==='KEYINT'))group='irq';
        frame.drawBreakdown[group]=(frame.drawBreakdown[group]||0)+c;
      }
      if(stack.some(s=>s.name==='RCCompose')) {
        // Explicit physical code ranges, never nearest EQU/data symbol attribution.
        let group='intersection_and_control';
        if(pc>=E.L.rcc_column && pc<E.L.rcc_restore) group='scratch_clear';
        if(pc>=E.L.rcc_pixel && pc<E.L.RCPreparedColumn) group='raw_shifted_pixels';
        if(pc>=E.L.RCPreparedColumn && pc<E.L.RCFastColumn) group='prepared_pixels';
        if(pc>=E.L.RCFastColumn && pc<E.L.rcc_next) group='raw_aligned_pixels';
        // RCCompose ends immediately before PreparedDraw in this build.
        if(pc>=E.L.rcc_empty && pc<E.L.PreparedDraw) group='commit';
        if(pc===E.L.KEYINT || stack.some(s=>s.name==='KEYINT')) group='irq';
        frame.compose[group]=(frame.compose[group]||0)+c;
      }
    }
    cycles+=c;
  };
  try {
    for(let f=0;f<1800;f++) { if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1); }
  } catch(e) {if(e!=='done')throw e;}
  assert.equal(frames.length,65);
  const warm=frames.slice(20);
  assert(warm.every(f=>f.cacheBuilds===0),'warm cache misses change the reference scenario');
  const reference=JSON.parse(fs.readFileSync(base.endsWith('-fast')?
    (process.env.BATTY_BUDGET_FAST_REFERENCE||'outputs/batty-prepared-fast-speed.json'):
    (process.env.BATTY_BUDGET_COMPOSITE_REFERENCE||(E.L.InitialObjectsRestore?
      'outputs/batty-three-plane-speed.json':'outputs/batty-prepared-composite-speed.json'))));
  assert.equal(reference.romSHA256,crypto.createHash('sha256').update(fs.readFileSync(base+'/batty.rom')).digest('hex'),'reference ROM mismatch');
  const expected=reference.reports.find(r=>r.name==='three_balls_bonus_enemy');
  const measured=warm.reduce((s,f)=>s+f.total/3000/warm.length,0);
  if(motion==='reference')assert(Math.abs(measured-expected.warmMeanMs)<1e-8,'profile perturbed reference timing');
  if(E.L.RCCompose)for(const f of frames)assert.equal(Object.values(f.compose).reduce((s,c)=>s+c,0),f.routines.RCCompose.inclusive,'compositor split sum');
  for(const f of frames)assert.equal(Object.values(f.drawBreakdown).reduce((s,c)=>s+c,0),f.routines.plane_object.inclusive,'direct output split sum');
  function aggregate(list) {
    const result={steps:list.length,totalMs:0,activeMs:0,irqEntryMs:0,irqEntryActiveMs:0,phases:{},routines:{},compose:{},drawBreakdown:{},objects:{},cacheBuilds:0};
    for(const f of list) {
      result.totalMs+=f.total/3000/list.length;
      result.activeMs+=(f.total-(f.phases.wait||0))/3000/list.length;
      result.irqEntryMs+=f.irqEntryCycles/3000/list.length;
      result.irqEntryActiveMs+=f.irqEntryActiveCycles/3000/list.length;
      result.cacheBuilds+=f.cacheBuilds;
      for(const bucket of ['phases','compose','drawBreakdown']) for(const [n,c]of Object.entries(f[bucket]))result[bucket][n]=(result[bucket][n]||0)+c/3000/list.length;
      for(const [n,s]of Object.entries(f.routines)) {
        const r=result.routines[n] ||= {callsPerStep:0,inclusiveMs:0,exclusiveMs:0};
        r.callsPerStep+=s.calls/list.length;r.inclusiveMs+=s.inclusive/3000/list.length;r.exclusiveMs+=s.exclusive/3000/list.length;
      }
      for(const [n,s]of Object.entries(f.objects)) {
        const r=result.objects[n] ||= {callsPerStep:0,ms:0};r.callsPerStep+=s.calls/list.length;r.ms+=s.cycles/3000/list.length;
      }
    }
    result.routines=Object.fromEntries(Object.entries(result.routines).sort((a,b)=>b[1].inclusiveMs-a[1].inclusiveMs));
    result.unattributedMs=list.reduce((s,f)=>s+f.unattributed/3000/list.length,0);
    result.modeledTotalMs=result.totalMs+result.irqEntryMs;
    result.modeledActiveMs=result.activeMs+result.irqEntryActiveMs;
    return result;
  }
  const pc={};for(const f of warm)for(const[p,c]of Object.entries(f.pc))pc[p]=(pc[p]||0)+c;
  const hot=Object.entries(pc).sort((a,b)=>b[1]-a[1]).slice(0,30).map(([p,c])=>({address:'0x'+(+p).toString(16),nearestLabel:labels.findLast(([,a])=>a<=+p)?.[0],msPerStep:c/3000/warm.length}));
  const worst=frames.reduce((a,b)=>a.total>b.total?a:b);
  return {base,motion,romSHA256:crypto.createHash('sha256').update(fs.readFileSync(base+'/batty.rom')).digest('hex'),
    maxNormalStackBytes:maxStack,paceProofs,warm:aggregate(warm),all:aggregate(frames),worst:aggregate([worst]),worstTick:worst.tick,
    shifts:Array.from({length:8},(_,shift)=>({shift,...aggregate(warm.filter(f=>f.shift===shift))})),hotInstructions:hot,
    frames:frames.map(({pc,start,phase,...f})=>f)};
}
const bases=process.env.BATTY_BUDGET_BASE?[process.env.BATTY_BUDGET_BASE]:['.'];
const reports=['reference','smooth'].flatMap(motion=>bases.map(base=>profile(base,motion)));
fs.writeFileSync(process.env.BATTY_BUDGET_OUT||'outputs/batty-three-plane-budget.json',JSON.stringify({cpu:'i8080 3 MHz; 64 KB; no RAM disk',
  method:'Per variant/motion: 65 controlled game steps, last 45 warm; moving paddle + 3 balls + bonus + UFO. Reference uses identical injection to measure-object-speed.js; smooth uses a 0..7..0 triangular offset with no coordinate jumps. Each instruction cycle charged to exactly one phase and one exclusive routine; inclusive routine times overlap; WaitVideoFrame includes IRQ body instructions during wait. The emulator adds 16 cycles per accepted IRQ outside instruction(); these are reported separately as irqEntryMs and included only in modeled*Ms. No brick/paddle collisions forced; no game/ROM edits.',reports},null,2));
for(const r of reports) console.log(JSON.stringify({base:r.base,warm:r.warm,worst:r.worst,worstTick:r.worstTick},null,2));
