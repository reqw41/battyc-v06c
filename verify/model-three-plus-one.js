'use strict';
const assert=require('assert'),fs=require('fs');
let seed=3108080;const rnd=n=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n;};
const video=new Uint8Array(8192);let previous=[];let writes=0,overlaps=0;
function address(o,c,r){return (o.x+c)*256+o.top-r;}
function overlapsRect(a,b){return a.x<b.x+b.cols&&b.x<a.x+a.cols&&a.top>=b.top-b.rows+1&&b.top>=a.top-a.rows+1;}
for(let frame=0;frame<2500;frame++){
 const current=Array.from({length:rnd(12)},()=>{const x=rnd(31),cols=1+rnd(Math.min(6,32-x)),rows=1+rnd(30),top=65+rnd(160);return{x,cols,rows,top,bits:Uint8Array.from({length:cols*rows},()=>rnd(256))};});
 const expected=new Uint8Array(8192);
 for(const o of current)for(let c=0;c<o.cols;c++)for(let r=0;r<o.rows;r++)expected[address(o,c,r)]|=o.bits[c*o.rows+r];
 // Conservative isolation: unions of old/new rectangles must be disjoint.
 const bounds=current.map((o,i)=>{const p=previous[i];if(!p)return o;const x=Math.min(o.x,p.x),right=Math.max(o.x+o.cols,p.x+p.cols),top=Math.max(o.top,p.top),bottom=Math.min(o.top-o.rows+1,p.top-p.rows+1);return{x,cols:right-x,top,rows:top-bottom+1};});
 for(let i=current.length;i<previous.length;i++)bounds[i]=previous[i];
 const isolated=bounds.map((b,i)=>!bounds.some((q,j)=>i!==j&&overlapsRect(b,q)));
 for(let i=0;i<current.length;i++){const o=current[i];for(let c=0;c<o.cols;c++)for(let r=0;r<o.rows;r++){const a=address(o,c,r);if(isolated[i])video[a]=o.bits[c*o.rows+r];else video[a]|=o.bits[c*o.rows+r];writes++;}}
 for(let i=0;i<previous.length;i++){
  const old=previous[i],own=current[i],candidates=current.filter(o=>overlapsRect(old,o));if(candidates.length>1)overlaps++;
  for(let c=0;c<old.cols;c++)for(let r=0;r<old.rows;r++){
   const a=address(old,c,r),inside=own&&old.x+c>=own.x&&old.x+c<own.x+own.cols&&old.top-r<=own.top&&old.top-r>=own.top-own.rows+1;
   if(isolated[i]&&inside)continue;
   let value=0;if(!isolated[i])for(const o of candidates){const dx=old.x+c-o.x,dy=o.top-(old.top-r);if(dx>=0&&dx<o.cols&&dy>=0&&dy<o.rows)value|=o.bits[dx*o.rows+dy];}
   assert.equal(value,expected[a]);video[a]=value;writes++;
  }
 }
 assert.deepStrictEqual(video,expected);previous=current;
}
const result={frames:2500,writes,overlappingOldRects:overlaps,saveUnder:false,finalSpriteUnion:true,passed:true};fs.writeFileSync('outputs/batty-three-plus-one-model.json',JSON.stringify(result,null,2));console.log(result);
