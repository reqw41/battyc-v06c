'use strict';
const assert=require('assert'),{make}=require('./vector_harness');
for(const scene of['menu','round','magnets']){
 const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);const inst=E.cpu.instruction.bind(E.cpu);let ret=null,done=false;
 E.cpu.instruction=function(){
  if(scene==='menu'&&this.pc===E.L.L93F8_0){done=true;throw 'done';}
  if(scene!=='menu'&&this.pc===E.L.LB9E8_1)E.memory.write(E.L.current_level_number_1up,1);
  if(scene==='round'&&this.pc===E.L.show_window_round_number)ret=E.rd(this.sp)+256*E.rd(this.sp+1);
  if((scene==='round'&&ret!==null&&this.pc===ret)||(scene==='magnets'&&this.pc===E.L.LB9E8_2)){done=true;throw 'done';}
  inst();
 };
 try{for(let f=0;f<1000;f++){if(scene!=='menu'){if(f===100)E.key(48,1);if(f===110)E.key(48,0);}E.run(1);}}catch(e){if(e!=='done')throw e;}
 assert(done,scene);E.pngFrom(E.idealBmp(),'outputs/batty-vector-colors-'+scene+'.png');
}
