const {cleanVideo,field}=require('./three_plane_test_helpers');
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const root=process.env.BATTY_TEST_BASE||'.',legacy=process.env.BATTY_COMPARE_FULL==='1',reports=[];
for(const scene of [{mode:0,other:0,name:'one-player'},{mode:2,other:3,name:'double-play'},{mode:1,other:0,name:'second-player-out'},{mode:1,other:3,name:'player-change'}]){
 const E=make(root+'/batty.rom',root+'/batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const w=(a,v)=>E.memory.write(a,v),word=a=>E.rd(a)+256*E.rd(a+1),range=(a,n)=>Buffer.from(Array.from({length:n},(_,i)=>E.rd(a+i))),inst=E.cpu.instruction.bind(E.cpu);
 const ctl=E.memory.control_write.bind(E.memory);E.memory.control_write=v=>{assert.equal(v,0);ctl(v)};
 let started=false,death=false,atLoss=false,done=false,ticks=0,draws=0,resets=0,resumes=0,music=0,level,background,attrs,map,magnets,score,minSP=E.L.stack,cycles=0,lossCycles=0;
 E.cpu.instruction=function(){const pc=this.pc;if(this.sp>=0x6900&&this.sp<=E.L.stack){minSP=Math.min(minSP,this.sp);assert(this.sp>=E.L.StackFloor,'stack '+scene.name);}
  if(!started&&pc===E.L.LB9E8_1){w(E.L.game_mode,scene.mode);w(E.L.lives_2up,scene.other);}
  if(pc===E.L.LB9E8_2){if(!started){started=true;}else if(atLoss){done=true;throw 'done';}if(++ticks===40){w(E.L.balls_quantity,0);}}
  if(started&&pc===E.L.LBC10_0&&!death){death=true;
   // Preserve an already destroyed brick in both the level map and video.
   level=word(E.L.current_level_addr);w(level+2,E.rd(level+2)|128);
   // A background signature makes full repainting detectable even if the
   // same texture/brick map would otherwise reproduce identical pixels.
   w(0xa700,0x55);w(0xc700,0xa5);
  }
  if(pc===E.L.live_dec){assert(death);atLoss=true;lossCycles=cycles;background=field(E);attrs=range(E.L.NativeAttrs,E.L.NativeAttrBytes||1024);map=range(level,180);magnets=range(E.L.NativeMagnetOverlayFlags,4);score=range(E.L.current_score_1up,3);}
  if(atLoss){if(pc===E.L.game_screen_draw_to_buffer)draws++;if(pc===E.L.planes_reset)resets++;if(pc===E.L.ResumeLife)resumes++;if(pc===E.L.MusicStart)music++;}
  inst();cycles+=this.vcycles;
 };
 try{for(let frame=0;frame<2400;frame++){if(frame===100)E.key(48,1);if(frame===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='done')throw e;}
 assert(done,scene.name+' did not resume');const same=scene.mode!==1||scene.other===0;
 if(same&&!legacy){assert.equal(draws,0);assert.equal(resets,0);assert.equal(resumes,1);assert.equal(music,0);assert(background.equals(field(E,range(0xa000,24576))),'background repainted '+scene.name);assert(attrs.equals(range(E.L.NativeAttrs,E.L.NativeAttrBytes||1024)));assert(map.equals(range(level,180)));assert(magnets.equals(range(E.L.NativeMagnetOverlayFlags,4)));assert(score.equals(range(E.L.current_score_1up,3)));assert.equal(E.rd(E.L.lives_1up),2);assert.equal(E.rd(E.L.balls_quantity),1);assert.equal(E.rd(E.L.object_ball_1),2);assert.equal(E.rd(E.L.object_bat_1),1);assert.equal(E.rd(E.L.object_bat_2),scene.mode===2?1:0);assert.equal(E.rd(E.L.object_bonus),0);assert.equal(E.rd(E.L.object_enemy),0);
  assert.equal(E.rd(E.L.SUCount),0,'old moving sprites remain');
  assert.equal(E.rd(E.L.SUDropped),0,'save-under capacity');
  const source=E.L.spr_lives_indicator,width=E.rd(source),height=E.rd(source+1),expected=Buffer.alloc(192);
  for(let r=0;r<height;r++)for(let c=0;c<width;c++){const m=E.rd(source+2+2*(r*width+c)),black=m&E.rd(source+3+2*(r*width+c));expected[6*(1+c)+r]=m&~black;}
  for(let p=0;p<3;p++)for(let c=0;c<32;c++)for(let r=0;r<6;r++)assert.equal(E.rd(0xa000+p*8192+256*c+24-r),expected[6*c+r],'life HUD '+scene.name);
 }else{assert.equal(draws,1);assert.equal(resets,1);assert.equal(resumes,0);assert.equal(E.rd(E.L.player_number),same?0:1);assert.equal(music,1);}
 reports.push({...scene,fullDraws:draws,fullResets:resets,resumes,sameBackground:same&&!legacy?true:null,lifeToNextTickMs:(cycles-lossCycles)/3000,minStackAddress:minSP.toString(16),stackBytes:E.L.stack-minSP,passed:true});
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync(root+'/batty.rom')).digest('hex'),strict64K:true,reports,passed:true};fs.writeFileSync(process.env.BATTY_TEST_OUT||'outputs/batty-three-plane-resume.json',JSON.stringify(result,null,2));console.log(result);
