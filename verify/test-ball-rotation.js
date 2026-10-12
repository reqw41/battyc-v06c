'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);const w=(a,v)=>E.memory.write(a,v),word=(a,v)=>{w(a,v);w(a+1,v>>8)};
function call(name){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;word(E.cpu.sp,256);E.cpu.iff=false;let t=0;for(let i=0;E.cpu.pc!==256;i++){assert(i<1e6);E.cpu.instruction();E.io.commit();t+=E.cpu.vcycles;}return t;}
const o=E.L.object_ball_1;word(E.L.IXobj,o);w(o,2);w(o+20,0);w(E.L.object_bat_1+20,255);w(E.L.object_bat_2+20,255);w(E.L.balls_quantity,1);const pictures=new Set();let cases=0;
for(let phase=0;phase<4;phase++)for(let shift=0;shift<8;shift++){w(o+1,shift);w(o+2,80+shift);w(o+21,128);w(E.L.counter_misc,phase*4);call('sprite_draw_prepare');assert.equal(E.rd(o+1),0);assert.equal(E.rd(o+21)&128,0);E.cpu.set_rp(4,o);call('sprite_search');const p=E.cpu.de();assert.equal(p,E.L['BallRotation'+phase]);assert.equal(E.rd(p),1);assert.equal(E.rd(p+1),6);pictures.add(Buffer.from(Array.from({length:6},(_,r)=>E.rd(p+3+r*2))).toString('hex'));cases++;}
assert.equal(pictures.size,4);w(o+20,100);E.cpu.set_rp(4,o);call('sprite_search');assert.equal(E.cpu.de(),E.L.BallRotation0);w(o+20,0);w(E.L.balls_quantity,3);w(o+1,5);w(o+21,128);call('sprite_draw_prepare');assert.equal(E.rd(o+1),5);assert.equal(E.rd(o+21),128);E.cpu.set_rp(4,o);call('sprite_search');assert.equal(E.cpu.de(),E.L.spr_ball_normal_shift_5);
w(E.L.balls_quantity,1);w(o+1,8);E.cpu.set_rp(4,o);call('sprite_search');assert.equal(E.cpu.de(),E.L.spr_big_ball);
call('planes_reset');for(let i=0;i<11;i++)w(E.L.object_ball_1+i*22,0);w(E.L.object_bat_1+20,255);w(E.L.object_bat_2+20,255);
const lit=[[0,56,76,92,124,56],[0,56,100,116,124,56],[0,56,124,116,100,56],[0,56,124,92,76,56]];let drawnFrames=0;
for(const count of[1,2])for(let phase=0;phase<4;phase++)for(let shift=0;shift<8;shift++){
 w(E.L.balls_quantity,count);w(E.L.counter_misc,phase*4);w(E.L.object_ball_2,0);const expected=Buffer.alloc(8192);
 for(let i=0;i<count;i++){const ball=E.L.object_ball_1+22*i,x=80+shift+4*i,y=72+2*i;w(ball,2);w(ball+1,shift);w(ball+2,x);w(ball+4,y);w(ball+20,0);w(ball+21,128);for(let r=0;r<6;r++)for(let b=0;b<8;b++)if(lit[phase][r]&(128>>b)){const px=x+b;expected[(px>>3)*256+224-y-r]|=128>>(px&7);}}
 call('DrawMovingObjects');const actual=Buffer.from(Array.from({length:8192},(_,i)=>E.rd(32768+i)));assert(actual.equals(expected),'rotation trails or overlap '+JSON.stringify({count,phase,shift}));drawnFrames++;
}
const report={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),cases,drawnFrames,rotationOverlapAndRestorationVerified:true,distinctPhases:4,periodGameplaySteps:16,attachedBallStationary:true,threeBallsKeepFastOriginalSprites:true,smashUnchanged:true,passed:true};fs.writeFileSync('outputs/batty-animation-ball.json',JSON.stringify(report,null,2));console.log(report);
