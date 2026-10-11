'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const base=process.env.BATTY_TEST_BASE||'.',before='outputs/no-shadows-before';
const E=make(base+'/batty.rom',base+'/batty.sym'),old=make(before+'/batty.rom',before+'/batty.sym');
E.memory.bytes=E.memory.bytes.slice(0,65536);old.memory.bytes=old.memory.bytes.slice(0,65536);
const raw=new Uint8Array(fs.readFileSync(before+'/batty.rom')),rd=a=>raw[a-256]||0;
E.run(100);old.run(100);
const stats=JSON.parse(fs.readFileSync('outputs/batty-no-shadows-assets.json')).stats;
let litChecks=0,outlineChecks=0,phaseChecks=0;
function pixel(machine,name,x,y){const a=machine.L[name],w=machine.rd(a),h=machine.rd(a+1);if(x>=w*8||y>=h)return 0;const at=a+2+2*(y*w+(x>>3)),bit=128>>(x&7);return machine.rd(at)&bit?(machine.rd(at+1)&bit?2:1):0;}
for(const r of stats){
 assert.equal(E.L[r.name],old.L[r.name],'fixed reservation moved');
 assert.deepEqual([E.rd(E.L[r.name]),E.rd(E.L[r.name]+1)],r.after,r.name);
 if(r.generatedFrom){
  const w=E.rd(E.L[r.name]),h=E.rd(E.L[r.name]+1);
  for(let y=0;y<h;y++)for(let x=0;x<w*8;x++){assert.equal(pixel(E,r.name,x,y),x<r.phase?0:pixel(E,r.generatedFrom,x-r.phase,y),r.name+' phase');phaseChecks++;}
  continue;
 }
 const a=old.L[r.name],w=rd(a),h=r.name==='spr_bird_4'?14:/^spr_bullet_[12]$/.test(r.name)?5:rd(a+1);
 for(let y=0;y<h;y++)for(let x=0;x<w*8;x++){
  const at=a+2+2*(y*w+(x>>3)),bit=128>>(x&7),mask=rd(at)&bit,lit=mask&&rd(at+1)&bit,got=pixel(E,r.name,x,y);
  assert.equal(got===1,!!lit,r.name+' lit detail '+x+','+y);litChecks++;
  if(got)assert(mask,r.name+' added silhouette');
  // Original neighbouring dark pixels form the black edge of lit details.
  if(mask&&!lit){let edge=false;for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const xx=x+dx,yy=y+dy;if(xx<0||xx>=w*8||yy<0||yy>=h)continue;const p=a+2+2*(yy*w+(xx>>3)),b=128>>(xx&7);edge ||= !!(rd(p)&rd(p+1)&b);}if(edge){assert.equal(got,2,r.name+' lost black outline');outlineChecks++;}}
 }
}
// Deliberately dark explosion frames and unshadowed UFO/bonus artwork survive.
let untouched=0;
for(const [name,a]of Object.entries(E.L))if(/^spr_(ufo_|alien_blast_|bullet_blast_|bonus_)/.test(name)){
 assert.equal(a,old.L[name]);const n=2+2*E.rd(a)*E.rd(a+1);
 for(let i=0;i<n;i++)assert.equal(E.rd(a+i),old.rd(a+i),name+' changed');untouched++;
}
for(let i=0;i<11;i++)for(const offset of [12,13])assert.equal(E.rd(E.L.object_ball_1+22*i+offset),old.rd(old.L.object_ball_1+22*i+offset),'collision extent changed');
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync(base+'/batty.rom')).digest('hex'),assets:stats.length,litChecks,outlineChecks,phaseChecks,untouchedEffectAndBonusAssets:untouched,collisionSizesUnchanged:true,strict64K:true,passed:true};
fs.writeFileSync(process.env.BATTY_TEST_OUT||'outputs/batty-no-shadows-assets-verification.json',JSON.stringify(result,null,2));console.log(result);
