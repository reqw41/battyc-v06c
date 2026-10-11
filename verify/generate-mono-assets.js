'use strict';
const fs=require('fs'),assert=require('assert');
const text=fs.readFileSync('gfx/sprites_no_shadows_2.asm','utf8');
const staticNames=new Set(['spr_lives_indicator','spr_1up','spr_2up','spr_hi','spr_score_digits','spr_separator','spr_magnet_circle_on','spr_magnet_circle_off']);
let count=0,total=0,output='; Generated native column pairs (~cover,lit). Static kind 3 keeps legacy row pairs.\n';
for(const m of text.matchAll(/^(spr_\w+):([\s\S]*?)(?=^spr_\w+:|$(?![\s\S]))/gm)){
 let bytes=[],padding=0;for(const line of m[2].split('\n')){const p=line.split(';')[0].match(/^\s*DEFB\s+(.+)/i);if(p)for(const v of p[1].split(','))bytes.push(parseInt(v.trim().slice(1),16));const d=line.match(/^\s*DS\s+(\d+),0/i);if(d)padding+=+d[1];}
 const original=bytes.slice(),allocated=bytes.length+padding,w=bytes[0],fullH=bytes[1];
 let data;if(staticNames.has(m[1])){data=bytes.slice();for(let i=2;i+1<data.length;i+=2)data[i+1]^=data[i];}
 else {const h=m[1]==='spr_bonus_rocket_1'?Math.min(12,fullH):fullH;data=[w,h];for(let c=0;c<w;c++)for(let y=0;y<h;y++){const i=2+2*(y*w+c),mask=bytes[i]||0,pixel=bytes[i+1]||0;data.push(mask^255,mask&pixel);}count++;total+=data.length;
 // Independent pixel-by-pixel transpose oracle, before startup inversion.
 for(let y=0;y<h;y++)for(let c=0;c<w;c++){const a=2+2*(c*h+y),b=2+2*(y*w+c);assert.equal(data[a+1],(original[b]||0)&(original[b+1]||0));assert.equal(data[a],(original[b]||0)^255);}}
 assert(data.length<=allocated,m[1]);output+=m[1]+':\n';for(let i=0;i<data.length;i+=12)output+=' DEFB '+data.slice(i,i+12).map(v=>'$'+v.toString(16).padStart(2,'0')).join(',')+'\n';if(data.length<allocated)output+=' DS '+(allocated-data.length)+',0\n';
}
fs.writeFileSync('gfx/sprites_mono_native_2.asm',output);fs.writeFileSync('outputs/batty-mono-assets.json',JSON.stringify({nativeAssets:count,nativeBytes:total,staticAssets:staticNames.size,allocationUnchanged:true,passed:true},null,2));console.log({count,total});
