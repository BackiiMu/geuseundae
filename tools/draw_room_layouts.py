from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1];defs=json.loads((R/'docs/room-templates.json').read_text());examples=json.loads((R/'docs/generated-run-examples.json').read_text())
im=Image.new('RGB',(1440,1080),'#101722');d=ImageDraw.Draw(im)
f=ImageFont.truetype('/System/Library/Fonts/AppleSDGothicNeo.ttc',22);sm=ImageFont.truetype('/System/Library/Fonts/AppleSDGothicNeo.ttc',16)
d.text((28,18),'그슨대 · 방 후보 9종 / 맵마다 이동 포탈 1~4개',font=f,fill='#d9e7d0')
for i,(key,v) in enumerate(defs.items()):
 x=24+(i%3)*472;y=70+(i//3)*258;w=448;h=230;scale=416/v['width']
 d.rectangle((x,y,x+w,y+h),fill='#1b2835',outline='#3d515a');d.text((x+14,y+10),v['name'],font=f,fill='#b4d1bc')
 d.text((x+14,y+39),f"{v['width']} × 864 · 높낮이 / 발판 구조",font=sm,fill='#91a7af')
 fy=y+202;cursor=0
 for start,gap in v['gaps']+[[v['width'],0]]:
  d.rectangle((x+16+cursor*scale,fy,x+16+start*scale,fy+15),fill='#485967');d.line((x+16+cursor*scale,fy,x+16+start*scale,fy),fill='#a8bf9b',width=3);cursor=start+gap
 for px,py,pw in v['platforms']:
  yy=fy+(py-704)*scale;d.rectangle((x+16+px*scale,yy,x+16+(px+pw)*scale,yy+5),fill='#b2b89c')
 d.rectangle((x+16+70*scale,fy-20,x+16+110*scale,fy),fill='#92bdc0')
 d.rectangle((x+16+(v['width']-120)*scale,fy-20,x+16+(v['width']-80)*scale,fy),outline='#dfb979',width=2)
d.text((28,861),'시드 예시 · 같은 번호 + 같은 규칙 버전 = 같은 배치',font=f,fill='#d9e7d0')
for i,ex in enumerate(examples):
 y=911+i*49;names=[defs[r['template']]['name'] for r in ex['rooms']];txt=f"SEED {ex['seed']}  |  {len(names)}개 방  |  "+' / '.join(names[:3])+' …'
 d.text((28,y),txt,font=sm,fill='#a8bdbb')
d.text((28,1060),'발판 구조도 · 실제 아트 화면과 별도 / 파란색 시작, 금색 출구',font=sm,fill='#83979e')
im.save(R/'assets/maps/random-room-layouts.png')
