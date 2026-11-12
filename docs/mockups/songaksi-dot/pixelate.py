#!/usr/bin/env python3
"""기존 손각시 시트(192x256 칸, 8x4)를 도트화한다: 배경 안개 제거 → 축소 → 색 제한 → 외곽선.
실행: python3 docs/mockups/songaksi-dot/pixelate.py   (Pillow 필요)
출력: songaksi-px2.png/json (96x128칸), songaksi-px3.png/json (64x86칸)"""
import json, os
from collections import deque
from PIL import Image
HERE=os.path.dirname(os.path.abspath(__file__))
SRC=os.path.join(HERE,'songaksi-v1-original.png')
COLS,ROWS,CW,CH=8,4,192,256
OUT=(15,10,22)
src=Image.open(SRC).convert('RGBA')

def clean_cell(cell):
    """캐릭터(알파 높은 부분)만 남기고 안개와 작은 얼룩을 지운다."""
    w,h=cell.size;px=cell.load();m=[[px[x,y][3]>=200 for x in range(w)] for y in range(h)]
    seen=[[False]*w for _ in range(h)];keep=[[False]*w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            if m[y][x] and not seen[y][x]:
                comp=[];q=deque([(x,y)]);seen[y][x]=True
                while q:
                    a,b=q.popleft();comp.append((a,b))
                    for dx,dy in((1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,-1),(1,-1),(-1,1)):
                        u,v=a+dx,b+dy
                        if 0<=u<w and 0<=v<h and m[v][u] and not seen[v][u]:seen[v][u]=True;q.append((u,v))
                if len(comp)>=25:
                    for a,b in comp:keep[b][a]=True
    out=Image.new('RGBA',(w,h),(0,0,0,0));op=out.load()
    for y in range(h):
        for x in range(w):
            if keep[y][x]:r,g,b,_=px[x,y];op[x,y]=(r,g,b,255)
    return out

def shrink(cell,tw,th):
    """알파로 가중 평균해 축소하고, 절반 넘게 덮인 칸만 남긴다(도트 경계가 또렷해짐)."""
    w,h=cell.size;fx,fy=w/tw,h/th;px=cell.load();out=Image.new('RGBA',(tw,th),(0,0,0,0));op=out.load()
    for y in range(th):
        for x in range(tw):
            x0,x1,y0,y1=int(x*fx),int((x+1)*fx+.999),int(y*fy),int((y+1)*fy+.999)
            n=0;r=g=b=0;tot=0
            for yy in range(y0,min(y1,h)):
                for xx in range(x0,min(x1,w)):
                    tot+=1;p=px[xx,yy]
                    if p[3]:n+=1;r+=p[0];g+=p[1];b+=p[2]
            if tot and n/tot>=.5:op[x,y]=(r//n,g//n,b//n,255)
    return out


def redraw_legs(sheet,ox,oy,tw,th,k):
    """치맛단 높이를 찾아 그 아래를 지우고, 앞다리·뒷다리를 반주기씩 어긋나게 그린다."""
    import math
    px=sheet.load();sc=th/85.0
    lum=lambda p:(p[0]+p[1]+p[2])/3
    yh=None
    for y in range(th-1,int(th*.5),-1):
        n=sum(1 for x in range(tw) if px[ox+x,oy+y][3])
        if n>=24*sc:yh=y;break
    if yh is None:return
    xs=[x for y in range(max(0,yh-5),yh+1) for x in range(tw) if px[ox+x,oy+y][3] and lum(px[ox+x,oy+y])>150]
    if not xs:xs=[x for x in range(tw) if px[ox+x,oy+yh][3]]
    hx=sum(xs)/len(xs)
    if os.environ.get('DBG'):print('yh',oy//th,k,yh,round(hx))
    for y in range(yh+1,th):
        for x in range(tw):px[ox+x,oy+y]=(0,0,0,0)
    ground=th-3
    ph=k/8*2*math.pi
    def leg(phase,col,sh):
        fx=hx+7*sc*math.sin(phase)+1*sc
        lift=max(0.0,-math.cos(phase))*6*sc
        fy=ground-lift
        x0,y0=hx+(1.5*sc if sh else -1.0*sc),yh-1
        n=int(max(abs(fx-x0),abs(fy-y0))*2)+2
        for t in range(n+1):
            u=t/n;x=x0+(fx-x0)*u;y=y0+(fy-y0)*u
            for dx in range(-2,2):
                xx=int(round(x+dx*.75*sc));yy=int(round(y))
                if 0<=xx<tw and yh<yy<th:px[ox+xx,oy+yy]=col
        # 발: 앞으로 뻗은 작은 발등
        for dx in range(0,int(round(5*sc))):
            for dy in (0,1,2):
                xx=int(round(fx+dx));yy=int(round(fy+dy))
                if 0<=xx<tw and 0<=yy<th:px[ox+xx,oy+yy]=col
    leg(ph+math.pi,(104,98,122,255),False)   # 뒷다리(어둡게)
    leg(ph,(160,154,174,255),True)           # 앞다리

def build(div_w,tw,th,name,colors):
    cells=[]
    for i in range(COLS*ROWS):
        c=src.crop(((i%COLS)*CW,(i//COLS)*CH,(i%COLS+1)*CW,(i//COLS+1)*CH))
        cells.append(shrink(clean_cell(c),tw,th))
    # 전체 시트에서 팔레트 한 벌을 뽑아 모든 프레임에 같은 색을 쓴다
    sheet=Image.new('RGBA',(COLS*tw,ROWS*th),(0,0,0,0))
    for i,c in enumerate(cells):sheet.paste(c,((i%COLS)*tw,(i//COLS)*th))
    # 달리기(8~15): 원본은 한쪽 다리만 차는 동작이라, 치맛단 아래를 지우고 두 다리를 번갈아 다시 그린다
    for i in range(8,16):
        redraw_legs(sheet,(i%COLS)*tw,(i//COLS)*th,tw,th,i-8)
    # 붉은 계열(허리띠·눈)은 따로 색을 뽑아 회색 소복에 섞여 사라지지 않게 한다
    W0,H0=sheet.size;sp=sheet.load()
    isred=lambda p:p[3] and p[0]-p[1]>38 and p[0]-p[2]>28
    def quant(pred,n):
        im=Image.new('RGB',(W0,H0),(0,0,0));ip=im.load();cnt=0
        for y in range(H0):
            for x in range(W0):
                p=sp[x,y]
                if p[3] and pred(p):ip[x,y]=p[:3];cnt+=1
        return im.quantize(colors=n,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB') if cnt else im
    qr=quant(isred,4);qg=quant(lambda p:not isred(p),colors-4)
    out=Image.new('RGBA',(W0,H0),(0,0,0,0));op=out.load();qrp=qr.load();qgp=qg.load()
    for y in range(H0):
        for x in range(W0):
            p=sp[x,y]
            if p[3]:op[x,y]=(qrp[x,y] if isred(p) else qgp[x,y])+(255,)
    # 바깥 1칸 윤곽선(어두운 색)
    op=out.load();W,H=out.size;add=[]
    for y in range(H):
        for x in range(W):
            if op[x,y][3]:continue
            for dx,dy in((1,0),(-1,0),(0,1),(0,-1)):
                u,v=x+dx,y+dy
                if 0<=u<W and 0<=v<H and op[u,v][3] and (x//tw==u//tw and y//th==v//th):add.append((x,y));break
    for x,y in add:op[x,y]=OUT+(255,)
    out.save(os.path.join(HERE,name+'.png'))
    tags=[('idle',0,7),('run',8,15),('attack',16,23),('hurt',24,24),('jump',25,25),('fall',26,26),('land',27,27),('dash',28,29),('stagger',30,31)]
    j={'frames':[{'filename':f'{name} {i}','frame':{'x':(i%COLS)*tw,'y':(i//COLS)*th,'w':tw,'h':th},'rotated':False,'trimmed':False,'spriteSourceSize':{'x':0,'y':0,'w':tw,'h':th},'sourceSize':{'w':tw,'h':th},'duration':83} for i in range(COLS*ROWS)],
       'meta':{'app':'geuseundae songaksi pixelate','version':'1','image':name+'.png','format':'RGBA8888','size':{'w':W,'h':H},'scale':'1',
        'frameTags':[{'name':n,'from':a,'to':b,'direction':'forward'} for n,a,b in tags],
        'pixelfx':{'id':name,'name':'손각시 도트','fps':12,'loop':True,'frames':COLS*ROWS,'frameSize':[tw,th],'columns':COLS,'rows':ROWS,'sourceCell':[CW,CH],'scaleFromSource':tw/CW,'palette':colors,
                   'pivot':'cell bottom (feet baseline per frame is taken from the source cell)','rows_info':{'0':'idle','1':'run','2':'attack (windup 16-17, release 18-23)','3':'hurt 24, jump 25, fall 26, land 27, dash 28-29, stagger 30-31'}}}}
    json.dump(j,open(os.path.join(HERE,name+'.json'),'w'),ensure_ascii=False,indent=1)
    print(name,W,H,len(add))

build(2,96,128,'songaksi-px2',28)
build(3,64,85,'songaksi-px3',22)
