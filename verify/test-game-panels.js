'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.run(100);const w=(a,v)=>E.memory.write(a,v),word=(a,v)=>{w(a,v);w(a+1,v>>8)},rgb=()=>Buffer.from(Array.from({length:24576},(_,i)=>E.rd(0xa000+i)));
function call(n){E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;word(E.cpu.sp,256);E.cpu.iff=false;for(let i=0;E.cpu.pc!==256;i++){assert(i<2e6);E.cpu.instruction();E.io.commit();}}
call('planes_reset');for(let i=0;i<24576;i++)w(0xa000+i,(i*41+17)&255);for(let i=0;i<11;i++)w(E.L.object_ball_1+i*22,0);const before=rgb();call('show_window_round_number');const round=rgb();call('win_bg_recovery');assert(rgb().equals(before),'round did not restore field');call('DrawGameOverPanel');assert(rgb().equals(round),'panels differ in position, size or colour');
for(const name of['txt_player_x','txt_game_on','txt_game_over'])assert.equal(E.rd(E.L[name]+1),143);
for(const name of['txt_round_xx','txt_player_0','txt_players_1_and_2'])assert.equal(E.rd(E.L[name]+1),158);
const report={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),identicalPanelRectangle:{x:64,y:135,width:128,height:25},firstLineBaseline:143,secondLineBaseline:158,roundBackgroundRestored:true,passed:true};fs.writeFileSync('outputs/batty-animation-panels.json',JSON.stringify(report,null,2));console.log(report);
