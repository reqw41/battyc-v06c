'use strict';
// Matched controlled gameplay: the enemy's bomb uses the real bonus handler.
const fs=require('fs'),assert=require('assert'),crypto=require('crypto');
const {make}=require('./vector_harness');
const base=process.env.BATTY_BENCH_BASE||'.';
const reports=[];
for(const balls of [1,3])for(const bomb of [false,true])for(const motion of ['fixed','phases']) {
 const E=make(base+'/batty.rom',base+'/batty.sym');
 E.memory.bytes=E.memory.bytes.slice(0,65536);
 const control=E.memory.control_write.bind(E.memory);
 E.memory.control_write=v=>{assert.equal(v,0);control(v);};
 const w=(a,v)=>E.memory.write(a,v),put=(o,a)=>a.forEach((v,i)=>w(o+i,v));
 let tick=0,cycles=0,frame,template,frames=[],waitReturn,buildReturn;
 const phases={WaitVideoFrame:'wait',RCBegin:'prepare',planes_begin:'erase',DrawMovingObjects:'draw',RCFlush:'compose',direct_dots_done:'tail'};
 const instruction=E.cpu.instruction.bind(E.cpu);
 E.cpu.instruction=function() {
  const pc=this.pc;
  if(this.sp>=0x6900&&this.sp<=E.L.stack)assert(this.sp>=E.L.StackFloor);
  if(frame&&pc===waitReturn){frame.phase='prepare';waitReturn=undefined;}
  if(frame&&pc===buildReturn){frame.buildCycles+=cycles-frame.buildStart;buildReturn=undefined;}
  if(pc===E.L.LB9E8_2) {
   tick++;
   if(tick===21)E.key(32,1);if(tick===31)E.key(32,0);
   if(tick>=40) {
    if(frame){frame.total=cycles-frame.start;assert.equal(Object.values(frame.phases).reduce((s,c)=>s+c,0),frame.total);frames.push(frame);}
    if(tick===105)throw 'done';
    template ||= Array.from({length:22},(_,i)=>E.rd(E.L.object_ball_1+i));
    for(let i=0;i<11;i++)if(E.L.object_ball_1+22*i!==E.L.object_bat_1)w(E.L.object_ball_1+22*i,0);
    const offset=tick%8;
    w(E.L.object_bat_1,1);w(E.L.object_bat_1+2,116+offset);w(E.L.object_bat_1+20,255);
    for(let i=0;i<balls;i++) {
     const a=template.slice();a[0]=2;a[2]=80+50*i+offset;a[3]=0;a[4]=130+10*i;a[5]=0;a[6]=8+8*i;a[7]=3;a[18]&=127;a[20]=0;a[21]=0;
     put(E.L.object_ball_1+22*i,a);
    }
    w(E.L.balls_quantity,balls);
    const enemy=Array(22).fill(0);
    enemy[0]=8;enemy[2]=180+offset;enemy[4]=64;enemy[6]=16;enemy[7]=1;enemy[8]=3;enemy[9]=16;enemy[12]=24;enemy[13]=16;enemy[14]=16;enemy[18]=0x60;enemy[19]=0x90;
    put(E.L.object_enemy,enemy);
    if(bomb){const a=Array(22).fill(0);a[0]=4;a[1]=10;a[2]=motion==='fixed'?189:184+offset;a[4]=88+tick-40;a[8]=2;a[9]=16;a[12]=8;a[13]=8;put(E.L.object_bonus,a);}
    w(E.L.LA557,0);w(E.L.LA557+1,2);w(E.L.LA559,0);
    frame={tick,start:cycles,phase:'logic',phases:{},builds:0,buildCycles:0};
   }
  }
  if(frame){
   // random_generate runs inside logic: suppress a new spawn at its real entry.
   // Existing bombs return immediately; ROM instructions remain unchanged.
   if(pc===E.L.bomb_appear){w(E.L.random_number,1);w(E.L.random_number_1,1);}
   for(const [n,p]of Object.entries(phases))if(pc===E.L[n])frame.phase=p;
   if(pc===E.L.WaitVideoFrame)waitReturn=E.rd(this.sp)+256*E.rd(this.sp+1);
   if(pc===E.L.SpriteCacheBuild){frame.builds++;frame.buildStart=cycles;buildReturn=E.rd(this.sp)+256*E.rd(this.sp+1);}
  }
  instruction();const c=this.vcycles;
  if(frame)frame.phases[frame.phase]=(frame.phases[frame.phase]||0)+c;
  cycles+=c;
 };
 try{for(let f=0;f<1800;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='done')throw e;}
 assert.equal(frames.length,65);
 const warm=frames.slice(20),mean=f=>warm.reduce((s,r)=>s+f(r)/warm.length,0);
 assert(warm.every(r=>r.builds===0),'warm phase rebuilt');
 const phaseTicks={};for(const r of warm)for(const [p,c]of Object.entries(r.phases))phaseTicks[p]=(phaseTicks[p]||0)+c/warm.length;
 reports.push({balls,bomb,motion,phaseTicks,activeTicks:mean(r=>r.total-(r.phases.wait||0)),totalTicks:mean(r=>r.total),maxActiveTicks:Math.max(...warm.map(r=>r.total-(r.phases.wait||0))),cacheBuilds:frames.reduce((s,r)=>s+r.builds,0),warmCacheBuilds:warm.reduce((s,r)=>s+r.builds,0),coldFirstStep:frames[0],frames});
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync(base+'/batty.rom')).digest('hex'),cpu:'i8080 3 MHz, 64 KB, no RAM disk',method:'65 matched controlled steps, last 45 warm; moving paddle, 1 or 3 free balls, UFO, with/without its 2x16-row bomb; fixed X for a vertical flight or all X phases; unchanged real handlers/rendering; IRQ entry cycles outside instruction() excluded',reports};
fs.writeFileSync(process.env.BATTY_BENCH_OUT||'outputs/batty-enemy-shot-speed.json',JSON.stringify(result,null,2));
console.log(reports.map(({frames,coldFirstStep,...r})=>r));
