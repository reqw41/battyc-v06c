const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const root=process.env.BATTY_RESTORE_BASE||'.',reports=[];let cases=0,sequential=0,duration=[];
for(let level=0;level<4;level++){
 const E=make(root+'/batty.rom',root+'/batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);
 const w=(a,v)=>E.memory.write(a,v),ptr=(a,v)=>{w(a,v&255);w(a+1,v>>8)},word=a=>E.rd(a)+256*E.rd(a+1),inst=E.cpu.instruction.bind(E.cpu);
 E.cpu.instruction=function(){if(this.pc===E.L.LB9E8_1)w(E.L.current_level_number_1up,level);if(this.pc===E.L.LB9E8_2)throw 'ready';inst();};
 try{for(let f=0;f<800;f++){if(f===100)E.key(48,1);if(f===110)E.key(48,0);E.run(1);}}catch(e){if(e!=='ready')throw e;}
 E.cpu.instruction=inst;E.cpu.iff=false;
 const call=n=>{E.cpu.pc=E.L[n];E.cpu.sp=E.L.stack-2;ptr(E.cpu.sp,256);let k=0,t=0;while(E.cpu.pc!==256&&k++<1000000){E.cpu.instruction();t+=E.cpu.vcycles;E.io.commit();}assert(k<1000000,n);assert.equal(E.cpu.sp,E.L.stack,n+' stack');return t/3000;};
 const read=(m,a)=>m[E.memory.tobank(a&65535)],lev=word(E.L.current_level_addr);
 // Canonical full draw starts with clean pixels and attributes, as game_restart does.
 call('planes_reset');call('game_screen_draw_to_buffer');let saved=E.memory.bytes.slice();const indices=Array.from({length:180},(_,i)=>i).filter(i=>!(read(saved,lev+i)&128));
 const field=m=>Buffer.from(Array.from({length:3*32*219},(_,i)=>{const p=Math.floor(i/(32*219)),r=i%219,c=Math.floor((i%(32*219))/219);return read(m,0xa000+p*8192+c*256+224-r);}));
 const reference=(state,index)=>{
  E.memory.bytes.set(state);if(index!==null)w(lev+index,E.rd(lev+index)|128);
  const flags=Array.from({length:4},(_,i)=>E.rd(E.L.NativeMagnetOverlayFlags+i));
  for(let a=0xa000;a<0x10000;a++)w(a,0);for(let a=E.L.NativeAttrs;a<E.L.NativeAttrs+768;a++)w(a,0xd0);
  E.cpu.instruction=function(){if(this.pc===E.L.MagnetInitialLayerChoice){const i=(word(E.L.IXobj)-E.L.magnet_properties)/16;w(E.L.random_number,(E.rd(E.L.random_number)&254)|(flags[i]?0:1));}inst();};
  call('game_screen_draw_to_buffer');E.cpu.instruction=inst;return E.memory.bytes.slice();
 };
 const destroy=(state,index)=>{
  E.memory.bytes.set(state);const x=8+16*(index%15),y=32+8*Math.floor(index/15);
  ptr(E.L.IXobj,E.L.object_ball_1);ptr(E.L.cur_level_ptr,lev+index);ptr(E.L.LB28F+1,(y<<8)|x);w(E.L.LB292+1,0);w(E.L.brik_value+1,15+Math.floor(index/15));w(E.L.random_number_1,255);w(E.L.object_bat_1+20,255);w(E.L.object_bat_2+20,255);w(E.L.wins_counter,0);ptr(E.L.wins_recovery_ptr,E.L.wins_recovery_data);
  duration.push(call('LAFFC_38'));assert(E.rd(lev+index)&128);return E.memory.bytes.slice();
 };
 let tested=0;
 for(const i of indices){const want=reference(saved,i),got=destroy(saved,i);if(!field(got).equals(field(want))){let diff=[];for(let plane of[0xa000,0xc000,0xe000])for(let c=1;c<31;c++)for(let y=29;y<136;y++){let a=plane+c*256+224-y;if(read(got,a)!==read(want,a))diff.push({a:a.toString(16),x:c*8,y,got:read(got,a),want:read(want,a)});}console.log(diff.slice(0,30),diff.length);};assert(field(got).equals(field(want)),`full A/C/E field differs: level ${level+1}, brick ${i}`);cases++;tested++;}
 // Repeated destruction also repairs outlines that previously belonged to neighbors.
 let state=saved;
 for(const i of indices){const want=reference(state,i),got=destroy(state,i);assert(field(got).equals(field(want)),`sequential field differs: level ${level+1}, brick ${i}`);state=got;sequential++;}
 E.memory.bytes.set(state);call('NativeRestoreBrick');assert.equal(E.rd(E.L.SUCount),0);
 reports.push({level:level+1,texture:level,individualBricks:tested,sequentialBricks:tested});
 if(level===0){E.memory.bytes.set(state);w(0xf0,0xc3);w(0xf1,0xf0);w(0xf2,0);E.cpu.pc=0xf0;E.cpu.iff=false;E.run(2);E.png('outputs/batty-three-plane-background.png');}
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync(root+'/batty.rom')).digest('hex'),physicalRAM:65536,individualCases:cases,saveUnderRetiredBeforeWrite:true,sequentialCases:sequential,compared:'All three A/C/E planes across all 32 columns, Y=0..218, including the CPC frame, against a fresh draw of the same level and magnet state',reports,destructionMeanMs:duration.reduce((a,b)=>a+b,0)/duration.length,destructionMinMs:Math.min(...duration),destructionMaxMs:Math.max(...duration),passed:true};
fs.writeFileSync(process.env.BATTY_TEST_OUT||'outputs/batty-three-plane-bricks.json',JSON.stringify(result,null,2));console.log(result);
