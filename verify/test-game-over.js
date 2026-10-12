'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const reports=[];
for(const mode of[0,1,2]){
 const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const inst=E.cpu.instruction.bind(E.cpu),out=E.io.realoutput.bind(E.io),w=(a,v)=>E.memory.write(a,v),range=(a,n)=>Buffer.from(Array.from({length:n},(_,i)=>E.rd(a+i)));
 let ticks=0,t=0,entered=null,musicStarted=null,musicEnded=null,firstTone=null,before=null,resets=0,menuSwitches=0,minSP=E.L.stack,ready=false,notes=[0,0,0],vramCompared=false;
 E.cpu.instruction=function(){const pc=this.pc;
  if(this.sp>=0x6900&&this.sp<=E.L.stack){minSP=Math.min(minSP,this.sp);assert(this.sp>=E.L.StackFloor);}
  if(pc===E.L.LB9E8_1&&ticks===0){w(E.L.game_mode,mode);w(E.L.lives_2up,3);}
  if(pc===E.L.LB9E8_2&&++ticks===40){w(E.L.balls_quantity,0);w(E.L.lives_1up,1);}
  if(pc===E.L.LBC10_6){entered=t;before=range(0xa000,24576);}
  if(entered!==null){if(pc===E.L.planes_reset)resets++;if(pc===E.L.SetPaletteMenu)menuSwitches++;}
  if(pc===E.L.MusicStartScore&&this.hl()===E.L.GameOverScore){
   musicStarted=t;assert.equal(E.rd(E.L.UiActive),0);assert.equal(resets,0);assert.equal(menuSwitches,0);
   const core=Buffer.alloc(8192);
   for(const name of ['txt_game_over',mode===2?'txt_players_1_and_2':'txt_player_0']){
    const msg=E.L[name],x0=E.rd(msg),y0=E.rd(msg+1),count=E.rd(msg+3)&63;
    for(let c=0;c<count;c++)for(let r=0;r<6;r++)for(let b=0;b<8;b++)if(E.rd(E.L.font+E.rd(msg+4+c)*6+5-r)&(128>>b)){const x=x0+c*8+b;core[(x>>3)*256+((224-y0+r)&255)]|=128>>(x&7);}
   }
   const now=range(0xa000,24576);for(let p=0;p<3;p++)for(let i=0;i<8192;i++)assert.equal(now[p*8192+i],before[p*8192+i]&~core[i],'game-over cleared field '+JSON.stringify({mode,p,i}));vramCompared=true;
   if(mode===0)E.pngFrom(E.idealBmp(),'outputs/batty-vector-colors-game-over.png');
  }
  if(musicStarted!==null&&pc===E.L.MusicStop&&musicEnded===null)musicEnded=t;
  if(entered!==null&&pc===E.L.hi_score_update){ready=true;throw 'done';}
  inst();t+=this.vcycles;
 };
 E.io.realoutput=function(p,v){if(musicStarted!==null&&musicEnded===null&&p===8){const i=[0x36,0x76,0xb6].indexOf(v);if(i>=0){notes[i]++;if(firstTone===null)firstTone=t;}}out(p,v);};
 try{for(let f=0;f<2400;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='done')throw e;}
 assert(ready&&vramCompared&&musicEnded!==null,'loss transition');assert.deepStrictEqual(notes,[3,3,3]);assert.equal(E.rd(E.L.MusicActive),0);assert(musicEnded>firstTone);const seconds=(musicEnded-firstTone)/3000000;assert(Math.abs(seconds-0.958464)<0.003,'loss music duration');reports.push({mode,fieldPreservedExceptBlackGlyphCores:vramCompared,screenResets:resets,menuPaletteSwitches:menuSwitches,musicEventsPerChannel:notes,musicSeconds:seconds,eventToFirstToneMs:(firstTone-musicStarted)/3000,gameOverVisibleSeconds:(t-entered)/3000000,stackBytes:E.L.stack-minSP,passed:true});
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),physicalRAM:65536,reports,passed:true};fs.writeFileSync('outputs/batty-vector-colors-game-over.json',JSON.stringify(result,null,2));console.log(result);
