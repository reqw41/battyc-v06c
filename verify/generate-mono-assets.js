'use strict';
const fs=require('fs'),assert=require('assert');
const text=fs.readFileSync('gfx/sprites_no_shadows_2.asm','utf8');
const staticNames=new Set(['spr_score_digits']);
// Native transposition trims unused legacy tails. Reuse only those tails;
// assembler bounds keep every following graphic label at its original address.
const pacePads={spr_bomb:'mono_pace_start',spr_ball_normal:'mono_pace_white',spr_bat_big:'mono_pace_bat',spr_bat_gun_shift:'mono_pace_shift',spr_bat_normal:'mono_pace_old',spr_spark_1:'mono_pace_wait',spr_ball_normal_shift_1:'mono_pace_dispatch',spr_ball_normal_shift_2:'ui_mono_outline_1',spr_ball_normal_shift_3:'ui_mono_outline_2',spr_ball_normal_shift_4:'ui_outline_byte',spr_ball_normal_shift_5:'mono_window_setup',spr_ball_normal_shift_6:'mono_pace_draw_1',spr_ball_normal_shift_7:'mono_pace_draw_2',spr_bat_gun_1:'mono_bonus_height',spr_bat_big_shift:'ui_glyph_background',spr_bat_gun_2:'ui_clear_line_1',spr_bat_gun_3:'ui_clear_line_2',spr_bat_gun_4:'paper_plane_fill',spr_bird_2:'ui_menu_overlay',spr_bat_normal_shift:'native_rotate',spr_bird_3:'magnet_center_e',spr_bird_4:'magnet_center_locate',spr_bird_5:'magnet_accent_off',spr_bat_right_part:'magnet_center_put',spr_bat_left_part:'magnet_center_stride',spr_big_ball:'magnet_center_read',spr_bat_gun:'magnet_center_read_shift'};
let count=0,total=0,output='; Generated native column pairs (~cover,lit). Static magnets, separators and HUD headings use native columns; score digits retain their separate legacy format.\n';
for(const m of text.matchAll(/^(spr_\w+):([\s\S]*?)(?=^spr_\w+:|$(?![\s\S]))/gm)){
 let bytes=[],padding=0;for(const line of m[2].split('\n')){const p=line.split(';')[0].match(/^\s*DEFB\s+(.+)/i);if(p)for(const v of p[1].split(','))bytes.push(parseInt(v.trim().slice(1),16));const d=line.match(/^\s*DS\s+(\d+),0/i);if(d)padding+=+d[1];}
 const allocated=bytes.length+padding;
 if(m[1]==='spr_big_ball'){const [ow,oh]=bytes;for(let y=0;y<oh;y++)for(let c=1;c<ow;c++)assert.equal(bytes[3+2*(y*ow+c)],0,'Smash has lit spill');bytes=[1,oh,...Array.from({length:oh},(_,y)=>bytes.slice(2+2*y*ow,4+2*y*ow)).flat()];}
 const original=bytes.slice(),w=bytes[0],fullH=bytes[1];
 let data;if(staticNames.has(m[1])){data=bytes.slice();for(let i=2;i+1<data.length;i+=2)data[i+1]^=data[i];}
 else {let h=fullH;
 // White-only owners need no trailing rows containing only black coverage.
 if(/^spr_(?:ball_normal(?:_shift_\d+)?|big_ball|bomb|bonus_(?!rocket)\w+)$/.test(m[1]))while(h>1&&Array.from({length:w},(_,c)=>bytes[2+2*((h-1)*w+c)]&bytes[3+2*((h-1)*w+c)]).every(v=>!v))h--;
 assert(h<=32,m[1]+' exceeds pacing row tables');data=[w,h];for(let c=0;c<w;c++)for(let y=0;y<h;y++){const i=2+2*(y*w+c),mask=bytes[i]||0,pixel=bytes[i+1]||0;data.push(mask^255,mask&pixel);}count++;total+=data.length;
 // Independent pixel-by-pixel transpose oracle, before startup inversion.
 for(let y=0;y<h;y++)for(let c=0;c<w;c++){const a=2+2*(c*h+y),b=2+2*(y*w+c);assert.equal(data[a+1],(original[b]||0)&(original[b+1]||0));assert.equal(data[a],(original[b]||0)^255);}}
 assert(data.length<=allocated,m[1]);output+=m[1]+':\n';for(let i=0;i<data.length;i+=12)output+=' DEFB '+data.slice(i,i+12).map(v=>'$'+v.toString(16).padStart(2,'0')).join(',')+'\n';if(data.length<allocated){const pad=allocated-data.length,helper=pacePads[m[1]];if(helper){output+=` INCLUDE \"routines/${helper}.asm\"\nMonoPadEnd_${m[1]}:\n ASSERT $ <= ${m[1]}+${allocated}\n IF $ < ${m[1]}+${allocated}\n DS ${m[1]}+${allocated}-$,0\n ENDIF\n`;}else output+=' DS '+pad+',0\n';}
}
fs.writeFileSync('gfx/sprites_mono_native_2.asm',output);fs.writeFileSync('outputs/batty-mono-assets.json',JSON.stringify({nativeAssets:count,nativeBytes:total,staticAssets:staticNames.size,allocationUnchanged:true,passed:true},null,2));console.log({count,total});

// The early HUD bank was still row-major. Keep digit data in its separate
// legacy digit format, but transpose the three fixed score headings.
const fontBytes=[...fs.readFileSync('gfx/font.asm','utf8').matchAll(/^\s*DEFB\s+([^;]+)/gm)].flatMap(m=>m[1].trim().split(',').map(v=>parseInt(v.trim().slice(1),16)));
const digitData=[10,8];for(let d=0;d<10;d++)for(let r=0;r<8;r++)digitData.push(255,255^(r<6?fontBytes[d*6+r]:0));
const hud=fs.readFileSync('gfx/sprites_with_masks_1.asm','utf8').replace(/spr_score_digits:[\s\S]*?(?=^spr_\w+:|$(?![\s\S]))/m,'spr_score_digits:\n'+Array.from({length:Math.ceil(digitData.length/12)},(_,i)=>' DEFB '+digitData.slice(i*12,i*12+12).map(v=>'$'+v.toString(16).padStart(2,'0')).join(',')).join('\n')+'\n').replace(/^(spr_(?:1up|2up|hi)):[\s\S]*?(?=^spr_\w+:|$(?![\s\S]))/gm,(block,name)=>{
 const bytes=[];for(const line of block.split('\n')){const m=line.split(';')[0].match(/^\s*DEFB\s+(.+)/i);if(m)for(const v of m[1].split(','))bytes.push(parseInt(v.trim().slice(1),16));}
 const codes={spr_1up:[1,30,25],spr_2up:[2,30,25],spr_hi:[17,18]}[name];const [w,h]=bytes;for(let y=0;y<h;y++)for(let c=0;c<w;c++){const v=y<6?fontBytes[codes[c]*6+y]:0;bytes[2+2*(y*w+c)]=v;bytes[3+2*(y*w+c)]=v;}const data=[w,h];for(let c=0;c<w;c++)for(let y=0;y<h;y++){const i=2+2*(y*w+c);data.push(bytes[i]^255,bytes[i]&bytes[i+1]);}
 return name+':\n'+Array.from({length:Math.ceil(data.length/12)},(_,i)=>' DEFB '+data.slice(i*12,i*12+12).map(v=>'$'+v.toString(16).padStart(2,'0')).join(',')).join('\n')+'\n';
});fs.writeFileSync('gfx/sprites_mono_native_1.asm',hud);
