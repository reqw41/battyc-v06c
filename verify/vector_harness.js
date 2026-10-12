// Общая обвязка эмулятора vector06js для замеров задачи #5 (фликер).
//
// ===== КОНТРАКТ МЕТРИК 2026-08-09 (для агента, правящего verify/*) ==================
// Геометрия объекта при ВЫВОДЕ: слот+0x96 pending, +0x97 hi0, +0x98 lo0, +0x99 ncols,
//   +0x9B hi0c, +0x9F hi0b-для-вывода (+0x9A — копия для сейва, дедуп может обнулить).
// Шапка save-under +0..+5 = фон под ПРОШЛЫМ/сохранённым габаритом, не то, что рисует
//   vec_spr_show / vso_merge1. Читать +2/+3 для Ytop вывода — ОШИБКА.
// Слитый путь: vso_merge1 (+ te=-1, дыры нет) и t1 пары = конец vpr_wr при vpr_def≠0.
// Стек-блит пары (#53): атрибуция слота через vpz_pa/vpz_pb (см. hero_atomic).
// A/B сборок: ввод по ИГРОВЫМ ТИКАМ (beam_ab / --ticks), не по номеру кадра.
// Nested IRQ false-late: beam_late_raster / экранный кадр в hero_atomic.
// Приёмка фликера: beam_ab + beam_tear + beam_color + hero_atomic.
// ОТКАТ правок 2026-08-09: смотри блоки «АУДИТ МЕТРИК» в beam_late/top/raster/z80/
//   jump_top_beam/beam_anchor; точечные откаты описаны там же рядом с кодом.
"use strict";
const fs=require("fs"),vm=require("vm"),zlib=require("zlib");
const base=process.env.VECTOR06JS_ROOT||"/Users/boris/Projects/vector06js";
function make(romPath,symPath){
  const g={};g.window=g;g.document={createElement:()=>fc(),getElementById:()=>fc()};
  function fcx(){return{createImageData:()=>({data:new Uint8ClampedArray(4)}),putImageData:()=>{},getImageData:()=>({data:new Uint8ClampedArray(4)}),drawImage:()=>{},fillRect:()=>{},save:()=>{},restore:()=>{},scale:()=>{},setTransform:()=>{}};}
  function fc(){return{width:0,height:0,style:{},getContext:()=>fcx()};}
  g.requestAnimationFrame=()=>0;g.setTimeout=()=>0;g.print=()=>0;
  g.console={log(){},debug(){},warn(){},error(){},info(){}};
  const ctx=vm.createContext(g);
  for(const f of ["i8080-js/i8080_trace.js","i8080-js/i8080_disasm.js","i8080-js/i8080.js","src/fili.js","src/ay.js","src/fd1793.js","src/fddimage.js","src/i8253.js","src/io.js","src/keyboard.js","src/memory.js","src/sound.js","src/tv.js"])
    vm.runInContext(fs.readFileSync(base+"/"+f,"utf8"),ctx,{filename:f});
  const memory=new ctx.Memory(),keyboard=new ctx.Keyboard(),timer=new ctx.I8253(),ay=new ctx.AY(),
        floppy=new(ctx.Floppy().FD1793)(),io=new ctx.IO(keyboard,timer,memory,ay,floppy);
  const cpu=new ctx.I8080(memory,io),tape={advance:()=>{},sample:0,reset:()=>{}},
        v06c=new ctx.Vector06c(cpu,memory,io,ay,tape);
  const W=576,H=288;
  v06c.bmp=new Uint32Array(W*H);v06c.displayFrame=()=>{};v06c.check_breakpoint=()=>false;v06c.dbg=null;
  // soundStep НЕ глушим: он тактует ВИ53, на нём часы музыки (правило задачи #5).
  const img=new Uint8Array(fs.readFileSync(romPath));
  memory.init_from_array(img.subarray(0,0x10000),0x100);memory.detach_boot&&memory.detach_boot();
  cpu.pc=0x100;cpu.sp=0xc300;cpu.iff=false;
  const L={};for(const l of fs.readFileSync(symPath,"latin1").split("\n")){
    const m=l.match(/^(\S+):\s+EQU\s+0x([0-9A-Fa-f]+)/);if(m)L[m[1]]=parseInt(m[2],16);}
  const rd=a=>memory.bytes[memory.tobank(a&0xffff)];
  const key=(c,d)=>{const e={which:c,keyCode:c,preventDefault(){},stopPropagation(){}};d?keyboard.keyDown(e):keyboard.keyUp(e);};
  const run=n=>{for(let i=0;i<n;i++)v06c.oneInterrupt(true);};
  // Такты от момента запроса IRQ (raster_line=0, raster_pixel=176). Кадр = 59904 такта.
  const FRAME=59904;
  function cyc(){const f=v06c.filler;if(!f)return 0;
    let p=(f.raster_line*768+f.raster_pixel)-176; if(p<0)p+=312*768; return (p/4)|0;}
  // Луч: картинка = растровые строки 40..295; при vec_vscroll=V экранная строка r
  // показывает fb-строку lo=(V-r)&255, то есть r=(V-lo)&255. Время луча = (40+r)*192-44.
  // [ЗАДАЧА#56] V БОЛЬШЕ НЕ 0x1F: табло уехало в кайму, картинка перецентрована (V=0x27).
  // Значение берём ИЗ .sym — так же, как BEAM0 в beam_ab/beam_late/beam_tear/beam_color.
  // ОТКАТ: const beamOfLo=lo=>{const r=(31-lo)&255;return (40+r)*192-44;};
  const VS=(L.vec_vscroll===undefined)?0x1F:L.vec_vscroll;
  const beamOfLo=lo=>{const r=(VS-lo)&255;return (40+r)*192-44;};
  const W_=W,H_=H;
  const crcT=(()=>{const t=[];for(let n=0;n<256;n++){let c=n;for(let k=0;k<8;k++)c=c&1?0xEDB88320^(c>>>1):c>>>1;t[n]=c;}return t;})();
  function crc(b){let c=0xffffffff;for(let i=0;i<b.length;i++)c=crcT[(c^b[i])&0xff]^(c>>>8);return c^0xffffffff;}
  function chunk(t,d){const l=Buffer.alloc(4);l.writeUInt32BE(d.length);const tt=Buffer.concat([Buffer.from(t),d]);const c=Buffer.alloc(4);c.writeUInt32BE(crc(tt)>>>0);return Buffer.concat([l,tt,c]);}
  function pngFrom(u32,out){const rgb=Buffer.alloc(W_*H_*3);
    for(let i=0;i<W_*H_;i++){const c=u32[i]>>>0;rgb[i*3]=c&255;rgb[i*3+1]=(c>>8)&255;rgb[i*3+2]=(c>>16)&255;}
    const raw=Buffer.alloc(H_*(W_*3+1));for(let y=0;y<H_;y++){raw[y*(W_*3+1)]=0;rgb.copy(raw,y*(W_*3+1)+1,y*W_*3,(y+1)*W_*3);}
    const ihdr=Buffer.alloc(13);ihdr.writeUInt32BE(W_,0);ihdr.writeUInt32BE(H_,4);ihdr[8]=8;ihdr[9]=2;
    fs.writeFileSync(out,Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk("IHDR",ihdr),chunk("IDAT",zlib.deflateSync(raw)),chunk("IEND",Buffer.alloc(0))]));}
  function png(out){pngFrom(v06c.bmp,out);}
  // «Идеальный» кадр: то, что лежит во фреймбуфере СЕЙЧАС, отрисованное без луча.
  // Палитра берётся из io.Palette (обновляется эмулятором). r=0..255 -> lo=(VS-r)&255,
  // где VS = vec_vscroll из .sym (ЗАДАЧА#56: 0x27, было зашито 0x1F).
  function idealBmp(){
    const out=new Uint32Array(W_*H_);
    const pal=v06c.filler?v06c.filler.palette:io.Palette;
    const bytes=memory.bytes;
    // Batty has separate menu/game scroll settings; use its current setting.
    // This affects completed-screen previews only, not beam timing helpers.
    const scroll=L.ScreenScroll===undefined?VS:rd(L.ScreenScroll);
    for(let r=0;r<256;r++){
      const lo=(scroll-r)&255;
      const sy=r+16;                       // FIRST_VISIBLE_LINE=24, картинка с 40 => 40-24=16
      for(let col=0;col<32;col++){
        const a=0x8000+col*256+lo;
        const p0=bytes[memory.tobank(a)],p1=bytes[memory.tobank(a+0x2000)],
              p2=bytes[memory.tobank(a+0x4000)],p3=bytes[memory.tobank(a+0x6000)];
        for(let b=7;b>=0;b--){
          const idx=((p0>>b)&1)<<3|((p1>>b)&1)<<2|((p2>>b)&1)<<1|((p3>>b)&1);
          const sx=(col*8+(7-b))*2+32;     // CENTER_OFFSET=120, картинка с pixel 152 => (152-120)=32
          const c=pal[idx];
          out[sy*W_+sx]=c;out[sy*W_+sx+1]=c;
        }
      }
    }
    return out;
  }
  return {ctx,memory,keyboard,cpu,v06c,io,L,rd,key,run,cyc,beamOfLo,png,pngFrom,idealBmp,W,H,FRAME};
}
// Дойти до геймплея (GameStatus=5)
//  ВХОД КОМБИНАЦИЕЙ F1+F3, А НЕ ПРОБЕЛОМ (замок читов, 2026-08-11). Читы N/H/E/G/D
//  работают только в партии, запущенной F1+F3; с обычного старта пробелом vec_cheats=0 и
//  весь блок читов в vec_isr пропускается. На этом стенде стоит ПОЛОВИНА инструментов
//  каталога, и многие уводят игру читом N на нужную пирамиду — со стартом пробелом они
//  молча меряли бы не ту сцену (так и вышло при первом прогоне: spr_resid_gate разошёлся
//  с декларацией покрытия, snd_tempo получил пустую выборку, bonus_ending_gate — молчащий
//  чит E). Пробел здесь не нажимается ни разу: F1+F3 запускают партию сами (vec_f15_scan
//  дописывает бит SPACE в образ ряда 8, старт идёт штатным chkPushAnyKey -> StartGame_0).
//  Клавиши ОТПУСКАЕМ на выходе — иначе остались бы зажатыми на весь замер.
//  [2026-09-11] ЗАПАСНОЙ ВХОД ПРОБЕЛОМ. В трёхплоскостной линии читы сняты (050301b) и
//  F1+F3 партию больше НЕ запускает: toGame возвращал 1, и каждый стенд на нём молча
//  писал «нет геймплея» — то есть половина каталога замеров была недоступна (проверено:
//  topright_jump_probe и audit_tickfit падали именно так). Комбинация пробуется первой
//  (старым сборкам с читами она по-прежнему нужна и уводит их на нужную пирамиду), а
//  если партия не пошла — обычный старт пробелом, тот же, что в pack_prof/pack_bytes_prof.
//  Сцена при этом ПЕРВАЯ пирамида, а не выбранная читом N: стенды, которым нужен уровень,
//  обязаны ставить его сами (прямой записью piramideDest/subStatus/GameStatus).
function toGame(E){
  const {run,key,rd,L}=E;
  run(400);
  key(112,1); key(114,1);                 // F1 + F3
  for(let i=0;i<40 && rd(L.GameStatus)!==5;i++) run(16);
  key(112,0); key(114,0); run(8);
  if(rd(L.GameStatus)!==5){               // читов нет — стартуем пробелом
    for(let i=0;i<250 && rd(L.GameStatus)!==5;i++){ key(32,1); run(3); key(32,0); run(5); }
    run(8);
  }
  // 25 Гц: после старта ещё шторка/лестница (GS=4), ждём игровую логику.
  for(let i=0;i<400 && rd(L.GameStatus)!==5;i++) run(4);
  return rd(L.GameStatus);
}
module.exports={make,toGame};
