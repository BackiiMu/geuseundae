#!/usr/bin/env python3
"""tiger-fang-spirit-projectile-pixel-v2.png(1536×1024, 16px 블록)를 원래 도트 격자(96×64)로 줄이고
검은 배경·바깥 광을 투명으로 만들어 tiger-v2-sprite.png로 저장한다 (시안용, 게임 에셋 아님)."""
import os
from PIL import Image
from collections import deque
HERE=os.path.dirname(os.path.abspath(__file__))
src=Image.open(os.path.join(HERE,'tiger-fang-spirit-projectile-pixel-v2.png')).convert('RGB')
B=16;GW,GH=src.width//B,src.height//B
g=Image.new('RGB',(GW,GH));gp=g.load();sp=src.load()
for y in range(GH):
    for x in range(GW):gp[x,y]=sp[x*B+B//2,y*B+B//2]
# 바깥에서 이어진 어두운 칸(배경+광)을 투명으로
bright=lambda c:max(c)
bgm=[[False]*GW for _ in range(GH)];q=deque()
TH=108
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
out=Image.new('RGBA',(GW,GH),(0,0,0,0));op=out.load()
for y in range(GH):
    for x in range(GW):
        if not bgm[y][x]:op[x,y]=gp[x,y]+(255,)
bbox=out.getchannel('A').getbbox();print('grid',GW,GH,'bbox',bbox)
out=out.crop(bbox);out.save(os.path.join(HERE,'tiger-v2-sprite.png'));print('sprite',out.size)
bg=Image.new('RGBA',out.size,(14,18,26,255));bg.alpha_composite(out)
bg.resize((out.width*6,out.height*6),Image.NEAREST).convert('RGB').save('/private/tmp/claude-501/-Users-backiimu-Documents-pj-geuseundae/342a599e-0975-4b88-91b0-4605def10e99/scratchpad/v2_sprite_check.png')
