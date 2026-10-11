'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const base=process.env.BATTY_LOGIC_BEFORE||'verify/fixtures/native-logic-before',root='.';
function env(p){const E=make(p+'/batty.rom',p+'/batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);E.cpu.iff=false;return E;}
const before=env(base),after=env(root),reports=[];
function w(E,a,v){E.memory.write(a,v);}
function ptr(E,a,v){w(E,a,v&255);w(E,a+1,v>>8);}
function word(E,a){return E.rd(a)+256*E.rd(a+1);}
function call(E,name,stop){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;ptr(E,E.cpu.sp,256);let cycles=0,n=0;while(E.cpu.pc!==256&&E.cpu.pc!==stop){assert(++n<200000,'hang '+name);assert(E.cpu.pc<0x8000,'escaped '+name);E.cpu.instruction();E.io.commit();cycles+=E.cpu.vcycles;}return cycles;}
function oldRow(y,h){if(y>=128||((y+h)&255)<32)return null;for(let i=0;i<12;i++){const r=32+8*i;let d=(r-y)&255;if(r<y){if(d+8>255)return i;}else if(d<h)return i;}return null;}
function newRow(y,h){const end=(y+h)&255;if(y>=128||end<32)return null;if(y<=32)return end===32?null:0;return (y-33)>>3;}
let oldTicks=0,newTicks=0,selected=0;
for(let y=0;y<256;y++)for(let h=0;h<256;h++){
 const expected=oldRow(y,h);assert.equal(newRow(y,h),expected,'JS row '+y+','+h);
 for(const E of [before,after]){ptr(E,E.L.IXobj,E.L.object_ball_1);w(E,E.L.object_ball_1+4,y);w(E,E.L.object_ball_1+13,h);ptr(E,E.L.current_level_addr,0x6d00);ptr(E,E.L.cur_level_ptr,0x5555);E.cpu.set_rp(4,0x1234);E.cpu.set_rp(0,0x5678);E.cpu.set_rp(2,0x9abc);const t=call(E,'LAFFC',E.L.LAFFC_3);if(E===before)oldTicks+=t;else newTicks+=t;assert.equal(E.cpu.pc===E.L.LAFFC_3,expected!==null,'native selection '+y+','+h);if(expected!==null){assert.equal(E.cpu.h(),expected);assert.equal(E.cpu.c(),32+8*expected);assert.equal(word(E,E.L.cur_level_ptr),0x6d00+15*expected);}assert.equal(E.rd(E.L.flag_2),0);}
 if(expected!==null)selected++;
}
reports.push({name:'brick_row_selection',cases:65536,selected,oldTicks,newTicks,passed:true});
let seed=0x36af09;function rnd(){seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;return seed>>>0;}
function keys(a,b,c){a=(~a)&255;b=(~b)&255;c=(~c)&255;return 12|((a&0xac)||(b&0x80)||(c&0xc0)?16:0)|((a&0x42)||(c&1)?1:0)|((a&0x11)||(c&2)?2:0);}
oldTicks=newTicks=0;let kc=0;
const cases=[];for(let row=0;row<3;row++)for(let v=0;v<256;v++){let a=[255,255,255];a[row]=v;cases.push(a);}for(let i=0;i<8192;i++)cases.push([rnd()&255,rnd()&255,rnd()&255]);
for(const a of cases)for(const cf of [false,true]){for(const E of [before,after]){for(let j=0;j<3;j++)w(E,E.L[['KeyLine0','KeyLine7','JoystickP'][j]],a[j]);E.cpu.cf=cf;const t=call(E,'read_keyboard');if(E===before)oldTicks+=t;else newTicks+=t;assert.equal(E.rd(E.L.ctrl_btns_pressed),keys(...a),'keys '+a);}kc++;}
reports.push({name:'keyboard',cases:kc,oldTicks,newTicks,passed:true});
// Pointer reuse in the ball finalizer must preserve both state and return flags.
oldTicks=newTicks=0;let bc=0;
for(let x=0;x<256;x++)for(const y of [0,127,166,191,192,255])for(const phase of [0,128]){
 for(const E of [before,after]){const o=E.L.object_ball_1;for(let i=0;i<22;i++)w(E,o+i,0);w(E,o,2);w(E,o+2,x);w(E,o+4,y);w(E,o+21,phase);ptr(E,E.L.IXobj,o);ptr(E,E.L.LA27C,0x6d20);w(E,0x6d20,3);w(E,0x6d21,4);w(E,E.L.balls_quantity,3);E.cpu.set_rp(0,0x5678);E.cpu.set_rp(2,0x9abc);const t=call(E,'LA27E_25');if(E===before)oldTicks+=t;else newTicks+=t;assert.equal(E.rd(o+1),x&7);assert.equal(E.rd(o+21),phase|128);assert.equal(E.rd(o),y<192?2:130);assert.equal(E.rd(E.L.balls_quantity),y<192?3:2);}
 assert.equal(before.cpu.cf,after.cpu.cf);assert.equal(before.cpu.a(),after.cpu.a());bc++;
}
reports.push({name:'ball_finalizer',cases:bc,oldTicks,newTicks,passed:true});
// Match the original column loop, including byte wrap at the left border.
oldTicks=newTicks=0;
for(let x=0;x<256;x++)for(const y of [33,40,80,127]){
 const row=(y-33)>>3,n=(x-8)&255,col=n>>4;
 for(const E of [before,after]){const o=E.L.object_ball_1;ptr(E,E.L.IXobj,o);w(E,o+2,x);w(E,o+4,y);w(E,o+13,7);ptr(E,E.L.current_level_addr,0x6d00);ptr(E,E.L.cur_level_ptr,0x6d00);const t=call(E,'LAFFC',E===before?E.L.LAFFC_5+4:E.L.native_column_ready);if(E===before)oldTicks+=t;else newTicks+=t;assert.equal(E.cpu.h(),32+row*8);assert.equal(E.cpu.l(),8+col*16);assert.equal(word(E,E.L.cur_level_ptr),0x6d00+15*row+col);assert.equal(E.rd(E.L.LB069+1),240+(n&15));}
}
reports.push({name:'brick_column_selection',cases:1024,oldTicks,newTicks,passed:true});
// Independent signed fixed-point model for all directions and byte speeds.
const table=[255,253,250,244,230,224,212,197,180,161,141,120,97,74,49,24,0];
oldTicks=newTicks=0;let motionCases=0;
for(let direction=0;direction<64;direction++)for(let speed=0;speed<256;speed++){
 const q=direction>>4,j=direction&15,xx=table[16-j],yy=table[j];
 const dx=[yy,-xx,-yy,xx][q]*speed,dy=[xx,yy,-xx,-yy][q]*speed;
 const x=rnd()&65535,y=rnd()&65535;
 for(const E of [before,after]){const o=E.L.object_ball_1;ptr(E,E.L.IXobj,o);w(E,o+6,direction);w(E,o+7,speed);w(E,o+2,x>>8);w(E,o+3,x&255);w(E,o+4,y>>8);w(E,o+5,y&255);const t=call(E,'LAD69');if(E===before)oldTicks+=t;else newTicks+=t;assert.equal(E.rd(o+2)*256+E.rd(o+3),(x+dx)&65535, "X dir="+direction+" speed="+speed+" variant="+(E===before?"old":"new"));assert.equal(E.rd(o+4)*256+E.rd(o+5),(y+dy)&65535, "Y dir="+direction+" speed="+speed+" variant="+(E===before?"old":"new"));assert.equal(E.cpu.cf,false);assert.equal(E.cpu.hl(),o+5);}
 motionCases++;
}
reports.push({name:'fixed_point_motion',cases:motionCases,oldTicks,newTicks,passed:true});
const result={beforeSHA256:crypto.createHash('sha256').update(fs.readFileSync(base+'/batty.rom')).digest('hex'),romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),strict64K:true,reports,passed:true};fs.writeFileSync('outputs/batty-native-logic-oracles.json',JSON.stringify(result,null,2));console.log(result);
