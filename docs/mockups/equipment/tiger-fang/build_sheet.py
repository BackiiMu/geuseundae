#!/usr/bin/env python3
"""tiger-v2-sprite.png(제공 이미지 v2에서 추출한 80×51 도트)에 꼬리 물결·머리 흔들림을 넣어
12프레임 반복 시트(godot/assets/vfx/tiger-spirit.png + .json)로 만든다.
실행: python3 docs/mockups/equipment/tiger-fang/build_sheet.py"""
import json, math, os
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.abspath(os.path.join(HERE,'..','..','..','..'))
sp=Image.open(os.path.join(HERE,'tiger-v2-sprite.png')).convert('RGBA')
SW,SH=sp.size
FW,FH,COLS,N=84,59,4,12
OX,OY=2,4                      # 스프라이트를 프레임 안에 놓는 위치(물결·흔들림 여백)
HEAD=(62,26)                   # 머리 중심(스프라이트 좌표)
ROWS=(N+COLS-1)//COLS
sheet=Image.new('RGBA',(COLS*FW,ROWS*FH),(0,0,0,0))
for f in range(N):
    ph=f/N*2*math.pi
    bob=round(math.sin(ph)*1.2)
    fr=Image.new('RGBA',(FW,FH),(0,0,0,0))
    for cx in range(SW):
        tail=max(0.0,1-cx/46)
        off=round(math.sin(ph+cx*.45)*1.6*tail)
        col=sp.crop((cx,0,cx+1,SH))
        fr.alpha_composite(col,(OX+cx,OY+off+bob))
    sheet.alpha_composite(fr,((f%COLS)*FW,(f//COLS)*FH))
out=os.path.join(ROOT,'godot','assets','vfx')
sheet.save(os.path.join(out,'tiger-spirit.png'))
pivot=[HEAD[0]+OX,HEAD[1]+OY]
meta={'frames':[{'filename':f'tiger-spirit {i}','frame':{'x':(i%COLS)*FW,'y':(i//COLS)*FH,'w':FW,'h':FH},'rotated':False,'trimmed':False,'spriteSourceSize':{'x':0,'y':0,'w':FW,'h':FH},'sourceSize':{'w':FW,'h':FH},'duration':50} for i in range(N)],
 'meta':{'app':'geuseundae tiger spirit sheet','version':'1','image':'tiger-spirit.png','format':'RGBA8888','size':{'w':COLS*FW,'h':ROWS*FH},'scale':'1',
 'frameTags':[{'name':'fly','from':0,'to':N-1,'direction':'forward'}],
 'pixelfx':{'id':'geuseundae/tiger-spirit','name':'범의 송곳니 · 푸른 영혼 호랑이','fps':20,'loop':True,'frames':N,'frameSize':[FW,FH],'pivot':pivot,'columns':COLS}}}
json.dump(meta,open(os.path.join(out,'tiger-spirit.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
# 매니페스트 등록
mp=os.path.join(out,'manifest.json');m=json.load(open(mp,encoding='utf-8'))
m['tiger-spirit']={'id':'geuseundae/tiger-spirit','name':'Tiger spirit','fps':20,'loop':True,'frames':N,'frameSize':[FW,FH],'pivot':pivot,'columns':COLS,'path':'res://assets/vfx/tiger-spirit.png','source':'tiger-fang-spirit-projectile-pixel-v2','anchor':[0,0]}
json.dump(m,open(mp,'w',encoding='utf-8'),ensure_ascii=False,indent=2)
print('ok',sheet.size,pivot)
