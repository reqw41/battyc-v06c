const {make}=require('./vector_harness'),assert=require('assert'),fs=require('fs');
const root=process.argv[2]||'.',E=make(root+'/batty.rom',root+'/batty.sym');
const frameLimit=Number(process.env.BATTY_GAMEPLAY_FRAMES||6000);
E.memory.bytes=E.memory.bytes.slice(0,65536);
const w=(a,v)=>E.memory.bytes[E.memory.tobank(a&65535)]=v,inst=E.cpu.instruction.bind(E.cpu);
let ticks=0,frame=0,launchTick=0,lastBonus=0,enemySeen=false,bombsSeen=0,created=[],caught=[],started=false;
E.cpu.instruction=function(){if(E.L.StackFloor&&this.sp>=0x6900&&this.sp<=E.L.stack)assert(this.sp>=E.L.StackFloor,'stack reaches classifier code');
 if(started){assert(this.pc<0x8000,'execution escaped into video RAM');assert(this.pc!==0&&this.pc!==256&&this.pc!==E.L.start_bin,'unexpected CPU restart');}
 if(this.pc===E.L.LB9E8_2){
  ticks++;started=true;
  for(const o of [E.L.object_ball_1,E.L.object_ball_2,E.L.object_ball_3])assert([0,2,128,130].includes(E.rd(o)),'ball type corrupted');
  const bonus=E.rd(E.L.object_bonus),id=E.rd(E.L.object_bonus+1),y=E.rd(E.L.object_bonus+4);
  const x=bonus===4&&id!==10&&y>145?E.rd(E.L.object_bonus+2)+8:E.rd(E.L.object_ball_1+2);
  w(E.L.object_bat_1+2,Math.max(8,Math.min(220,x-12)));
  if(E.rd(E.L.object_ball_1+20)===0xc0||ticks===21){E.key(32,1);launchTick=ticks;}
  if(ticks===launchTick+10)E.key(32,0);
  if(bonus!==lastBonus){if(bonus===4){if(id===10)bombsSeen++;else{assert(id<10);created.push({frame,id});}}if(bonus===11)caught.push({frame,id:E.rd(E.L.object_bonus+20)});lastBonus=bonus;}
  enemySeen ||= E.rd(E.L.object_enemy)!==0;
 }
 inst();
};
for(frame=0;frame<frameLimit;frame++){if(frame===100)E.key(48,1);if(frame===110)E.key(48,0);E.run(1);}
console.log({ticks,created,caught,enemySeen,bombsSeen}); assert(created.length>=4&&caught.length>=3);assert(created.some(v=>v.id===4));if(process.env.BATTY_GAMEPLAY_REQUIRE_SMASH!=='0')assert(caught.some(v=>v.id===7));assert(enemySeen&&bombsSeen>0);
const result={frames:frameLimit,ticks,naturalBonuses:created,pickedBonuses:caught,enemySeen,bombsSeen,unexpectedResets:0,physicalRAM:65536,naturalSmashObserved:caught.some(v=>v.id===7),requiredNaturalSmash:process.env.BATTY_GAMEPLAY_REQUIRE_SMASH!=='0',passed:true};
console.log(result);if(process.env.BATTY_GAMEPLAY_OUT||!process.argv[2])fs.writeFileSync(process.env.BATTY_GAMEPLAY_OUT||'outputs/batty-natural-bonus-verification.json',JSON.stringify(result,null,2));
