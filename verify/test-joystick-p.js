'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
function machine(){const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const input=E.io.input.bind(E.io);E.joys=[255,255];E.io.input=function(p){if(p===6){switch((this.PC2>>5)&3){case 0:return E.joys[0]&E.joys[1];case 1:return E.joys[0];case 2:return E.joys[1];default:return 255;}}return input(p);};return E;}
function call(E,name,a=0){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;E.memory.write(E.cpu.sp,0);E.memory.write(E.cpu.sp+1,1);E.cpu.set_a(a);E.cpu.iff=false;for(let i=0;E.cpu.pc!==256;i++){assert(i<1e6,name);E.cpu.instruction();E.io.commit();}}
const E=machine();E.run(100);const w=(n,v)=>E.memory.write(E.L[n],v);let cases=0;
for(let mode=0;mode<3;mode++)for(let player=0;player<2;player++)for(const first of[255,254,253,191,127,189])for(const second of[255,254,253,191,127,189]){
 w('game_mode',mode);w('player_number',player);w('ctrl_type_1up',1);w('JoystickP',first);w('JoystickP2',second);w('SoloJoystick2',0);call(E,'get_control_state',1);const j=~((mode===2||!player)?first:second)&255;assert.equal(E.rd(E.L.ctrl_btns_pressed),12|(j&3)|((j&192)?16:0));call(E,'get_right_player_ctrl_state',1);const k=~second&255;assert.equal(E.rd(E.L.ctrl_btns_pressed),12|(k&3)|((k&192)?16:0));cases++;
}
w('game_mode',2);w('ctrl_type_1up',0);w('ctrl_type_2up',0);w('KeyLine0',255);w('KeyLine7',255);
for(const key of[255,253,239,191,173]){w('KeyLine4',key);call(E,'get_left_player_ctrl_state');const b=~key&255;assert.equal(E.rd(E.L.ctrl_btns_pressed),12|(b&16?1:0)|(b&2?2:0)|(b&64?16:0));call(E,'get_right_player_ctrl_state',0);assert.equal(E.rd(E.L.ctrl_btns_pressed),12);cases++;}
const starts=[];
for(const pad of[0,1]){const Q=machine();const orig=Q.cpu.instruction.bind(Q.cpu);let started=false,loops=0;Q.cpu.instruction=function(){if(this.pc===Q.L.L93F8_0&&++loops===4)Q.joys[pad]=191;if(this.pc===Q.L.LB9E8_2){started=true;throw 'done';}orig();};try{for(let f=0;f<1000;f++)Q.run(1);}catch(e){if(e!=='done')throw e;}assert(started,'fire start '+pad);assert.equal(Q.rd(Q.L.ctrl_type_1up),1);assert.equal(Q.rd(Q.L.SoloJoystick2),pad);starts.push({pad:pad+1,fireStartedGame:true});}
// Actual IRQ scanning must preserve two distinct port samples.
const Q=machine();Q.run(100);Q.joys=[254,189];Q.run(2);assert.equal(Q.rd(Q.L.JoystickP),254);assert.equal(Q.rd(Q.L.JoystickP2),189);
const report={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),cases,starts,irqDevicesSeparate:true,doubleKeyboardIndependent:true,passed:true};fs.writeFileSync('outputs/batty-animation-joystick.json',JSON.stringify(report,null,2));console.log(report);
