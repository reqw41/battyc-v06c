'use strict';
const assert=require('assert'),fs=require('fs');
// Inclusive descending video row intervals. Keep the most recent connected
// union per byte column. Disjoint intervals replace the cache conservatively.
function uncovered(old,done){const [b,t]=old;if(!done||b>done[1]+1||t<done[0]-1)return {spans:[old],done:old};const [cb,ct]=done,spans=[];if(t>ct)spans.push([ct+1,t]);if(b<cb)spans.push([b,cb-1]);return {spans,done:[Math.min(b,cb),Math.max(t,ct)]};}
let seed=8080,cases=0,pixels=0,saved=0;const rnd=n=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n;};
for(let run=0;run<10000;run++){let done=null;const visited=new Set();for(let i=0;i<11;i++){const b=25+rnd(175),t=Math.min(224,b+rnd(32)),old=[b,t],r=uncovered(old,done);const expected=[];for(let y=b;y<=t;y++)if(!done||y<done[0]||y>done[1])expected.push(y);const actual=r.spans.flatMap(([l,h])=>Array.from({length:h-l+1},(_,i)=>l+i)).sort((a,b)=>a-b);assert.deepEqual(actual,expected);for(const y of actual)visited.add(y);for(let y=r.done[0];y<=r.done[1];y++)assert(visited.has(y),'merged a gap that has not been composed');pixels+=t-b+1;saved+=t-b+1-actual.length;done=r.done;cases++;}}
// Three overlapping Smash-sized old regions: exact union, each byte once.
let done=null;const seen=new Set();for(const old of [[100,107],[103,110],[106,113]]){const r=uncovered(old,done);for(const [b,t]of r.spans)for(let y=b;y<=t;y++){assert(!seen.has(y));seen.add(y);}done=r.done;}assert.equal(seen.size,14);
const report={cases,pixels,saved,conservativeCache:true,overlapUnionBytes:seen.size,passed:true};fs.writeFileSync('outputs/compositor-js-model.json',JSON.stringify(report,null,2));console.log(report);
module.exports={uncovered};
