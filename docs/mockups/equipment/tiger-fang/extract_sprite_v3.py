#!/usr/bin/env python3
"""tiger-fang-projectile-existing-tiger-v3.png(1536×1024, 16px 블록)를 도트 격자(96×64)로 줄이고
검은 배경·바깥 광을 투명으로 만든 뒤, 주황/갈색 줄무늬를 푸른 계열로 바꿔 tiger-v3-sprite.png로 저장한다 (시안용)."""
import os,colorsys
from PIL import Image
from collections import deque
HERE=os.path.dirname(os.path.abspath(__file__))
src=Image.open(os.path.join(HERE,'tiger-fang-projectile-existing-tiger-v3.png')).convert('RGB')
B=16;GW,GH=src.width//B,src.height//B
g=Image.new('RGB',(GW,GH));gp=g.load();sp=src.load()
for y in range(GH):
    for x in range(GW):gp[x,y]=sp[x*B+B//2,y*B+B//2]
TH=int(os.environ.get('TH','60'))
bright=lambda c:max(c)
bgm=[[False]*GW for _ in range(GH)];q=deque()
for x in range(GW):
    for y in(0,GH-1):
        if bright(gp[x,y])<TH and not bgm[y][x]:bgm[y][x]=True;q.append((x,y))
for y in range(GH):
    for x in(0,GW-1):
        if bright(gp[x,y])<TH and not bgm[y][x]:bgm[y][x]=True;q.append((x,y))
while q:
    x,y=q.popleft()
    for dx,dy in((1,0),(-1,0),(0,1),(0,-1)):
        u,v=x+dx,y+dy
        if 0<=u<GW and 0<=v<GH and not bgm[v][u] and bright(gp[u,v])<TH:bgm[v][u]=True;q.append((u,v))
def blue(c):
    r,g_,b=[v/255 for v in c];h,s,v=colorsys.rgb_to_hsv(r,g_,b)
    if (h<=0.16 or h>=0.97) and s>0.12:  # 주황·갈색 줄무늬 → 푸른색
        h=0.57;s=min(1,max(s*1.6,0.55));v=min(1,v*1.45)
    elif s<0.25 and v>0.35:        # 회백색 털에 푸른 기운
        h=0.58;s=max(s,0.14)
    r,g_,b=colorsys.hsv_to_rgb(h,s,v);return (round(r*255),round(g_*255),round(b*255))
out=Image.new('RGBA',(GW,GH),(0,0,0,0));op=out.load()
for y in range(GH):
    for x in range(GW):
        if not bgm[y][x]:op[x,y]=blue(gp[x,y])+(255,)
bbox=out.getchannel('A').getbbox();print('grid',GW,GH,'bbox',bbox)
out=out.crop(bbox);out.save(os.path.join(HERE,'tiger-v3-sprite.png'));print('sprite',out.size)
bg=Image.new('RGBA',out.size,(14,18,26,255));bg.alpha_composite(out)
bg.resize((out.width*6,out.height*6),Image.NEAREST).convert('RGB').save(os.environ['CHK'])
