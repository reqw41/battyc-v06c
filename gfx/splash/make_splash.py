import sys,re
from PIL import Image
src,fontasm,out=sys.argv[1:4]
d=open(src,'rb').read()[1:6913]
def zbit(x,y):
    a=((y&0xc0)<<5)|((y&7)<<8)|((y&0x38)<<2)|(x>>3);return d[a]>>(7-(x&7))&1
def zattr(x,y):return d[6144+(y>>3)*32+(x>>3)]
PAL=[(0,0,0),(0,0,85),(0,0,170),(0,73,255),(255,0,0),(146,0,0),(255,255,0),(255,146,0),
     (0,219,0),(0,109,0),(0,255,255),(255,0,255),(255,255,255),(182,182,170),(109,109,85),(73,73,85)]
K,NAVY,BLUE,BBLUE,RED,DRED,YEL,ORA,GRN,DGRN,CYAN,MAG,WHITE,LGREY,GREY,DGREY=range(16)
BG=-1
W=H=256
img=[[BG]*W for _ in range(H)]
TOP=12;INS=16;SPLIT=128
def zxcol(c,bright):
    return [K,BBLUE if bright else BLUE,RED if bright else DRED,MAG,GRN if bright else DGRN,CYAN,YEL,WHITE if bright else LGREY][c]
def pixel(x,y):
    """colour of ZX pixel (x,y) or BG"""
    at=zattr(x,y);b=zbit(x,y);ink=at&7;pap=(at>>3)&7;br=at>>6&1
    c=ink if b else pap
    if c==0:return BG
    if x>=222 and 54<=y<72:return BG      # the artist's "M.C." signature is left out
    if (x>=252 or x<=3) and 80<=y<136:return BG   # slivers of the side walls cut by the screen edge
    col=zxcol(c,br)
    if y<72:                       # logo: per-row stripes instead of attribute cells
        r=y>>3
        if col in(RED,DRED,YEL,MAG) or (r>=4 and col not in(WHITE,LGREY,CYAN)):
            col=[None,None,None,None,MAG,RED,ORA,YEL,YEL][min(r,8)] or col
            if r==8 and (y&7)>=4:col=ORA
    elif y<104 or (y<136 and (x<36 or x>219)):   # pipe and side walls
        if col==CYAN and y>=104:col=LGREY        # attribute clash at the wall corner
        if col in(WHITE,LGREY):
            if 36<=x<=219 and y<97:col=LGREY
            else:col=GREY
    return col
# upper part
for y in range(SPLIT):
    for x in range(W):img[y+TOP][x]=pixel(x,y)
# pipe highlight: first ink row of the pipe white
for x in range(36,220):
    ys=[y for y in range(72,100) if img[y+TOP][x]==LGREY]
    if ys:
        img[ys[0]+TOP][x]=WHITE
# brick rows: geometry from the ZX rows (left/right edge and joints are linear in y)
def runs(y):
    row=[zbit(x,y) for x in range(W)];L=26+ (127-y) ;  # search inside the field
    xs=[x for x in range(20,236) if row[x]]
    # field = longest stretch between walls
    segs=[];s=None
    for x in range(W+1):
        v=x<W and row[x]
        if v and s is None:s=x
        if not v and s is not None:segs.append((s,x-1));s=None
    segs=[g for g in segs if g[0]>24 and g[1]<232]
    return segs
top=runs(105);bot=runs(127)
assert len(top)==len(bot),(len(top),len(bot))
N=len(top)
def brick_edges(y):       # y in ZX coordinates, may exceed 127
    t=(y-105)/22.0
    return [(round(a[0]+(b[0]-a[0])*t),round(a[1]+(b[1]-a[1])*t)) for a,b in zip(top,bot)]
ROWS=[(105,YEL,ORA),(113,RED,DRED),(121,GRN,DGRN),(129,BBLUE,BLUE),(137,LGREY,GREY)]
for y0,c,dark in ROWS:
    for i in range(7):
        y=y0+i
        for a,b in brick_edges(y):
            for x in range(max(a,0),min(b,W-1)+1):
                col=c
                if i==0:col=WHITE if c!=LGREY else WHITE
                if i==6 or x==b:col=dark
                img[y+TOP][x]=col
    for x in range(W):                       # black joint line under the row
        e=brick_edges(y0+7)
        if e[0][0]<=x<=e[-1][1]:img[y0+7+TOP][x]=K
# front face under the nearest row, then the shadow
FY=145
eF=brick_edges(FY);L,R=eF[0][0],eF[-1][1]
for i in range(7):
    y=FY+i+TOP
    for a,b in eF:
        for x in range(max(a,0),min(b,W-1)+1):
            img[y][x]=DGREY if (i==6 or x in(a,b) or (x+i)&1) else K
for x in range(max(L,0),min(R,W-1)+1):
    if img[FY-1+TOP][x]==BG:img[FY-1+TOP][x]=K
SH=[]
for i in range(6):
    y=FY+9+i+TOP
    for x in range(L+12-i,min(R+4+i,W-1)+1):
        if (x+i)&1:SH.append((x,y))
# lower part of the ZX picture (bats, ball, copyright), moved down
LOW=TOP+INS+12
for y in range(146,184):
    for x in range(W):
        c=pixel(x,y)
        at=zattr(x,y)
        r,cc=y>>3,x>>3
        if c!=BG and at==6 and (r>=21 or (r in(19,20) and 11<=cc<=13) or (r==20 and (cc==3 or cc>=26))):   # dim yellow dither = shadow
            SH.append((x,y+LOW));continue
        if c!=BG:img[y+LOW][x]=c
for y in range(184,192):
    for x in range(W):
        c=pixel(x,y)
        if c!=BG:img[y+LOW+8][x]=c
# Russian line in the game font
glyph={}
n=0
for line in open(fontasm,encoding='utf-8'):
    m=re.match(r'\s*DEFB\s+([^;]+);\s*([0-9A-F]{2})\s*-\s*(.*)',line)
    if m:glyph[m.group(3).strip() or ' ']=[int(v.strip()[1:],16) for v in m.group(1).split(',')]
def text(s,y,col):
    x=(W-8*len(s))//2
    for ch in s:
        g=glyph.get(ch)
        if g:
            for r,row in enumerate(g):
                for b in range(8):
                    if row>>(7-b)&1:img[y+r][x+b]=col
        x+=8
text('ВЕРСИЯ ДЛЯ ВЕКТОРА-06Ц',242,CYAN)
# background: two-blue diamonds, black halo around everything, black dither shadows
fg=[[img[y][x]!=BG for x in range(W)] for y in range(H)]
def near(x,y,r):
    for dy in range(-r,r+1):
        for dx in range(-r,r+1):
            if abs(dx)+abs(dy)<=r+1 and 0<=x+dx<W and 0<=y+dy<H and fg[y+dy][x+dx]:return True
    return False
shadow=set(SH)
for y in range(H):
    for x in range(W):
        if img[y][x]!=BG:continue
        if near(x,y,1) or (x,y) in shadow:img[y][x]=K;continue
        if (x-1,y) in shadow or (x+1,y) in shadow:img[y][x]=NAVY;continue
        u,v=(x+y)%16,(x-y)%16
        img[y][x]=NAVY if (u<1 or v<1 or (u in(7,8) and v in(7,8))) else BLUE if ((x//8+y//8)&1)==0 and False else (NAVY if (u<8)!=(v<8) else BLUE)
im=Image.new('P',(W,H));pal=[]
for c in PAL:pal+=list(c)
im.putpalette(pal+[0]*(768-len(pal)))
im.putdata([img[y][x] for y in range(H) for x in range(W)])
im.save(out);im.convert('RGB').resize((768,768),Image.NEAREST).save(out.replace('.png','_x3.png'))
# Vector-06C screen image: four planes of 8 KB, column-major, picture row r at offset 255-r
# (vertical scroll $FF). Colour index = 8*plane8000 + 4*planeA000 + 2*planeC000 + planeE000.
import os
d0=os.path.dirname(os.path.abspath(__file__))
scr=bytearray(32768)
for y in range(H):
    for x in range(W):
        c=img[y][x]
        for k,bit in enumerate((8,4,2,1)):
            if c&bit:scr[k*8192+(x>>3)*256+255-y]|=128>>(x&7)
open(os.path.join(d0,'splash.bin'),'wb').write(scr)
vec=lambda r,g,b:(round(b*3/255)<<6)|(round(g*7/255)<<3)|round(r*7/255)
open(os.path.join(d0,'splash_palette.asm'),'w').write('; Generated by make_splash.py: sixteen colours of the title picture (BBGGGRRR)\nPaletteSplash:\n db '+','.join('$%02x'%vec(*c) for c in PAL)+'\n')
print('colours',sorted(set(v for r in img for v in r)),'bricks per row',N)
