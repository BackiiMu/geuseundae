#!/usr/bin/env python3
"""기존 발톱 이펙트(godot/assets/gear3/fx/jangsan-paw.png)를 초승달 곡선에 맞춰 '미리 구운' 프레임 시트로 만든다.
줄마다 늘려 붙이지 않고, 목적지 픽셀마다 원본 좌표를 거꾸로 계산해 양선형으로 샘플링한 뒤
알파를 임계값으로 끊어 가장자리가 층지지 않게 한다. 발톱 굵기(가로 팽창)·어두운 외곽선·위아래 끝 가늘어짐·디더 페이드를 함께 굽는다.
실행: python3 docs/mockups/equipment/jangsan-paw/bake_claw.py  → claw-crescent.png / claw-crescent.json"""
import json, math, os
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__))
ROOT=os.path.abspath(os.path.join(HERE,'..','..','..','..'))
SRC=Image.open(os.path.join(ROOT,'godot/assets/gear3/fx/jangsan-paw.png')).convert('RGBA')
FW,FH,COLS=180,140,5
SR=(65,55,72,64)                         # 원본에서 발톱이 그려지는 영역 x,y,w,h
# 형태(가슴 기준, 위가 음수). 시안 기본값과 같다.
REACH,AA,BB,CY,THK,CT=145,105,85,-14,150,5
CXC=REACH-AA; PM=math.radians(100.8); H=CT//2
# 원본 3~6번 프레임이 발톱 4줄이 가장 또렷하다(7번 이후는 조각으로 흩어진다). 그 구간을 쓰고 끝은 디더로 사라지게 한다.
SEQ=[4,4,4,4,4,5,5,5,5,5,6,6,6,6]
REVEAL=[.30,.62,.9]                     # 앞 3프레임은 위에서 아래로 훑듯이 드러난다
N=len(SEQ)
FPS=30; FADE=6                           # 마지막 6프레임은 디더로 사라짐
BAY=[[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]]
def src_frame(i):
    c=SRC.crop(((i%COLS)*FW+SR[0],(i//COLS)*FH+SR[1],(i%COLS)*FW+SR[0]+SR[2],(i//COLS)*FH+SR[1]+SR[3]));return c.load()
def bilinear(px,w,h,x,y):
    x-=.5;y-=.5;x0=math.floor(x);y0=math.floor(y);fx=x-x0;fy=y-y0
    r=g=b=a=0.0
    for dx,dy,wt in((0,0,(1-fx)*(1-fy)),(1,0,fx*(1-fy)),(0,1,(1-fx)*fy),(1,1,fx*fy)):
        xx=min(w-1,max(0,x0+dx));yy=min(h-1,max(0,y0+dy));p=px[xx,yy];al=p[3]/255
        r+=p[0]*al*wt;g+=p[1]*al*wt;b+=p[2]*al*wt;a+=al*wt
    return (r/a,g/a,b/a,a) if a>1e-6 else (0,0,0,0)
# 목적지 범위
xs=[];
for row in range(-BB,BB+1):
    sn=row/BB
    if abs(sn)>1:continue
    ph=math.asin(sn);ox=CXC+AA*math.cos(ph);th=THK*math.cos(ph/PM*math.pi/2);xs+= [ox-th,ox]
XMIN=math.floor(min(xs))-H-3;XMAX=math.ceil(max(xs))+H+3;YMIN=CY-BB-3;YMAX=CY+BB+3
W,Hh=XMAX-XMIN,YMAX-YMIN
print('cell',W,Hh)
frames=[]
for fi in range(N):
    sf=SEQ[fi];px=src_frame(sf);sw,sh=SR[2],SR[3]
    A=[[0.0]*W for _ in range(Hh)];Cc=[[None]*W for _ in range(Hh)]
    for y in range(Hh):
        wy=YMIN+y+.5;sn=(wy-CY)/BB
        if abs(sn)>1:continue
        ph=math.asin(sn);ox=CXC+AA*math.cos(ph);th=THK*math.cos(ph/PM*math.pi/2)
        if th<1:continue
        v=(wy-(CY-BB))/(2*BB);tf=min(1.0,th/34)
        if fi<len(REVEAL) and v>REVEAL[fi]:continue
        for x in range(W):
            wx=XMIN+x+.5;u=(wx-(ox-th))/th
            if u<0 or u>1:continue
            r,g,b,a=bilinear(px,sw,sh,u*sw,v*sh)
            A[y][x]=a*tf;Cc[y][x]=(r,g,b)
    # 임계값으로 끊기
    M=[[A[y][x]>=.42 for x in range(W)] for y in range(Hh)]
    # 가로 팽창(굵게) — 색은 창 안에서 알파가 가장 높은 칸의 것
    M2=[[False]*W for _ in range(Hh)];C2=[[None]*W for _ in range(Hh)]
    for y in range(Hh):
        for x in range(W):
            best=None;ba=0
            for d in range(-H,H+1):
                xx=x+d
                if 0<=xx<W and M[y][xx] and A[y][xx]>ba:ba=A[y][xx];best=Cc[y][xx]
            if best is not None:M2[y][x]=True;C2[y][x]=best
    out=Image.new('RGBA',(W,Hh),(0,0,0,0));op=out.load()
    fk=1.0 if fi<N-FADE else max(0.0,1-(fi-(N-FADE)+1)/(FADE+0.5))
    for y in range(Hh):
        for x in range(W):
            keep=fk>=1 or BAY[y%4][x%4]/16<fk
            if M2[y][x]:
                if keep:
                    r,g,b=C2[y][x];op[x,y]=(min(255,int(r)),min(255,int(g)),min(255,int(b)),255)
            else:
                edge=any(0<=x+dx<W and 0<=y+dy<Hh and M2[y+dy][x+dx] for dx,dy in((1,0),(-1,0),(0,1),(0,-1)))
                if edge and keep:op[x,y]=(14,18,32,235)
    frames.append(out)
COLS_O=4;ROWS_O=(N+COLS_O-1)//COLS_O
sheet=Image.new('RGBA',(COLS_O*W,ROWS_O*Hh),(0,0,0,0))
for i,f in enumerate(frames):sheet.alpha_composite(f,((i%COLS_O)*W,(i//COLS_O)*Hh))
sheet.save(os.path.join(HERE,'claw-crescent.png'))
meta={'frames':[{'filename':f'claw-crescent {i}','frame':{'x':(i%COLS_O)*W,'y':(i//COLS_O)*Hh,'w':W,'h':Hh},'duration':round(1000/FPS)} for i in range(N)],
 'meta':{'image':'claw-crescent.png','size':{'w':COLS_O*W,'h':ROWS_O*Hh},
 'pixelfx':{'id':'geuseundae/claw-crescent','name':'장산범 앞발 · 초승달 발톱','fps':FPS,'loop':False,'frames':N,'frameSize':[W,Hh],'pivot':[-XMIN,-YMIN],'columns':COLS_O,
 'shape':{'reach':REACH,'a':AA,'b':BB,'cy':CY,'thickness':THK,'clawWidth':CT}}}}
json.dump(meta,open(os.path.join(HERE,'claw-crescent.json'),'w',encoding='utf-8'),ensure_ascii=False,indent=1)
print('ok',sheet.size,'pivot',-XMIN,-YMIN)
bg=Image.new('RGBA',sheet.size,(16,22,32,255));bg.alpha_composite(sheet)
bg.resize((sheet.width*2,sheet.height*2),Image.NEAREST).convert('RGB').save('/private/tmp/claude-501/-Users-backiimu-Documents-pj-geuseundae/342a599e-0975-4b88-91b0-4605def10e99/scratchpad/claw_bake_check.png')
