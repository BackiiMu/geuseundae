#!/usr/bin/env python3
"""산호랑이 시트(포효·도약 프레임)에서 머리만 잘라 푸른 영혼 호랑이 머리 도트 데이터(JSON)로 만든다.
실행: python3 docs/mockups/tiger-fang/build_head.py → tiger-head.json (+ pixelfx 데이터 모듈)"""
import json, os, colorsys
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.abspath(os.path.join(HERE,'..','..','..'))
SRC=os.path.join(ROOT,'godot/assets/actors/source/mountain-tiger-v1.png')
im=Image.open(SRC).convert('RGBA')
def cell(i):
    c=im.crop(((i%8)*192,(i//8)*256,(i%8+1)*192,(i//8+1)*256));a=c.getchannel('A').point(lambda v:255 if v>=200 else 0);c.putalpha(a);return c
# (프레임, 머리 상자, 눈 위치) — 눈을 같은 자리에 맞춰 턱만 움직이게 한다
HEADS=[(19,(100,58,163,114),(139,80)),(20,(94,56,153,114),(127,72))]
CW,CH,EYE=64,60,(34,26); K=.75
def blue(r,g,b):
    h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
    h=(0.60+(h-0.08)*0.25)%1;s=min(1,s*0.9+0.18);v=min(1,v*0.95+0.08)
    rr,gg,bb=colorsys.hsv_to_rgb(h,s,v);return int(rr*255),int(gg*255),int(bb*255)
canvases=[]
for f,(x0,y0,x1,y1),(ex,ey) in HEADS:
    c=cell(f).crop((x0,y0,x1,y1));px=c.load()
    out=Image.new('RGBA',(CW,CH),(0,0,0,0));o=out.load()
    ox,oy=EYE[0]-(ex-x0),EYE[1]-(ey-y0)
    for y in range(c.height):
        for x in range(c.width):
            r,g,b,a=px[x,y]
            if a and 0<=x+ox<CW and 0<=y+oy<CH:o[x+ox,y+oy]=blue(r,g,b)+(255,)
    # 도트화: 0.75배 박스 축소 후 반투명 가장자리 제거
    sm=out.resize((int(CW*K),int(CH*K)),Image.BOX);sp=sm.load()
    for y in range(sm.height):
        for x in range(sm.width):
            p=sp[x,y];sp[x,y]=(p[0],p[1],p[2],255) if p[3]>=128 else (0,0,0,0)
    # 떨어진 점(외톨이 픽셀) 제거
    sp=sm.load()
    for y in range(sm.height):
        for x in range(sm.width):
            if sp[x,y][3]:
                n=sum(1 for dx,dy in((1,0),(-1,0),(0,1),(0,-1)) if 0<=x+dx<sm.width and 0<=y+dy<sm.height and sp[x+dx,y+dy][3])
                if n==0:sp[x,y]=(0,0,0,0)
    canvases.append(sm)
W,H=canvases[0].size
rgb=Image.new('RGB',(W*len(canvases),H),(0,0,0))
for i,c in enumerate(canvases):
    t=Image.new('RGB',c.size,(0,0,0));t.paste(c,mask=c.getchannel('A'));rgb.paste(t,(i*W,0))
q=rgb.quantize(colors=20,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE)
pal=q.getpalette()[:60]
CH_='0123456789abcdefghijklmnopqrstuvwxyz'
palette={CH_[i]:'#%02x%02x%02x'%tuple(pal[i*3:i*3+3]) for i in range(20)}
frames=[]
for i,c in enumerate(canvases):
    rows=[];qp=q.load();ap=c.load()
    for y in range(H):
        rows.append(''.join(CH_[qp[i*W+x,y]] if ap[x,y][3] else '.' for x in range(W)))
    frames.append(rows)
data={'about':'푸른 영혼 호랑이 머리 도트 데이터. 산호랑이 시트 19·20번 프레임의 머리를 파랗게 바꿔 0.75배로 줄이고 20색으로 제한. 문자는 palette의 키, "."은 투명. 눈 위치를 맞춰 턱만 열리고 닫힌다.',
      'source':'godot/assets/actors/source/mountain-tiger-v1.png frames 19,20','size':[W,H],'palette':palette,'frames':frames}
json.dump(data,open(os.path.join(HERE,'tiger-head.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
js='// 자동 생성: python3 docs/mockups/tiger-fang/build_head.py\nexport default '+json.dumps(data,ensure_ascii=False)+';\n'
open(os.path.join(ROOT,'vendor/pixelfx/src/fx/geuseundae/tiger-head-data.js'),'w',encoding='utf-8').write(js)
print('head',W,H,'colors',len(palette))
