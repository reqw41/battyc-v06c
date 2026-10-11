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
 // New lit pixels appear first; old rectangles are never cleared wholesale.
 for(const o of current)for(let c=0;c<o.cols;c++)for(let r=0;r<o.rows;r++){video[address(o,c,r)]|=o.bits[c*o.rows+r];writes++;}
 for(const old of previous){const candidates=current.filter(o=>overlapsRect(old,o));if(candidates.length>1)overlaps++;for(let c=0;c<old.cols;c++)for(let r=0;r<old.rows;r++){const a=address(old,c,r);let value=0;for(const o of candidates){const dx=old.x+c-o.x,dy=o.top-(old.top-r);if(dx>=0&&dx<o.cols&&dy>=0&&dy<o.rows)value|=o.bits[dx*o.rows+dy];}assert.equal(value,expected[a]);video[a]=value;writes++;}}
 assert.deepStrictEqual(video,expected);previous=current;
}
const result={frames:2500,writes,overlappingOldRects:overlaps,saveUnder:false,finalSpriteUnion:true,passed:true};fs.writeFileSync('outputs/batty-three-plus-one-model.json',JSON.stringify(result,null,2));console.log(result);
