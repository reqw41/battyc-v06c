const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const root=process.env.BATTY_TEST_BASE||'.',E=make(root+'/batty.rom',root+'/batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);
const w=(a,v)=>E.memory.write(a,v),put=(o,a)=>a.forEach((v,i)=>w(o+i,v)),word=a=>E.rd(a)+256*E.rd(a+1),inst=E.cpu.instruction.bind(E.cpu);
let current=null,ready=false,frame=0,t=0,eraseStart=0,eraseReturn=0,enemyStart=0,enemyReturn=0,drawStart=0,stepStart=0;
let eraseStartPhase=0;
const enemyFirst=process.env.BATTY_ENEMY_FIRST==='1';let earlyStage=0;
const bonusTarget=process.env.BATTY_RASTER_BONUS==='1',moving=process.env.BATTY_RASTER_MOVING==='1';
const phases=[],scenes=[];
for(const heavy of [false,true])for(const kind of (bonusTarget?[4]:[8,9]))for(const shift of [0,3])for(const y of (enemyFirst?[108]:[40,108,144]))scenes.push({heavy,kind,shift,y,samples:[],phases:[]});
function objects(c){
 for(let i=0;i<11;i++)w(E.L.object_ball_1+22*i,0);
 for(let i=0;i<(c.heavy?3:1);i++){const a=Array(22).fill(0);a[0]=2;a[2]=80+40*i;a[4]=136;a[6]=8;a[7]=3;a[8]=2;a[9]=12;a[12]=8;a[13]=7;a[20]=0xc0;a[21]=0x80;put(E.L.object_ball_1+22*i,a);}
 w(E.L.balls_quantity,c.heavy?3:1);
 const b=Array(22).fill(0);b[0]=1;b[2]=116;b[4]=173;b[8]=4;b[9]=13;b[12]=28;b[13]=10;b[20]=255;b[21]=0x80;put(E.L.object_bat_1,b);
 if(c.heavy){const a=Array(22).fill(0);a[0]=4;a[2]=51;a[4]=96;a[8]=2;a[9]=8;a[12]=16;a[13]=8;a[18]=0xf0;a[19]=0x60;put(E.L.object_bonus,a);w(E.L.LA559+1,0);}
 const a=Array(22).fill(0);a[0]=c.kind;a[2]=176+c.shift+(moving?frame%8:0);a[4]=c.y+(moving?frame%4:0);a[6]=16;a[7]=1;a[8]=3;a[9]=c.kind===8?16:12;a[12]=24;a[13]=a[9];a[18]=c.kind===8?0x60:0xf0;a[19]=c.kind===8?0x90:0x70;if(bonusTarget){a[0]=4;a[6]=0;a[8]=3;a[9]=11;a[12]=16;a[13]=8;a[18]=0xf0;a[19]=0x60;put(E.L.object_bonus,a);w(E.L.LA559+1,0);if(c.heavy){a[0]=8;a[2]=220;a[4]=40;a[8]=3;a[9]=16;put(E.L.object_enemy,a);}else w(E.L.object_enemy,0);}else put(E.L.object_enemy,a);
}
E.cpu.instruction=function(){
 const pc=this.pc;
 if(pc===E.L.LB9E8_2){ready=true;stepStart=t;if(current)objects(current);}
 if(current){
  if(pc===E.L.planes_begin){objects(current);earlyStage=0;eraseStart=t;eraseStartPhase=E.cyc()/3000;eraseReturn=word(this.sp);drawStart=t;}
  if(eraseReturn&&pc===eraseReturn){current.phases.push({eraseMs:(t-eraseStart)/3000,eraseStartPhaseMs:eraseStartPhase});eraseReturn=0;}
  if(pc===E.L.plane_object&&word(E.L.IXobj)===E.L.object_enemy&&current.phases.length){enemyStart=t;enemyReturn=word(this.sp);current.phases[current.phases.length-1].enemyStartPhaseMs=E.cyc()/3000;}
  if(enemyReturn&&pc===enemyReturn){const p=current.phases[current.phases.length-1];p.enemyBlitMs=(t-enemyStart)/3000;p.erasedUntilEnemyDrawMs=(enemyStart-eraseStart)/3000;p.drawThroughEnemyMs=(t-drawStart)/3000;p.stepThroughEnemyMs=(t-stepStart)/3000;enemyReturn=0;}
  // A/B experiment only: call the existing enemy renderer first, then exclude
  // it from the ordinary list so its pixels/erase footprint are emitted once.
  if(enemyFirst&&pc===E.L.DrawMovingObjects){
   if(earlyStage===0){earlyStage=1;w(E.L.IXobj,E.L.object_enemy&255);w(E.L.IXobj+1,E.L.object_enemy>>8);this.sp-=2;w(this.sp,pc&255);w(this.sp+1,pc>>8);this.pc=E.L.plane_object;return;}
   if(earlyStage===1){earlyStage=2;w(E.L.object_enemy,0);}
  }
  if(enemyFirst&&pc===E.L.direct_dots_done&&earlyStage===2)w(E.L.object_enemy,current.kind);
 }
 inst();t+=this.vcycles;
};
for(;!ready&&frame<700;frame++){if(frame===100)E.key(48,1);if(frame===110)E.key(48,0);E.run(1);}assert(ready);
let captured=false;
for(const c of scenes){
 current=c;enemyReturn=eraseReturn=0;const source=E.L[bonusTarget?'spr_bonus_size':c.kind===8?'spr_ufo_1':'spr_bird_1'],width=E.rd(source),height=E.rd(source+1),pixels=[];
 for(let r=0;r<height;r++)for(let col=0;col<width;col++){const m=E.rd(source+2+2*(r*width+col)),p=E.rd(source+3+2*(r*width+col)),fg=m&~p;
  for(let b=0;b<8;b++)if(fg&(128>>b))for(let dx=0;dx<(moving?8:1);dx++)for(let dy=0;dy<(moving?4:1);dy++)pixels.push({x:176+c.shift+8*col+b+dx,y:c.y+r+dy,index:E.L.SUObjectPlanes===2?(bonusTarget||r<(height>>1)?1:3):(bonusTarget||r<(height>>1)?7:1)});}
 for(let f=0;f<76;f++){E.run(1);frame++;if(f<12)continue;let raster=0,memory=0;
  for(const p of pixels){const expected=E.io.Palette[p.index]>>>0,sx=32+2*p.x,sy=16+37+p.y;
   if((E.v06c.bmp[sy*576+sx]>>>0)===expected)raster++;
   const a=0x8000+(p.x>>3)*256+((224-p.y)&255),bit=128>>(p.x&7);let index=0;
   for(let j=0;j<4;j++)if(E.rd(a+j*8192)&bit)index|=[8,4,2,1][j];
   if((E.io.Palette[index]>>>0)===expected)memory++;
  }
  c.samples.push({raster,memory,total:pixels.length});
  if(!captured&&c.heavy&&c.shift===3&&raster<pixels.length/2){E.png('outputs/batty-three-plane-flicker-raster.png');captured=true;}
 }
 c.phases=c.phases.slice(6).filter(p=>p.enemyBlitMs!==undefined);
}
const reports=scenes.map(c=>({heavy:c.heavy,target:bonusTarget?'bonus':c.kind===8?'UFO':'bird',shift:c.shift,y:c.y,samples:c.samples.length,blankFrames:c.samples.filter(s=>!s.raster).length,partialFrames:c.samples.filter(s=>s.raster<s.total).length,minVisibleFraction:Math.min(...c.samples.map(s=>s.raster/s.total)),meanVisibleFraction:c.samples.reduce((a,s)=>a+s.raster/s.total,0)/c.samples.length,memoryBlankFrames:c.samples.filter(s=>!s.memory).length}));
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync(root+'/batty.rom')).digest('hex'),cpu:'i8080 3 MHz, strict 64 KB',moving,method:'Stable object positions, real game pipeline and actual raster; 64 samples per scene after warmup. Foreground checked against native source masks, palette and scroll. Moving mode checks foreground in the union of eight X and four Y positions: zero blank frames proves the object does not completely disappear, without proving a tear-free image.',reports};
fs.writeFileSync(process.env.BATTY_RASTER_OUT||'outputs/batty-three-plane-'+(bonusTarget?'bonus':'enemy')+'-raster.json',JSON.stringify(result,null,2));console.table(reports);
