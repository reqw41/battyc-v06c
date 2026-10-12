'use strict';
const assert=require('assert'),fs=require('fs');
let seed=8080;const rnd=n=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n;};
const size=8192;let screen=new Uint8Array(size),old=[];let clears=0,repeat=0;
function bitmap(objects){const out=new Uint8Array(size);for(const o of objects)for(let c=0;c<o.cols;c++)for(let r=0;r<o.rows;r++)out[(o.col+c)*256+o.top-r]|=o.data[c*o.rows+r];return out;}
for(let f=0;f<2000;f++){const next=Array.from({length:rnd(12)},()=>{const cols=1+rnd(6),rows=1+rnd(28),col=rnd(33-cols),top=25+rows+rnd(199-rows);return {col,top,cols,rows,data:Uint8Array.from({length:cols*rows},()=>rnd(256))};});const done=new Uint8Array(128),addresses=new Set();for(const o of old)for(let c=o.col;c<o.col+o.cols;c++){const bottom=(o.top-o.rows+1)&248,top=o.top|7;for(let row=top;row>=bottom;row-=8){const tile=row>>3,idx=c*4+(tile>>3),mask=1<<(tile&7);if(done[idx]&mask)continue;done[idx]|=mask;for(let y=row;y>row-8;y--){const at=c*256+y;assert(!addresses.has(at));addresses.add(at);screen[at]=0;clears++;}}}const current=bitmap(next);for(let i=0;i<size;i++)screen[i]|=current[i];assert.deepEqual(screen,current);old=next;}
const result={frames:2000,clearedBytes:clears,repeatedClears:repeat,passed:true};fs.writeFileSync('outputs/new-folder-clear-redraw-js.json',JSON.stringify(result,null,2));console.log(result);
