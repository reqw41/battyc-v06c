const {cleanVideo}=require('./three_plane_test_helpers');
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const root=process.env.BATTY_TEST_BASE||'.',reports=[];
for(const [tag,x,mode,x2] of [['centre',116,0,116],['left',8,0,8],['right',220,0,220],['double-wide',8,2,220],['double-close',96,2,128]]){
 const E=make(root+'/batty.rom',root+'/batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const w=(a,v)=>E.memory.write(a,v),word=a=>E.rd(a)+256*E.rd(a+1),inst=E.cpu.instruction.bind(E.cpu),range=(a,n)=>Buffer.from(Array.from({length:n},(_,i)=>E.rd(a+i)));
 const ctl=E.memory.control_write.bind(E.memory);E.memory.control_write=v=>{assert.equal(v,0);ctl(v);};
 let cycles=0,renderStart=null,renderReturn=null,renderCycles=[];
 let ticks=0,death=false,done=false,expected,oldParticles=[],nextParticles=[],steps=0,local=0,global=0,minSP=E.L.stack,bg,guard=range(E.L.SparksLocalRender,18);
 const masks=()=>{let out=[];for(let i=0;i<11;i++){let o=E.L.object_ball_1+22*i;if(E.rd(o)!==7||E.rd(o+4)>=192)continue;let a=word(E.L.anim_spark+2*E.rd(o+1)),width=E.rd(a),height=E.rd(a+1),x=E.rd(o+2),y=E.rd(o+4),pixels=[];for(let r=0;r<height&&y+r<192;r++)for(let c=0;c<width;c++){let m=E.rd(a+2+2*(r*width+c)),black=m&E.rd(a+3+2*(r*width+c));for(let b=0;b<8;b++)if((m&(128>>b))&&x+8*c+b<256)pixels.push({x:x+8*c+b,y:y+r,black:!!(black&(128>>b))});}out.push({id:i,x,y,pixels});}return out;};
 E.cpu.instruction=function(){let pc=this.pc;if(renderStart!==null&&pc===renderReturn){renderCycles.push(cycles-renderStart);renderStart=null;}if(this.sp>=0x6900&&this.sp<=E.L.stack){minSP=Math.min(minSP,this.sp);assert(this.sp>=E.L.StackFloor,'stack code overlap '+tag);}
  if(pc===E.L.LB9E8_2&&++ticks===40)w(E.L.balls_quantity,0);
  if(pc===E.L.LBC10_0){w(E.L.object_bat_1+2,x);w(E.L.object_bat_2+2,x2);w(E.L.game_mode,mode);}
  if(pc===E.L.SparksRender){renderStart=cycles;renderReturn=word(this.sp);death=true;nextParticles=masks();if(!bg)bg=cleanVideo(E);expected=Buffer.from(bg);for(let p of nextParticles)for(let q of p.pixels){const pos=(q.x>>3)*256+((224-q.y)&255),bit=128>>(q.x&7);for(let plane=0;plane<3;plane++)expected[plane*8192+pos]=(expected[plane*8192+pos]&~bit)|(q.black?0:bit);}}

  if(death&&pc===E.L.SparksLocalRender){local++;for(let i=0;i<oldParticles.length;i++){let at=E.L.plane_old+4*i,startX=(E.rd(at)-0xe0)*8,startY=(224-E.rd(at+1))&255,endX=startX+8*E.rd(at+2),endY=startY+E.rd(at+3);for(let p of nextParticles)if(p.id!==oldParticles[i].id)for(let q of p.pixels)assert(!(q.x>=startX&&q.x<endX&&q.y>=startY&&q.y<endY),'unsafe local erase '+tag+' step '+steps);}}
  if(death&&pc===E.L.planes_begin)global++;
  if(death&&pc===E.L.pause_game){for(let c=0;c<32;c++)for(let y=0;y<192;y++){const pos=c*256+((224-y)&255);for(let p=0;p<3;p++)assert.equal(E.rd(0xa000+p*8192+pos),expected[p*8192+pos],'spark '+tag+' step '+steps+' plane '+p+' '+c+','+y);}assert(bg.equals(cleanVideo(E)),'background modified');assert.equal(E.rd(E.L.SUDropped),0);
  assert(guard.equals(range(E.L.SparksLocalRender,18)),'level buffer corrupted code');steps++;oldParticles=nextParticles;}
  if(death&&pc===E.L.live_dec){done=true;throw 'done';}inst();cycles+=this.vcycles;};
 try{for(let f=0;f<2200;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='done')throw e;}
 assert(done&&steps>10);assert.equal(local,0);assert(global>0);reports.push({tag,steps,local,global,minStackAddress:minSP.toString(16),stackBytes:E.L.stack-minSP,pixelsCorrect:true,backgroundUnchanged:true,reverseSaveUnder:true,renderMeanMs:renderCycles.reduce((a,b)=>a+b,0)/renderCycles.length/3000,renderMaxMs:Math.max(...renderCycles)/3000});
}
let result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync(root+'/batty.rom')).digest('hex'),physicalRAM:65536,reports,passed:true};fs.writeFileSync(process.env.BATTY_TEST_OUT||'outputs/batty-three-plane-sparks.json',JSON.stringify(result,null,2));console.log(result);
