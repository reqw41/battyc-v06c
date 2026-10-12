'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const inst=E.cpu.instruction.bind(E.cpu);
const B=make('../../outputs/batty-three-plus-one-cpc-bricks.rom','../../outputs/batty-three-plus-one-cpc-bricks.sym');
// Russian font order: digits, 32 letters, punctuation, Latin Y.
const ABC='0123456789АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ., -=Y',textAt=(M,a,n)=>Array.from({length:n},(_,i)=>ABC[M.rd(a+i)]).join('');
assert.equal(textAt(E,E.L.txt_player_0_enter_your_name+4,12),'   ИГРОК 0  ','name-entry text changed');assert.equal(textAt(E,E.L.txt_player_0_enter_your_name+20,16),'ВВЕДИТЕ ВАШЕ ИМЯ','name-entry text changed');
let loops=0,done=false;
E.cpu.instruction=function(){if(this.pc===E.L.L93F8_0){
 loops++;
 if(loops===2||loops===20)E.key(65,1);if(loops===4||loops===22)E.key(65,0);
 if(loops===20){assert.equal(E.rd(E.L.ctrl_type_1up),1);assert.equal(E.rd(E.L.coord_ctrl_1up+1),154);}
 if(loops===40){assert.equal(E.rd(E.L.ctrl_type_1up),0);assert.equal(E.rd(E.L.coord_ctrl_1up+1),130);E.key(66,1);}
 if(loops===42||loops===62)E.key(66,0);
 if(loops===60){assert.equal(E.rd(E.L.ctrl_type_2up),1);assert.equal(E.rd(E.L.coord_ctrl_2up+1),154);E.key(66,1);}
 if(loops===80){assert.equal(E.rd(E.L.ctrl_type_2up),0);assert.equal(E.rd(E.L.coord_ctrl_2up+1),130);done=true;throw 'done';}
 }inst();};
try{for(let f=0;f<800;f++)E.run(1);}catch(e){if(e!=='done')throw e;}assert(done,'menu toggle test did not finish');
E.pngFrom(E.idealBmp(),'outputs/batty-full-height-menu.png');
const R=make('batty.rom','batty.sym');R.memory.bytes=R.memory.bytes.slice(0,65536);const ri=R.cpu.instruction.bind(R.cpu);let records=false;
R.cpu.instruction=function(){if(this.pc===R.L.hs_wait){records=true;throw 'records';}ri();};
try{for(let f=0;f<1000;f++)R.run(1);}catch(e){if(e!=='records')throw e;}assert(records,'record screen does not appear');R.pngFrom(R.idealBmp(),'outputs/batty-full-height-records.png');
// Rank and score columns must share each baseline; all ten rows have equal spacing.
for(let i=0;i<10;i++){
 const rankY=R.rd(R.L.txt_high_score_table+i*6+1);
 const scoreY=R.rd(R.L.txt_high_score_table+61+i*18+1);assert.equal(rankY,39+i*17);assert.equal(scoreY,rankY);
 assert.equal(textAt(R,R.L.txt_high_score_table+61+i*18+4,14),String((10-i)*10000).padStart(6,'0')+'   '+(i%2?'П А К':'Х И Т'),'record contents changed');
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),menuLoops:loops,togglesPerPlayer:2,keyboardJoystickToggleVerified:true,highScoreRows:10,rankAndScoreBaselinesMatch:true,rowSpacing:17,passed:true};fs.writeFileSync('outputs/batty-full-height-menu-selection.json',JSON.stringify(result,null,2));console.log(result);
