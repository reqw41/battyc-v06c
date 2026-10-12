'use strict';
const fs=require('fs'),assert=require('assert'),crypto=require('crypto'),{make}=require('./vector_harness');
const E=make('batty.rom','batty.sym'),B=make('../../outputs/batty-three-plus-one-cpc-bricks.rom','../../outputs/batty-three-plus-one-cpc-bricks.sym');
for(const Q of[E,B]){Q.memory.bytes=Q.memory.bytes.slice(0,65536);Q.run(100);}
const w=(Q,a,v)=>Q.memory.write(a,v),ptr=(Q,a,v)=>{w(Q,a,v);w(Q,a+1,v>>8);};
function call(Q,n){Q.cpu.pc=Q.L[n];Q.cpu.sp=Q.L.stack-2;ptr(Q,Q.cpu.sp,256);Q.cpu.iff=false;let k=0;while(Q.cpu.pc!==256 && !(n==='SetPaletteLevel'&&Q.cpu.pc===Q.L.SetPaletteGame)){assert(++k<2e6,n);Q.cpu.instruction();Q.io.commit();}}
let textureCases=0,paletteCases=0;
for(let theme=0;theme<4;theme++){
 for(const Q of[E,B]){call(Q,'planes_reset');Q.cpu.set_rp(4,Q.L['spr_level_texture_'+(theme+1)]);call(Q,'NativeFillTexture');}
 for(let p=0;p<4;p++)for(let c=0;c<32;c++)for(let lo=0;lo<256;lo++){
  const y=224-lo,filled=y>=0&&y<=218;
  // Continue the old 16-row texture downwards without changing the old field.
  const sample=224-(y&15),want=filled&&p>=2?B.rd(0x8000+p*8192+c*256+sample):p===3?255:0;
  assert.equal(E.rd(0x8000+p*8192+c*256+lo),want,'texture phase/extent '+JSON.stringify({theme,p,c,lo}));
 }
 w(E,E.L.current_level_number_1up,theme);call(E,'SetPaletteLevel');
 assert.equal(E.rd(E.L.ScreenScroll),5);assert.equal((E.rd(E.L.ScreenScroll)-6)&255,255);
 assert.equal(E.rd(E.L.PaletteGame+1),B.rd(B.L[theme===0?'LevelTextureColors':'LevelPaperColors']+theme));
 assert.equal(E.rd(E.L.PaletteGame+2),B.rd(B.L[theme===0?'LevelPaperColors':'LevelTextureColors']+theme));
 textureCases++;paletteCases++;
}
// The palette routine waits for an IRQ; isolate the synchronous frame painter.
const menuOpcode=E.rd(E.L.SetPaletteMenu);w(E,E.L.SetPaletteMenu,0xc9);call(E,'draw_frame');w(E,E.L.SetPaletteMenu,menuOpcode);
for(let r=0;r<256;r++)for(let x=0;x<256;x++){
 let ink=0;const lo=255-r,mask=128>>(x&7);
 for(const [p,b] of [[0x8000,8],[0xa000,4],[0xc000,2],[0xe000,1]])if(E.rd(p+(x>>3)*256+lo)&mask)ink|=b;
 assert.equal(ink,r<2||r>=254||x<2||x>=254?7:1,'full-screen menu frame '+JSON.stringify({x,r}));
}
// Devices must be distinct: keyboard ignores joystick and joystick ignores keys.
let inputCases=0;
for(let device=0;device<2;device++)for(const keys of[255,253,239,123])for(const joy of[255,254,253,191]){
 w(E,E.L.KeyLine0,keys);w(E,E.L.KeyLine7,255);w(E,E.L.JoystickP,joy);E.cpu.set_a(device);call(E,'get_control_state');
 const k=~keys&255,j=~joy&255,want=12|(device?((j&3)|((j&192)?16:0)):((k&66?1:0)|(k&17?2:0)|(k&172?16:0)));
 assert.equal(E.rd(E.L.ctrl_btns_pressed),want,'device filter');inputCases++;
}
for(let value=0;value<4;value++){w(E,E.L.ctrl_type_1up,value);w(E,E.L.ctrl_type_2up,value);call(E,'NormalizeMenuControls');assert.equal(E.rd(E.L.ctrl_type_1up),value&1);assert.equal(E.rd(E.L.coord_ctrl_1up+1),value&1?154:130);assert.equal(E.rd(E.L.coord_ctrl_2up+1),value&1?154:130);}
const result={romSHA256:crypto.createHash('sha256').update(fs.readFileSync('batty.rom')).digest('hex'),textureCases,paletteCases,firstThemeColoursSwapped:true,otherThemesUnchanged:true,oldTexturePhasePreserved:true,textureEndsAtScreenRow:255,menuFramePixels:65536,inputCases,keyboardAndJoystickAreDistinct:true,twoMenuControlChoices:true,passed:true};
fs.writeFileSync('outputs/batty-full-height-layout.json',JSON.stringify(result,null,2));console.log(result);
