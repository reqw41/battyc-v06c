'use strict';
const assert=require('assert'),fs=require('fs');
// Old E/F interpretation vs native (~cover,lit) encoding. Every byte pair,
// all background bytes and destination planes; include coloured enemy rows.
let cases=0;
for(let cover=0;cover<256;cover++)for(let rawBlack=0;rawBlack<256;rawBlack++){
 const black=rawBlack&cover,lit=cover^black,keep=cover^255;
 const encodedKeep=(~cover)&255,encodedLit=cover^(rawBlack&cover);
 assert.equal(encodedKeep,keep);assert.equal(encodedLit,lit);
 for(const enemy of [false,true]){
  const oldE=enemy?black:cover,oldF=enemy?cover:black;
  assert.equal((oldE|oldF)^255,keep);assert.equal(oldE^oldF,lit);
  for(let bg=0;bg<256;bg++)for(let plane=0;plane<3;plane++){
   const oldPixel=plane===2?oldE^oldF:oldE&~oldF;
   const newPixel=enemy&&plane!==2?0:lit;
   assert.equal((bg&~(oldE|oldF))|oldPixel,(bg&keep)|newPixel);cases++;
  }
 }
}
// Four-row fallthrough dispatch must consume precisely the clipped count,
// including enemies whose visible region ends before the colour boundary.
let rowCases=0;
for(let height=1;height<=64;height++)for(let rows=1;rows<=height;rows++)for(const enemy of [false,true]){
 const white=enemy?Math.min(height>>1,rows):rows,colored=rows-white;
 const groups=(white+3)>>2,start=[0,3,2,1][white&3];
 let visited=white?4-start+4*(groups-1):0;
 assert.equal(visited,white);assert.equal(visited+colored,rows);rowCases++;
}
// Execute the real cache builder with all mask/raw-black byte combinations.
const {make}=require('./vector_harness'),crypto=require('crypto');
const E=make('batty.rom','batty.sym');E.memory.bytes=E.memory.bytes.slice(0,65536);
const src=0x6a00,dst=E.L.SUScratch;
assert(src>E.L.BATTYCODE_END && src+4<E.L.StackFloor);
const w=(a,v)=>E.memory.write(a,v),ptr=(a,v)=>{w(a,v&255);w(a+1,v>>8);};
let nativePairs=0;
for(let mask=0;mask<256;mask++)for(let black=0;black<256;black++){
 w(src,1);w(src+1,1);w(src+2,mask);w(src+3,black);
 ptr(E.L.SpriteCacheOriginal,src);ptr(E.L.SpriteCacheBuffer,dst);
 w(E.L.SpriteCacheHeight,1);w(E.L.SpriteCacheShift,0);
 E.cpu.pc=E.L.SpriteCacheBuild;E.cpu.sp=E.L.stack-2;ptr(E.cpu.sp,256);E.cpu.iff=false;
 let instructions=0;
 while(E.cpu.pc!==256){assert(++instructions<1000);E.cpu.instruction();E.io.commit();}
 assert.equal(E.rd(dst),1);assert.equal(E.rd(dst+1),1);
 assert.equal(E.rd(dst+2),mask^255);assert.equal(E.rd(dst+3),mask&~black);nativePairs++;
}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),bytePlaneCases:cases,rowCases,nativeCachePairs:nativePairs,cacheBytesPerCell:2,extraRAMBytes:0,passed:true};
fs.writeFileSync('outputs/batty-three-native-render-models.json',JSON.stringify(result,null,2));console.log(result);
