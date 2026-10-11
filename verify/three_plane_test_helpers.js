// Independent reconstruction of the clean framebuffer from saved records.
// Used only by verification, never by the ROM or timed renderer.
function cleanVideo(E){const bytes=Buffer.from(Array.from({length:24576},(_,i)=>E.rd(0xa000+i)));const word=a=>E.rd(a)+256*E.rd(a+1);for(let i=E.rd(E.L.SUCount)-1;i>=0;i--){const r=E.L.SURecords+6*i,dst=word(r),cols=E.rd(r+2),rows=E.rd(r+3);let src=word(r+4);if(E.L.CGFormat&&E.rd(E.L.CGFormat)){for(let c=0;c<cols;c++)for(let y=0;y<rows;y++){const a=(dst&0xff00)+c*256+(dst&255)+rows-1-y;bytes[a-0xa000]=E.rd(src++);bytes[a-0xc000]=E.rd(src++);}}else{for(let p=0;p<(E.L.SUObjectPlanes||3);p++)for(let c=0;c<cols;c++)for(let y=0;y<rows;y++)bytes[dst-p*8192+c*256+y-0xa000]=E.rd(src++);}}return bytes;}
function field(E,bytes=cleanVideo(E)){return Buffer.from(Array.from({length:3*32*192},(_,i)=>{const p=Math.floor(i/6144),q=i%6144,c=Math.floor(q/192),y=q%192;return bytes[p*8192+c*256+((224-y)&255)];}));}
module.exports={cleanVideo,field};
