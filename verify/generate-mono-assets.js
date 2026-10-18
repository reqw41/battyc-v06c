'use strict';
const fs=require('fs'),assert=require('assert');
const text=fs.readFileSync('gfx/sprites_no_shadows_2.asm','utf8');
const staticNames=new Set(['spr_score_digits']);
// Native transposition reclaims unused legacy tails. Labels relocate normally;
// helper bounds verify each helper still fits the original reserved tail.
const pacePads={spr_bomb:'mono_pace_start',spr_ball_normal:'mono_pace_white',spr_bat_big:'mono_pace_bat',spr_bat_gun_shift:'mono_pace_shift',spr_bat_normal:'mono_pace_old',spr_spark_1:'mono_pace_wait',spr_ball_normal_shift_1:'mono_pace_dispatch',spr_ball_normal_shift_2:'ui_mono_outline_1',spr_ball_normal_shift_3:'ui_mono_outline_2',spr_ball_normal_shift_4:'ui_outline_byte',spr_ball_normal_shift_5:'mono_window_setup',spr_ball_normal_shift_6:'mono_pace_draw_1',spr_ball_normal_shift_7:'mono_pace_draw_2',spr_bat_gun_1:'mono_bonus_height',spr_bat_big_shift:'ui_glyph_background',spr_bat_gun_2:'ui_clear_line_1',spr_bat_gun_3:'ui_clear_line_2',spr_bat_gun_4:'paper_plane_fill',spr_bird_2:'ui_menu_overlay',spr_bat_normal_shift:'native_rotate',spr_bird_3:'magnet_center_e',spr_bird_4:'magnet_center_locate',spr_bird_5:'magnet_accent_off',spr_bat_right_part:'magnet_center_put',spr_bat_left_part:'magnet_center_stride',spr_big_ball:'magnet_center_read',spr_bat_gun:'magnet_center_read_shift'};
const magnetDisc=(()=>{const b=[];for(const line of text.match(/^spr_magnet_circle_on:([\s\S]*?)(?=^spr_\w+:)/m)[1].split('\n')){const p=line.split(';')[0].match(/^\s*DEFB\s+(.+)/i);if(p)for(const v of p[1].split(','))b.push(parseInt(v.trim().slice(1),16));}return Array.from({length:12},(_,r)=>Array.from({length:13},(_,x)=>b[2+2*(r*b[0]+(x>>3))]>>(7-(x&7))&1));})();
let count=0,total=0,output='; Generated native column pairs (~cover,lit). Static magnets, separators and HUD headings use native columns; score digits retain their separate legacy format.\n';
for(const m of text.matchAll(/^(spr_\w+):([\s\S]*?)(?=^spr_\w+:|$(?![\s\S]))/gm)){
 let bytes=[],padding=0;for(const line of m[2].split('\n')){const p=line.split(';')[0].match(/^\s*DEFB\s+(.+)/i);if(p)for(const v of p[1].split(','))bytes.push(parseInt(v.trim().slice(1),16));const d=line.match(/^\s*DS\s+(\d+),0/i);if(d)padding+=+d[1];}
 let allocated=bytes.length+padding;
 // Magnets are opaque discs in the RGB planes. The ZX mask also covers the dithered shadow and the off
 // picture borrows the right rim from the on picture; give both the same clean, symmetric 25x23 disc.
 if(/^spr_magnet_circle_(on|off)$/.test(m[1])){const [mw]=bytes,lit=(r,x)=>x<8*mw&&r<bytes[1]?(bytes[2+2*(r*mw+(x>>3))]&bytes[3+2*(r*mw+(x>>3))])>>(7-(x&7))&1:0,onH=m[1].endsWith('_on')?bytes[1]:24,out=[4,onH];
  // Both states share a grey ring: every disc pixel further than 10.8 from the centre
  // (the wider ZX ring of the off picture, 9.2..10.8, is dropped to leave more room inside).
  // On: mask plane = grey ring + cyan body (plane C and E), lit plane = cyan body; the rest of the disc
  // (the arrows and the core) is red.
  const isOn=m[1].endsWith('_on'),coreOn=[0x00,0x1c,0x3e,0x3e,0x3e,0x3e,0x1c,0x00]; // red here; the core pass turns it yellow with a white centre
  // Off: mask = the disc, lit = the grey marks; the ring comes from the on picture. The wide ZX ring of the
  // off picture is dropped whole: it is the 4-connected lit region that reaches the new ring zone.
  const coreOff=[0x1c,0x3e,0x7f,0x7f,0x7f,0x7f,0x3e,0x1c],oldRing=new Set();
  if(!isOn){const far=(r,x)=>Math.hypot(x-12,(r-11.5)*25/24)>10.8,queue=[];for(let r=0;r<24;r++)for(let x=0;x<25;x++)if(lit(r,x)&&far(r,x)){oldRing.add(r*32+x);queue.push([r,x]);}
   while(queue.length){const [r,x]=queue.pop();for(const [dr,dx]of[[1,0],[-1,0],[0,1],[0,-1]]){const rr=r+dr,xx=x+dx;if(rr>=0&&rr<24&&xx>=0&&xx<25&&lit(rr,xx)&&!oldRing.has(rr*32+xx)){oldRing.add(rr*32+xx);queue.push([rr,xx]);}}}}
  for(let r=0;r<onH;r++)for(let c=0;c<4;c++){let mask=0,pixel=0;for(let b=0;b<8;b++){const x=c*8+b,cov=r<24&&x<25&&magnetDisc[Math.min(r,23-r)][Math.min(x,24-x)];if(cov){
   const dist=Math.hypot(x-12,(r-11.5)*25/24),ring=dist>10.8,core=r>=8&&r<16&&x>=8&&x<16&&(coreOn[r-8]>>(15-x)&1);
   if(isOn){const nearRing=[-1,0,1].some(dr=>[-1,0,1].some(dx=>{const rr=r+dr,xx=x+dx;return rr>=0&&rr<24&&xx>=0&&xx<25&&magnetDisc[Math.min(rr,23-rr)][Math.min(xx,24-xx)]&&Math.hypot(xx-12,(rr-11.5)*25/24)>10.8;}));
    // The tips of the four diagonal arrows are straightened to 45 degrees: (7,5) moves to (6,5), mirrored.
    const fr=Math.min(r,23-r),fx=Math.min(x,24-x),tipOff=fr===7&&fx===5,tipOn=fr===6&&fx===5;
    const red=tipOn||(!tipOff&&!ring&&!nearRing&&(!lit(r,x)||core)); // the arrows stop one pixel short of the ring
    if(!red)mask|=128>>b;if(!red&&!ring)pixel|=128>>b;}
   else{const ball=r>=8&&r<16&&x>=8&&x<16&&(coreOff[r-8]>>(15-x)&1);mask|=128>>b;if(!ring&&!ball&&lit(r,x)&&!oldRing.has(r*32+x))pixel|=128>>b;}}}out.push(mask,pixel);}
  bytes=out;allocated=Math.max(allocated,2+4*onH*2);}
 if(m[1]==='spr_big_ball'){const [ow,oh]=bytes;for(let y=0;y<oh;y++)for(let c=1;c<ow;c++)assert.equal(bytes[3+2*(y*ow+c)],0,'Smash has lit spill');bytes=[1,oh,...Array.from({length:oh},(_,y)=>bytes.slice(2+2*y*ow,4+2*y*ow)).flat()];}
 // The Double Play separator has no shadow: keep only its first byte column (body and outline).
 if(m[1]==='spr_separator'){const [sw,sh]=bytes;for(let y=0;y<sh;y++)for(let c=1;c<sw;c++){bytes[2+2*(y*sw+c)]=0;bytes[3+2*(y*sw+c)]=0;}}
 const original=bytes.slice(),w=bytes[0],fullH=bytes[1];
 let data;if(staticNames.has(m[1])){data=bytes.slice();for(let i=2;i+1<data.length;i+=2)data[i+1]^=data[i];}
 else {let h=fullH;
 // White-only owners need no trailing rows containing only black coverage.
 if(/^spr_(?:ball_normal(?:_shift_\d+)?|big_ball|bomb|bonus_(?!rocket)\w+)$/.test(m[1]))while(h>1&&Array.from({length:w},(_,c)=>bytes[2+2*((h-1)*w+c)]&bytes[3+2*((h-1)*w+c)]).every(v=>!v))h--;
 assert(h<=32,m[1]+' exceeds pacing row tables');data=[w,h];for(let c=0;c<w;c++)for(let y=0;y<h;y++){const i=2+2*(y*w+c),mask=bytes[i]||0,pixel=bytes[i+1]||0;data.push(mask^255,mask&pixel);}count++;total+=data.length;
 // Independent pixel-by-pixel transpose oracle, before startup inversion.
 for(let y=0;y<h;y++)for(let c=0;c<w;c++){const a=2+2*(c*h+y),b=2+2*(y*w+c);assert.equal(data[a+1],(original[b]||0)&(original[b+1]||0));assert.equal(data[a],(original[b]||0)^255);}}
 if(/^spr_ball_normal_shift_[1-7]$/.test(m[1])){allocated-=data.length;data=[];}
 assert(data.length<=allocated,m[1]);output+=m[1]+':\n';for(let i=0;i<data.length;i+=12)output+=' DEFB '+data.slice(i,i+12).map(v=>'$'+v.toString(16).padStart(2,'0')).join(',')+'\n';if(data.length<allocated){const pad=allocated-data.length,helper=pacePads[m[1]];if(helper){output+=` INCLUDE \"routines/${helper}.asm\"\nMonoPadEnd_${m[1]}:\n ASSERT $ <= ${m[1]}+${allocated}\n IF $ < ${m[1]}+${allocated}\n DS ${m[1]}+${allocated}-$,0\n ENDIF\n`;}else output+=' DS '+pad+',0\n';}
}
output=output.replace(/(MonoPadEnd_\w+:\n ASSERT[^\n]+\n) IF[^\n]+\n DS[^\n]+\n ENDIF\n/g,'$1').replace(/^ DS \d+,0\n/gm,'');
fs.writeFileSync('gfx/sprites_mono_native_2.asm',output.replace(/spr_bullet_2:[\s\S]*?(?=spr_bullet_blast_1:)/,'spr_bullet_2 EQU spr_bullet_1\n'));fs.writeFileSync('outputs/batty-mono-assets.json',JSON.stringify({nativeAssets:count,nativeBytes:total,staticAssets:staticNames.size,allocationUnchanged:false,obsoleteBallShiftsReclaimed:182,passed:true},null,2));console.log({count,total});

// The early HUD bank was still row-major. Keep digit data in its separate
// legacy digit format, but transpose the three fixed score headings.
// The build language (BATTY_LANG=ru|en) picks the font and the headings; the result goes to lang/<language>/.
const lang=process.env.BATTY_LANG||'ru';assert(['ru','en'].includes(lang),'BATTY_LANG must be ru or en');
const fontBytes=[...fs.readFileSync('lang/'+lang+'/font.asm','utf8').matchAll(/^\s*DEFB\s+([^;]+)/gm)].flatMap(m=>m[1].trim().split(',').map(v=>parseInt(v.trim().slice(1),16)));
const digitData=[10,8];for(let d=0;d<10;d++)for(let r=0;r<8;r++)digitData.push(255,255^(r<6?fontBytes[d*6+r]:0));
const hud=fs.readFileSync('gfx/sprites_with_masks_1.asm','utf8').replace(/spr_score_digits:[\s\S]*?(?=^spr_\w+:|$(?![\s\S]))/m,'spr_score_digits:\n'+Array.from({length:Math.ceil(digitData.length/12)},(_,i)=>' DEFB '+digitData.slice(i*12,i*12+12).map(v=>'$'+v.toString(16).padStart(2,'0')).join(',')).join('\n')+'\n').replace(/^(spr_(?:1up|2up|hi)):[\s\S]*?(?=^spr_\w+:|$(?![\s\S]))/gm,(block,name)=>{
 const bytes=[];for(const line of block.split('\n')){const m=line.split(';')[0].match(/^\s*DEFB\s+(.+)/i);if(m)for(const v of m[1].split(','))bytes.push(parseInt(v.trim().slice(1),16));}
 const codes=(lang==='en'?{spr_1up:[1,30,25],spr_2up:[2,30,25],spr_hi:[17,18]}:{spr_1up:[18,13,26,24,20,44,1],spr_2up:[18,13,26,24,20,44,2],spr_hi:[26,15,20,24,26,14]})[name];const w=codes.length,h=bytes[1];bytes.length=0;for(let y=0;y<h;y++)for(let c=0;c<w;c++){const v=y<6?fontBytes[codes[c]*6+y]:0;bytes[2+2*(y*w+c)]=v;bytes[3+2*(y*w+c)]=v;}const data=[w,h];for(let c=0;c<w;c++)for(let y=0;y<h;y++){const i=2+2*(y*w+c);data.push(bytes[i]^255,bytes[i]&bytes[i+1]);}
 return name+':\n'+Array.from({length:Math.ceil(data.length/12)},(_,i)=>' DEFB '+data.slice(i*12,i*12+12).map(v=>'$'+v.toString(16).padStart(2,'0')).join(',')).join('\n')+'\n';
});fs.writeFileSync('lang/'+lang+'/sprites_mono_native_1.asm',hud);
