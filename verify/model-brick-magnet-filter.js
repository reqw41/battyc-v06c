'use strict';
const assert=require('assert'),fs=require('fs');
// The centre and its one-bit fringe touch four byte columns and ten rows.
// The fast E writer in a fringe updates a full byte, so reject by BYTE
// footprints, not by only the single bit that belongs to the brick outline.
function touches(x,y,magnets){const l=(x>>3)-1,r=(x>>3)+3,t=y-1,b=y+9;return magnets.some(m=>{const ml=(m.x-5)>>3,mt=m.y-5;return l<ml+5&&r>ml&&t<mt+30&&b>mt;});}
let cases=0,misses=0,fast=0;
for(let x=8;x<248;x+=16)for(let y=32;y<128;y+=8)for(let mx=5;mx<250;mx+=7)for(let my=5;my<190;my+=11){const m={x:mx,y:my},hit=touches(x,y,[m]);let oracle=false;for(let c=(x>>3)-1;c<(x>>3)+3;c++)for(let row=y-1;row<y+9;row++)if(c>=((mx-5)>>3)&&c<((mx-5)>>3)+5&&row>=my-5&&row<my-5+30)oracle=true;assert.equal(hit,oracle);cases++;if(!hit)fast++;}
// Touching the next bit in the SAME byte must stay on the masked slow path.
assert(touches(120,48,[{x:144,y:48}]));assert(!touches(120,48,[{x:165,y:48}]));
const result={cases,fast,misses,byteAccurate:true,passed:true};fs.writeFileSync('outputs/new-folder-magnet-filter-js.json',JSON.stringify(result,null,2));console.log(result);module.exports={touches};
