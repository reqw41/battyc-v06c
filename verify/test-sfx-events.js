'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const B=make('../../outputs/batty-three-plus-one-game-over-before-cheats.rom','../../outputs/batty-three-plus-one-game-over-before-cheats.sym'),E=make('batty.rom','batty.sym');
for(const Q of[B,E]){Q.memory.bytes=Q.memory.bytes.slice(0,65536);Q.run(100);Q.events=[];const real=Q.io.realoutput.bind(Q.io);Q.io.realoutput=(p,v)=>{if(p===8||p===11)Q.events.push([p,v]);real(p,v);};}
function call(Q,n){Q.cpu.pc=Q.L[n];Q.cpu.sp=Q.L.stack-2;Q.memory.write(Q.cpu.sp,0);Q.memory.write(Q.cpu.sp+1,1);Q.cpu.iff=false;let i=0;while(Q.cpu.pc!==256){assert(++i<10000,n);Q.cpu.instruction();Q.io.commit();}}
let cases=0;
for(const id of[1,2,3,4,6,7,8,9,10,11,12])for(const counter of[2,0x30,0x58,0x99]){
 for(const Q of[B,E]){Q.events=[];const w=(a,v)=>Q.memory.write(a,v),o=Q.L.sounds_queue;w(o,id);w(o+1,counter);w(Q.L.snd_slot_ptr,o);w(Q.L.snd_slot_ptr+1,o>>8);w(Q.L.MusicActive,0);w(Q.L.SfxCooldown??(Q.L.SfxWait+3),0);w(Q.L.SfxWait,0);w(Q.L.random_number,17);w(Q.L.bonus_flag,0);Q.cpu.set_a(id);call(Q,'play_selected_sound');}
 assert.deepStrictEqual(E.events,B.events,'event timer output '+id+'/'+counter);assert.equal(E.rd(E.L.sounds_queue),B.rd(B.L.sounds_queue));if(E.rd(E.L.sounds_queue))assert.equal(E.rd(E.L.sounds_queue+1),B.rd(B.L.sounds_queue+1),'active envelope state');assert.equal(E.rd(E.L.frames),B.rd(B.L.frames));assert.equal(E.rd(E.L.frames_copy),B.rd(B.L.frames_copy));cases++;
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),eventCases:cases,otherEventTimerWritesUnchanged:true,activeQueueStateUnchanged:true,passed:true};fs.writeFileSync('outputs/batty-vector-colors-sfx.json',JSON.stringify(result,null,2));console.log(result);
