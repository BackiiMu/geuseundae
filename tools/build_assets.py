from PIL import Image, ImageDraw, ImageFont
import math,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'assets'
P={'ink':'#171523','hair':'#242333','edge':'#484254','white':'#e9e5ce','shade':'#aaa9a4','skin':'#d7ccc1','red':'#c84c58','mint':'#91c9bb','gold':'#e1b66f'}
def sprite(kind,f):
 im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);bob=[0,0,-1,-1,0,1][f];y=bob
 def r(box,c):d.rectangle(tuple(v+(y if i%2 else 0) for i,v in enumerate(box)),fill=P.get(c,c))
 def poly(pts,c):d.polygon([(x,z+y) for x,z in pts],fill=P.get(c,c))
 if kind=='songaksi':
  # child's feet and a borrowed, oversized mourning hanbok
  r((26,52,29,55),'skin');r((35,52,38,55),'skin')
  poly([(23,27),(40,27),(45,50),(39,53),(31,51),(21,53),(19,48)],'ink')
  poly([(25,28),(38,28),(42,49),(36,50),(30,48),(22,50)],'white')
  poly([(27,31),(29,33),(26,48),(23,49)],'shade');r((30,32,38,34),'red');r((34,34,35,41),'red')
  poly([(23,29),(17,35),(17,42),(23,40),(28,31)],'white');r((16,41,19,44),'skin')
  poly([(39,29),(44,32),(47,39),(41,41),(35,31)],'white');r((44,40,47,42),'skin')
  poly([(24,12),(35,10),(42,15),(43,30),(48,43),(43,40),(40,33),(38,26),(23,31),(20,40),(18,36),(20,24),(20,17)],'ink')
  r((25,18,36,27),'skin');r((25,18,31,25),'white')
  poly([(23,13),(35,12),(40,16),(37,23),(34,20),(33,28),(30,27),(30,18),(26,26),(23,30)],'hair')
  r((34,24,36,24),'red');r((24,15,25,21),'edge');r((39,21,40,29),'edge')
  for i in range(3):r((19-i*2,33+i*4,20-i*2,38+i*4),'hair')
 elif kind=='dosa':
  r((23,51,30,55),'ink');r((35,51,42,55),'ink')
  poly([(23,28),(40,28),(44,51),(20,51)],'shade');poly([(25,29),(37,29),(40,49),(24,49)],'white')
  poly([(25,28),(31,34),(38,28),(34,38),(34,50),(30,50),(29,36)],'gold')
  r((24,38,39,40),'red');r((24,41,26,48),'red')
  poly([(23,28),(16,33),(14,42),(21,43),(28,32)],'white');poly([(38,28),(44,31),(48,35),(44,40),(35,33)],'white')
  r((44,33,48,36),'skin');r((47,26,53,36),'gold');r((49,28,50,34),'red');r((48,30,52,30),'red')
  r((26,17,37,27),'skin');r((26,17,28,23),'shade');r((35,21,37,22),'ink');r((31,26,36,28),'ink')
  r((24,10,39,17),'ink');r((27,7,36,11),'hair');r((20,16,43,18),'ink');r((27,11,36,12),'edge')
 else:
  r((23,51,29,55),'ink');r((35,51,41,55),'ink')
  poly([(24,28),(39,28),(44,51),(20,51)],'white');poly([(29,29),(34,31),(34,49),(29,49)],'red')
  poly([(24,28),(17,30),(12,38),(19,41),(29,32)],'white');poly([(38,28),(44,31),(48,38),(41,42),(35,32)],'shade')
  r((12,37,17,40),'skin');r((44,39,48,42),'skin');r((47,33,48,43),'gold')
  for a,b in [(45,32),(49,35),(45,39)]:r((a,b,a+3,b+3),'gold')
  r((26,16,37,27),'skin');r((26,16,28,24),'shade');r((28,21,29,21),'ink');r((35,21,36,21),'ink');r((31,25,34,25),'red')
  poly([(23,17),(25,11),(36,10),(40,16),(38,20),(36,16),(27,16),(25,24),(22,24)],'ink')
  r((20,12,41,14),'red');r((24,9,27,11),'gold');r((36,8,38,11),'mint')
  r((22,26,24,34),'red');r((40,24,42,33),'gold')
 return im

def effect(kind,f):
 im=Image.new('RGBA',(128,96));d=ImageDraw.Draw(im);t=f/11
 if kind=='hair-whip':
  if f<2:return im
  for strand in range(5):
   pts=[]
   for k in range(21):
    q=k/20;pts.append((int(20+q*90*min(1,t*2)),int(55-math.sin(q*3.7-t*4)*18*q+strand*2)))
   d.line(pts,fill=['#242333','#484254','#756579','#b6a9b1','#91c9bb'][strand],width=2 if strand<3 else 1)
  if 4<=f<=7:
   for a in range(8):
    x=int(104+math.cos(a*math.pi/4)*(f-3)*4);y=int(52+math.sin(a*math.pi/4)*(f-3)*4);d.rectangle((x,y,x+2,y+2),fill='#e9e5ce')
 elif kind=='shadow-dash':
  for i in range(22):
   q=((i*31)%23)/23;x=int(18+q*88);h=int((1-t)*22*(1-q)+3);y=66-int(math.sin(q*8+t*4)*3)
   d.rectangle((x,y-h,x+3+int(t*8),y),fill=['#242333','#484254','#719e99'][i%3])
  d.line((14,68,111,68),fill='#91c9bb',width=1)
 elif kind=='corruption':
  rad=8+t*35
  for i in range(24):
   a=i*2.399;x=int(64+math.cos(a)*rad);y=int(48+math.sin(a)*rad*.7);s=max(1,4-f//3)
   d.rectangle((x,y,x+s,y+s),fill=['#91c9bb','#548d89','#484254'][i%3])
  for i in range(7):
   x=40+i*8;h=int(math.sin(i*2+1)**2*25*(1-t));d.rectangle((x,64-h,x+2,67),fill='#719e99')
 elif kind=='purifying-talisman':
  x=int(15+t*94);y=int(45-math.sin(t*math.pi)*12)
  for j in range(5):d.rectangle((x-j*6,y+3,x-j*6+2,y+4),fill=['#e9e5ce','#e1b66f','#c84c58','#783e4e','#484254'][j])
  d.rectangle((x,y-6,x+7,y+7),fill='#e9e5ce');d.line((x+3,y-4,x+3,y+5),fill='#c84c58',width=1);d.line((x+1,y,x+5,y),fill='#c84c58')
 return im
meta={}
for name in ['songaksi','dosa','mudang','hair-whip','shadow-dash','corruption','purifying-talisman']:
 char=name in ['songaksi','dosa','mudang'];n=6 if char else 12;w,h=(64,64) if char else (128,96)
 frames=[sprite(name,f) if char else effect(name,f) for f in range(n)];sheet=Image.new('RGBA',(w*n,h))
 for f,im in enumerate(frames):sheet.paste(im,(f*w,0))
 sheet.save(OUT/f'{name}.png');frames[0 if char else 5].resize((w*4,h*4),Image.Resampling.NEAREST).save(OUT/f'{name}-preview.png')
 meta[name]={'file':f'{name}.png','frameWidth':w,'frameHeight':h,'frames':n,'fps':8 if char else 18,'loop':char,'pivot':{'x':w//2,'y':55 if char else 68}}
 (OUT/f'{name}.json').write_text(json.dumps({'frames':{f'{name}_{f}':{'frame':{'x':f*w,'y':0,'w':w,'h':h},'duration':125 if char else 56} for f in range(n)},'meta':{'image':f'{name}.png','size':{'w':w*n,'h':h},'scale':'1','frameTags':[{'name':'idle' if char else 'effect','from':0,'to':n-1,'direction':'forward'}],'pivot':meta[name]['pivot']}},indent=2))
(OUT/'manifest.json').write_text(json.dumps(meta,indent=2))
# contact sheet
board=Image.new('RGB',(1200,670),'#11121b');d=ImageDraw.Draw(board)
for i,name in enumerate(['songaksi','dosa','mudang']):
 im=sprite(name,0).resize((256,256),Image.Resampling.NEAREST);board.paste(im,(80+i*390,20),im);d.text((100+i*390,285),name.upper(),fill='#91c9bb')
for i,name in enumerate(['hair-whip','shadow-dash','corruption','purifying-talisman']):
 im=effect(name,5).resize((256,192),Image.Resampling.NEAREST);board.paste(im,(20+i*295,360),im);d.text((30+i*295,580),name.upper(),fill='#e1b66f')
board.save(OUT/'overview.png')
print('Created 7 PNG sheets, 7 frame metadata files, previews and manifest.')
