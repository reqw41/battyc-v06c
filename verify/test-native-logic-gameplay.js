'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const baseline=process.env.BATTY_LOGIC_BEFORE||'verify/fixtures/native-logic-before';
function ready(root){const E=make(root+'/batty.rom',root+'/batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const inst=E.cpu.instruction.bind(E.cpu);E.cpu.instruction=function(){if(this.pc===E.L.LB9E8_2)throw 'ready';inst();};try{for(let f=0;f<800;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='ready')throw e;}E.cpu.instruction=inst;E.cpu.iff=false;E.snap=E.memory.bytes.slice();return E;}
const old=ready(baseline),now=ready('.');
function w(E,a,v){E.memory.write(a,v);}
function ptr(E,a,v){w(E,a,v&255);w(E,a+1,v>>8);}
function word(E,a){return E.rd(a)+256*E.rd(a+1);}
function call(E,name){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;ptr(E,E.cpu.sp,256);let c=0,n=0;while(E.cpu.pc!==256){assert(++n<200000,'hang '+name);assert(E.cpu.pc<0x8000);if(E.cpu.sp>=0x6900&&E.cpu.sp<=E.L.stack)assert(E.cpu.sp>=E.L.StackFloor);E.cpu.instruction();E.io.commit();c+=E.cpu.vcycles;}return c;}
function bytes(E,a,n){return Array.from({length:n},(_,i)=>E.rd(a+i));}
const vars=['balls_quantity','briks_quantity_1up','briks_quantity_2up','flag_2','need_change_player','wins_counter','scr_score_need_upd','bonus_flag','counter_2','lives_1up','lives_2up','magnets_quantity'];
const ranges=[['sounds_queue',35],['current_score_1up',3],['current_score_2up',3],['NativeAttrs',768]];
function state(E){const objects=bytes(E,E.L.object_ball_1,242);for(let k=0;k<11;k++){objects[k*22+10]=0;objects[k*22+11]=0;}
 const s={objects,map:bytes(E,0x6d00,180),curLevelOffset:word(E,E.L.cur_level_ptr)-0x6d00};for(const n of vars)if(n in E.L)s[n]=E.rd(E.L[n]);for(const[n,size]of ranges)s[n]=bytes(E,E.L[n],size);// 8000..9FFF is invisible cache/save-under RAM in this variant.
 for(const page of [0xa000,0xc000,0xe000])s[page]=bytes(E,page,8192);return s;}
let seed=0x92ef37;function rnd(){seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;return seed>>>0;}
let reports=[];
for(const name of ['LAFFC','handling_ball','handling_ufo','handling_bird','handling_spark']){let oldTicks=0,newTicks=0;
 for(let i=0;i<640;i++){
  const x=i<256?i:rnd()&255,y=i<256?(i%16)*8:rnd()&255,width=[8,16,24,28,44][i%5],height=[7,8,13,16,31][i%5],direction=rnd()&63,speed=1+i%6,mode=i%7,held=i%13===0?176:0;
  const pattern=Array.from({length:180},(_,k)=>i%4===0?128:i%4===1?0:((k+i)%3===0?128:k%5));
  for(const E of [old,now]){E.memory.bytes.set(E.snap);E.cpu.iff=false;for(let k=0;k<242;k++)w(E,E.L.object_ball_1+k,0);
   const o=['handling_ufo','handling_bird'].includes(name)?E.L.object_enemy:E.L.object_ball_1;
   const obj=[name==='handling_ufo'?8:name==='handling_bird'?9:name==='handling_spark'?7:2,0,x,0,y,0,direction,speed,3,16,0,0,width,height,x,y,0,0,0,0,held,128];obj.forEach((v,k)=>w(E,o+k,v));
   const bat=[1,0,116,0,173,0,0,0,4,13,0,0,28,13,116,173,0,0,0,0,mode,128];bat.forEach((v,k)=>w(E,E.L.object_bat_1+k,v));
   ptr(E,E.L.IXobj,o);ptr(E,E.L.current_level_addr,0x6d00);ptr(E,E.L.cur_level_ptr,0x6d00);pattern.forEach((v,k)=>w(E,0x6d00+k,v));
   w(E,E.L.balls_quantity,3);w(E,E.L.briks_quantity_1up,100);w(E,E.L.game_mode,0);w(E,E.L.player_number,0);w(E,E.L.magnets_quantity,0);w(E,E.L.ctrl_btns_pressed,i%2?16:0);ptr(E,E.L.counter_misc,i);ptr(E,E.L.random_number,0x8e17);
   for(let k=0;k<35;k++)w(E,E.L.sounds_queue+k,0);for(const n of ['LA270','LA274','LA278'])if(n in E.L)for(let k=0;k<4;k++)w(E,E.L[n]+k,0);
   const ticks=call(E,name);if(E===old)oldTicks+=ticks;else newTicks+=ticks;
  }
  try{assert.deepStrictEqual(state(now),state(old));}catch(e){const a=state(old),b=state(now);const different=Object.keys(a).filter(k=>JSON.stringify(a[k])!==JSON.stringify(b[k]));throw Error(name+' case '+i+' x='+x+' y='+y+' w='+width+' h='+height+' different '+different.join(','));}
 }
 reports.push({name,cases:640,oldTicks,newTicks,passed:true});
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),strict64K:true,reports,passed:true};fs.writeFileSync('outputs/batty-native-logic-gameplay.json',JSON.stringify(result,null,2));console.log(result);
