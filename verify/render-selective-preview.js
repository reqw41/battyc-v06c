'use strict';
// Completed framebuffer previews, not raster/flicker acceptance evidence.
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const paths=[];
for(let level=0;level<4;level++) {
 const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);
 const w=(a,v)=>E.memory.write(a,v),ptr=(a,v)=>{w(a,v&255);w(a+1,v>>8)},inst=E.cpu.instruction.bind(E.cpu);
 E.cpu.instruction=function(){if(this.pc===E.L.LB9E8_1)w(E.L.current_level_number_1up,level);if(this.pc===E.L.LB9E8_2)throw 'ready';inst();};
 try{for(let f=0;f<800;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='ready')throw e;}
 E.cpu.instruction=inst;E.cpu.iff=false;
 function call(name){E.cpu.pc=E.L[name];E.cpu.sp=E.L.stack-2;ptr(E.cpu.sp,256);let n=0;while(E.cpu.pc!==256){assert(++n<1e6,name);E.cpu.instruction();E.io.commit();}}
 call('planes_reset');call('game_screen_draw_to_buffer');
 for(let i=0;i<11;i++)for(let j=0;j<22;j++)w(E.L.object_ball_1+22*i+j,0);
 function obj(a,kind,frame,x,y,width){w(a,kind);w(a+1,frame);w(a+2,x);w(a+4,y);w(a+12,width);w(a+20,255);}
 obj(E.L.object_bat_1,1,0,116,180,28);obj(E.L.object_ball_1,2,0,103,158,8);
 obj(E.L.object_bonus,4,1,64,145,16);obj(E.L.object_enemy,8,0,180,108,24);
 ptr(E.L.counter_misc,1);call('planes_begin');call('DrawMovingObjects');E.cpu.set_rp(4,E.L.object_bat_1+2);call('running_dot');
 const path='outputs/batty-selective-level-'+(level+1)+'.png';E.pngFrom(E.idealBmp(),path);paths.push(path);
}
const r={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),method:'Completed framebuffer, real boot/level palette and native drawing, injected stationary objects. Does not prove raster stability.',paths};
fs.writeFileSync('outputs/batty-selective-previews.json',JSON.stringify(r,null,2));console.log(r);
