'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
function boot(rom,sym){const Q=make(rom,sym);Q.memory.bytes=Q.memory.bytes.slice(0,65536);const inst=Q.cpu.instruction.bind(Q.cpu);let ready=false;Q.cpu.instruction=function(){if(this.pc===Q.L.LB9E8_2){ready=true;throw 'ready';}inst();};try{for(let f=0;f<900;f++){if(f===100)Q.key(48,1);if(f===110)Q.key(48,0);Q.run(1);}}catch(e){if(e!=='ready')throw e;}assert(ready);Q.cpu.instruction=inst;return Q;}
const E=boot('batty.rom','batty.sym'),B=boot('../../outputs/batty-three-plus-one-full-height.rom','../../outputs/batty-three-plus-one-full-height.sym');
const w=(a,v)=>E.memory.write(a,v),ptr=(a,v)=>{w(a,v);w(a+1,v>>8);},word=(Q,a)=>Q.rd(a)+256*Q.rd(a+1),read=(a,n)=>Buffer.from(Array.from({length:n},(_,i)=>E.rd(a+i)));
let minSP=E.L.stack;function call(n){E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;ptr(E.cpu.sp,256);E.cpu.iff=false;let k=0,t=0;while(E.cpu.pc!==256){assert(++k<2e6,n);if(E.cpu.sp>=0x6900&&E.cpu.sp<=E.L.stack){minSP=Math.min(minSP,E.cpu.sp);assert(E.cpu.sp>=E.L.StackFloor);}E.cpu.instruction();E.io.commit();t+=E.cpu.vcycles;}return t;}
assert.equal(E.rd(E.L.object_bat_1+4),B.rd(B.L.object_bat_1+4)+8);assert.equal(E.rd(E.L.object_bat_temp+4),181);
assert.equal(E.rd(E.L.object_ball_1+7),B.rd(B.L.object_ball_1+7));
for(let i=0;i<180;i++)assert.equal(E.rd(word(E,E.L.current_level_addr)+i),B.rd(word(B,B.L.current_level_addr)+i),'level cell changed');
assert.equal(word(E,E.L.score_1up_in_game)&255,240);assert.equal(E.rd(E.L.object_score_indicator+4),232);
const ball=E.L.object_ball_1;ptr(E.L.IXobj,ball);w(E.L.ctrl_btns_pressed,0);call('handling_ball');assert.equal(E.rd(ball+4),175,'attached ball is at old paddle height');w(E.L.ctrl_btns_pressed,16);call('handling_ball');assert.equal(E.rd(ball+4),174,'first launched frame height');assert.equal(E.rd(ball+7),3);
const state=E.memory.bytes.slice();w(E.L.object_bat_1+20,255);w(ball+20,0);w(ball+2,E.rd(E.L.object_bat_1+2)+12);w(ball+4,179);w(ball+15,176);ptr(E.L.IXobj,ball);call('LAB1F');assert.equal(E.rd(ball+4),174,'bounce uses old paddle height');assert.equal(E.rd(ball+7),3);E.memory.bytes.set(state);let lossCases=0;
for(const y of[199,200]){E.memory.bytes.set(state);w(ball,2);w(ball+4,y);w(E.L.balls_quantity,1);ptr(E.L.IXobj,ball);ptr(E.L.LA27C,E.L.LA270);call('LA27E_25');assert.equal(E.rd(E.L.balls_quantity),y===200?0:1);assert.equal(!!(E.rd(ball)&128),y===200);lossCases++;}

const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),paddleY:181,heldBallY:175,launchAnchorY:177,firstLaunchedFrameY:174,lossBoundaryY:200,lossCases,levelCellsUnchanged:180,ballSpeedUnchanged:true,paddleBounceVerified:true,scoreOutsideFrameRestored:true,stackBytes:E.L.stack-minSP,passed:true};fs.writeFileSync('outputs/batty-lower-bat-layout.json',JSON.stringify(result,null,2));console.log(result);
