'use strict';
const assert=require('assert'),fs=require('fs');
const W=32,H=192,N=11;
const intersect=(a,b)=>a&&b&&a.x<b.x+b.w&&b.x<a.x+a.w&&a.y<b.y+b.h&&b.y<a.y+a.h;
const rect=o=>o&&({x:o.x,y:o.y,w:o.w,h:(o.h+1)&~1});
function union(a,b){if(!a)return b;if(!b)return a;const x=Math.min(a.x,b.x),y=Math.min(a.y,b.y);return{x,y,w:Math.max(a.x+a.w,b.x+b.w)-x,h:Math.max(a.y+a.h,b.y+b.h)-y};}
function groups(old,now){const r=old.map((o,i)=>union(o&&o.r,rect(now[i]))),label=Array.from({length:N},(_,i)=>i);for(let i=0;i<N;i++)for(let j=i+1;j<N;j++)if(intersect(r[i],r[j])){const a=label[i],b=label[j];for(let k=0;k<N;k++)if(label[k]===b)label[k]=a;}return[...new Set(label)].map(l=>label.map((v,i)=>v===l&&r[i]?i:-1).filter(i=>i>=0)).filter(g=>g.length);}
function shade(o,c,y,e,f){if(y>=o.h)return[e,f];const q=c*o.h+y,m=o.mask[q],v=o.lit[q];return[(e&~m)|v,(f&~m)|(o.enemy&&y>=(o.sourceH>>1)?v:0)];}
function full(bg,now){const v=bg.map(p=>Buffer.from(p));for(const o of now)if(o)for(let c=0;c<o.w;c++)for(let y=0;y<o.h;y++){const p=(o.x+c)*H+o.y+y;[v[0][p],v[1][p]]=shade(o,c,y,v[0][p],v[1][p]);}return v;}
function restore(v,records){for(let i=N-1;i>=0;i--){const o=records[i];if(o)for(let c=0;c<o.r.w;c++)for(let y=0;y<o.r.h;y++){const p=(o.r.x+c)*H+o.r.y+y,q=2*(c*o.r.h+y);v[0][p]=o.data[q];v[1][p]=o.data[q+1];}}return v;}
let seed=0x808006;const rnd=n=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n;};
const bg=[Buffer.alloc(W*H),Buffer.alloc(W*H)];for(let i=0;i<W*H;i++){bg[0][i]=rnd(256);bg[1][i]=rnd(256);}
let video=bg.map(p=>Buffer.from(p)),old=Array(N).fill(null),stats={frames:0,groups:0,isolated:0,stable:0,tiles:0,videoBytes:0,maxScratch:64};
for(let t=0;t<2500;t++){
 const now=Array.from({length:N},(_,i)=>{if(rnd(5)===0)return null;const w=1+rnd(7),h=1+rnd(28),x=rnd(W-w+1),y=rnd(H-((h+1)&~1)+1),mask=Buffer.alloc(w*h),lit=Buffer.alloc(w*h);for(let q=0;q<mask.length;q++){mask[q]=rnd(256);lit[q]=rnd(256)&mask[q];}return{x,y,w,h,sourceH:h,mask,lit,enemy:rnd(2)};});
 if(t%7===0)for(let i=0;i<N;i++)if(old[i]&&now[i]){const r=old[i].r;now[i]={...now[i],x:r.x,y:r.y,w:r.w,h:r.h,sourceH:r.h,mask:Buffer.alloc(r.w*r.h,0x55),lit:Buffer.alloc(r.w*r.h,0x11)};}
 const next=now.map((o,i)=>o?{r:rect(o),data:Buffer.alloc(2*o.w*((o.h+1)&~1)),bank:old[i]?old[i].bank^1:0}:null);
 for(const g of groups(old,now)){
  stats.groups++;if(g.length===1)stats.isolated++;
  const i=g[0];if(g.length===1&&old[i]&&now[i]&&JSON.stringify(old[i].r)===JSON.stringify(rect(now[i]))){stats.stable++;next[i]=old[i];const r=old[i].r;for(let c=0;c<r.w;c++)for(let y=0;y<r.h;y++){const q=2*(c*r.h+y),p=(r.x+c)*H+r.y+y;[video[0][p],video[1][p]]=shade(now[i],c,y,old[i].data[q],old[i].data[q+1]);stats.videoBytes+=2;}continue;}
  if(g.length===1){
   const i=g[0],prev=old[i],o=now[i],s=next[i];
   if(o){for(let c=0;c<s.r.w;c++)for(let y=0;y<s.r.h;y++){const x=s.r.x+c,yy=s.r.y+y,p=x*H+yy,q=2*(c*s.r.h+y);if(prev&&x>=prev.r.x&&x<prev.r.x+prev.r.w&&yy>=prev.r.y&&yy<prev.r.y+prev.r.h){const oldq=2*((x-prev.r.x)*prev.r.h+yy-prev.r.y);s.data[q]=prev.data[oldq];s.data[q+1]=prev.data[oldq+1];}else{s.data[q]=video[0][p];s.data[q+1]=video[1][p];}}
    for(let c=0;c<s.r.w;c++)for(let y=0;y<s.r.h;y++){const q=2*(c*s.r.h+y),p=(s.r.x+c)*H+s.r.y+y;[video[0][p],video[1][p]]=shade(o,c,y,s.data[q],s.data[q+1]);stats.videoBytes+=2;}
   }
   if(prev)for(let c=0;c<prev.r.w;c++)for(let y=0;y<prev.r.h;y++){const x=prev.r.x+c,yy=prev.r.y+y;if(s&&x>=s.r.x&&x<s.r.x+s.r.w&&yy>=s.r.y&&yy<s.r.y+s.r.h)continue;const p=x*H+yy,q=2*(c*prev.r.h+y);video[0][p]=prev.data[q];video[1][p]=prev.data[q+1];stats.videoBytes+=2;}
   continue;
  }
  const r=g.reduce((r,i)=>union(r,union(old[i]&&old[i].r,rect(now[i]))),null);
  for(let c=r.x;c<r.x+r.w;c++)for(let y0=r.y;y0<r.y+r.h;y0+=32){const h=Math.min(32,r.y+r.h-y0),scratch=[Buffer.alloc(h),Buffer.alloc(h)];stats.tiles++;for(let y=0;y<h;y++){scratch[0][y]=video[0][c*H+y0+y];scratch[1][y]=video[1][c*H+y0+y];}
   for(const i of [...g].reverse()){const o=old[i];if(o&&c>=o.r.x&&c<o.r.x+o.r.w)for(let y=Math.max(y0,o.r.y);y<Math.min(y0+h,o.r.y+o.r.h);y++){const q=2*((c-o.r.x)*o.r.h+y-o.r.y);scratch[0][y-y0]=o.data[q];scratch[1][y-y0]=o.data[q+1];}}
   for(const i of g){const o=now[i],s=next[i];if(o&&c>=o.x&&c<o.x+o.w)for(let y=Math.max(y0,o.y);y<Math.min(y0+h,o.y+s.r.h);y++){const q=2*((c-o.x)*s.r.h+y-o.y),k=y-y0;s.data[q]=scratch[0][k];s.data[q+1]=scratch[1][k];[scratch[0][k],scratch[1][k]]=shade(o,c-o.x,y-o.y,scratch[0][k],scratch[1][k]);}}
   for(let y=0;y<h;y++){video[0][c*H+y0+y]=scratch[0][y];video[1][c*H+y0+y]=scratch[1][y];stats.videoBytes+=2;}
  }
 }
 assert.deepStrictEqual(video,full(bg,now),'finished image frame '+t);assert.deepStrictEqual(restore(video.map(p=>Buffer.from(p)),next),bg,'reverse reconstruction frame '+t);old=next;stats.frames++;
}
fs.writeFileSync('outputs/batty-local-js-model.json',JSON.stringify({...stats,passed:true},null,2));console.log(stats);
