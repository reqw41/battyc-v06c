const {make}=require('./vector_harness'),assert=require('assert'),fs=require('fs');const root=process.argv[2]||'.',E=make(root+'/batty.rom',root+'/batty.sym');
const w=(a,v)=>E.memory.write(a,v),ptr=(a,v)=>{w(a,v&255);w(a+1,v>>8)},inst=E.cpu.instruction.bind(E.cpu);
E.cpu.instruction=function(){if(this.pc===E.L.LB9E8_2)throw 'ready';inst();};try{for(let f=0;f<800;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='ready')throw e;}
E.cpu.instruction=inst;E.cpu.iff=false;const snap=E.memory.bytes.slice(),bat=E.L.object_bat_1,bonus=E.L.object_bonus;
function call(n){E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;ptr(E.cpu.sp,256);let k=0;while(E.cpu.pc!==256&&k++<200000){if(!(E.cpu.pc<0x8000||(E.L.CGCodeBegin&&E.cpu.pc>=E.L.CGCodeBegin&&E.cpu.pc<E.L.CGCode1End)||(E.L.CGCode2Begin&&E.cpu.pc>=E.L.CGCode2Begin&&E.cpu.pc<E.L.CGCodeEnd)))throw Error('escaped');inst();E.io.commit();}if(k>=200000)throw Error('hang '+n);}
let reports=[]; for(const mode of ['normal','wide','gun'])for(let id=0;id<10;id++){
 if((mode==='wide'&&id===0)||(mode==='gun'&&id===1))continue;
 E.memory.bytes.set(snap);w(bat+20,255);w(bat+2,116);w(bat+21,128);w(E.L.object_ball_1+7,3);
 ptr(E.L.ball_split_src,E.L.object_ball_1);
 if(mode==='wide'){w(bat+20,0);w(bat+12,44);w(bat+21,129);w(bat+1,5);}
 if(mode==='gun'){w(bat+20,1);w(bat+1,11);}
 if(id===9){const e=E.L.object_enemy;w(e,8);w(e+1,0);w(e+2,140);w(e+4,120);w(e+8,3);w(e+9,14);w(e+12,24);w(e+13,16);}
 for(let i=0;i<16;i++)w(E.L.bonus_table_current+i,id);
 ptr(E.L.IXobj,E.L.object_ball_1);ptr(E.L.LB28F+1,(150<<8)|120);call('set_bonus');
 let seen=[],caught=false,shots=0,maxWidth=0,frames=[];
 for(let t=0;t<160;t++){
  ptr(E.L.counter_misc,t);w(E.L.ctrl_btns_pressed,id===1&&t>80?16:0);
  ptr(E.L.IXobj,bat);call('handling_bat');
  if(E.rd(E.L.object_bullet_1)||E.rd(E.L.object_bullet_2))shots++;for(const b of[E.L.object_bullet_1,E.L.object_bullet_2])if(E.rd(b))assert.equal(E.rd(b+4),180,'bullet is not above the lowered paddle');
  const type=E.rd(bonus);if(type===4||type===11){ptr(E.L.IXobj,bonus);call(type===4?'handling_bonus':'handling_400pts');}
  if(E.rd(bonus)===11)caught=true;
  call('planes_begin');call('DrawMovingObjects');
  assert.equal(E.rd(E.L.spr_bonus_rocket_1+1),27,'rocket native column pitch changed');seen.push([E.rd(bat+1),E.rd(bat+12),E.rd(bat+20),E.rd(bat+21),E.rd(E.L.bonus_flag)]);maxWidth=Math.max(maxWidth,E.rd(bat+12));frames.push(E.rd(bat+1));
 }
assert(caught,mode+' '+id+' not caught');
 if(id===0)assert.equal(E.rd(bat+12),44,mode+' expansion');
 else if(id!==6)assert.equal(E.rd(bat+12),28,mode+' shrink '+id);
 if(id===1){assert([10,11].includes(E.rd(bat+1)),mode+' gun sprite');assert(shots>0,mode+' did not fire');assert([7,8,9].every(v=>frames.includes(v)),mode+' skipped gun transformation');}
 if(id===2){assert.equal(E.rd(E.L.balls_quantity),3);for(const b of [E.L.object_ball_1,E.L.object_ball_2,E.L.object_ball_3])assert.equal(E.rd(b),2);}
 if(id===3){const o=E.L.object_ball_1;w(o+2,E.rd(bat+2)+12);w(o+4,179);w(o+15,176);ptr(E.L.IXobj,o);call('LAB1F');assert.equal(E.rd(o+20),0xb0,mode+' hand did not attach ball');w(E.L.ctrl_btns_pressed,0);call('handling_ball');assert.equal(E.rd(o+4),0xaf);}
 if(id===4)assert.equal(E.rd(E.L.object_ball_1+7),2);
 if(id===5)assert.equal(E.rd(E.L.lives_1up),4);
 if(id===6)assert.equal(E.rd(E.L.object_rocket),6);
 if(id===7)assert.equal(E.rd(E.L.object_ball_1+1),8);
 if(id===8)assert.equal(E.rd(E.L.current_score_1up+1),0x54);
 if(id===9)assert.equal(E.rd(E.L.object_enemy),10);
 for(const v of [E.L.object_ball_1,E.L.object_ball_2,E.L.object_ball_3])assert([0,2,130].includes(E.rd(v)));
 reports.push({mode,id,caught,fireObserved:shots>0,width:E.rd(bat+12),frames:[...new Set(frames)]});
 if(mode==='normal'&&(id===0||id===1))E.pngFrom(E.idealBmp(),'outputs/batty-three-plane-bonus-'+(id===0?'wide':'gun')+'.png');
}

console.log({cases:reports.length,reports,passed:true}); if(process.env.BATTY_TEST_OUT||!process.argv[2])fs.writeFileSync(process.env.BATTY_TEST_OUT||'outputs/batty-bonus-effects-verification.json',JSON.stringify({romSHA256:require('crypto').createHash('sha256').update(fs.readFileSync(root+'/batty.rom')).digest('hex'),cases:reports.length,reports,passed:true},null,2));
