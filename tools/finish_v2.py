from PIL import Image,ImageDraw
from pathlib import Path
import json,shutil,runpy
root=Path(__file__).resolve().parents[1];a=root/'assets';data=json.loads((root/'assets-v1/manifest.json').read_text())
# retain source and engine metadata; presentation uses the original grid sheets.
for n in ['hair-whip','shadow-dash','corruption','purifying-talisman']:
 p=a/'pixelfx/geuseundae'/n; j=json.loads((p/f'{n}.json').read_text());frames=list(j['frames'].values()) if isinstance(j['frames'],dict) else j['frames'];r=frames[0]['frame'];pix=j['meta']['pixelfx'];shutil.copy(p/f'{n}.png',a/f'{n}.png');shutil.copy(p/f'{n}.json',a/f'{n}.json')
 data[n]={'file':f'{n}.png','frameWidth':r['w'],'frameHeight':r['h'],'frames':len(frames),'fps':pix['fps'],'loop':False,'pivot':pix['pivot'],'rects':[f['frame'] for f in frames]}
 im=Image.open(a/f'{n}.png');f=frames[min(len(frames)-1,6 if n=='hair-whip' else 20)]['frame'];im.crop((f['x'],f['y'],f['x']+r['w'],f['y']+r['h'])).resize((r['w']*3,r['h']*3),Image.Resampling.NEAREST).save(a/f'{n}-preview.png')
# Distinct anticipation / release / recovery poses for all three custom characters.
for n in ['songaksi','dosa','mudang']:
 original=Image.open(root/'assets-v1'/f'{n}.png');sheet=Image.new('RGBA',(64*10,64));sheet.paste(original,(0,0))
 for f in range(4):
  im=original.crop((0,0,64,64));d=ImageDraw.Draw(im)
  if f==0:im=im.rotate(7,resample=Image.Resampling.NEAREST,center=(31,53))
  elif f in [1,2]:
   im=im.rotate(-9 if f==1 else -5,resample=Image.Resampling.NEAREST,center=(31,53));d=ImageDraw.Draw(im)
   if n=='songaksi':
    for i in range(5):d.line([(37,17+i),(45,14+i),(54,20+i),(62,19+i)],fill=['#171523','#242333','#484254','#687f8c','#a8d7c5'][i],width=1)
   else:
    d.polygon([(36,29),(46,27),(53,31),(50,36),(39,35)],fill='#e9e5ce');d.rectangle((50,30,54,33),fill='#d7ccc1');d.rectangle((54,23,58,32),fill='#e1b66f');d.line((56,24,56,30),fill='#c84c58')
  else:im=im.rotate(-2,resample=Image.Resampling.NEAREST,center=(31,53))
  sheet.paste(im,((6+f)*64,0))
 sheet.save(a/f'{n}.png');data[n]['frames']=10;data[n]['idleFrames']=6
 j=json.loads((root/'assets-v1'/f'{n}.json').read_text());j['meta']['size']['w']=640;j['meta']['frameTags'] += [{'name':'attack','from':6,'to':9,'direction':'forward'}]
 for f in range(6,10):j['frames'][f'{n}_{f}']={'frame':{'x':f*64,'y':0,'w':64,'h':64},'duration':[180,80,100,180][f-6]}
 (a/f'{n}.json').write_text(json.dumps(j,indent=2))
(a/'manifest.json').write_text(json.dumps(data,indent=2))
p=root/'index.html';s=(root/'index-v1.html').read_text().replace('assets-v1/','assets/').replace('ART STUDY 001','ART STUDY 002 / PIXELFX').replace('첫 시안','두 번째 시안').replace('CHARACTERS / 64 × 64','CHARACTERS / IDLE + ATTACK').replace('EFFECTS / 128 × 96','EFFECTS / PIXELFX 30 FPS')
s=s.replace('const images={},cards=[];', 'const assetMeta='+json.dumps(data)+';\nfor(const [n,m] of Object.entries(assetMeta)){specs[n][0]=m.frameWidth;specs[n][1]=m.frameHeight;specs[n][2]=m.frames;specs[n][3]=m.fps;}\nconst images={},cards=[];')
s=s.replace("(f%s[2])*s[0],0,s[0],s[1]", "(assetMeta[name].rects?.[f%s[2]]?.x ?? (f%s[2])*s[0]),(assetMeta[name].rects?.[f%s[2]]?.y ?? 0),s[0],s[1]")
s=s.replace('Math.floor(time*s[3]),0,0','Math.floor(time*s[3])%(s[0]===64?6:s[2]),0,0')
s=s.replace("const cycle=time%2,hit=selected==='hair-whip'&&cycle>.3&&cycle<.65,fr=Math.min(11,Math.floor(cycle*18));", "const cycle=time%5,et=cycle-.35,hit=selected==='hair-whip'&&et>=.19&&et<.29,fr=Math.max(0,Math.min(specs[selected][2]-1,Math.floor(et*30)));const pose=cycle<.35?6:cycle<.44?7:cycle<.7?8:cycle<1?9:Math.floor(time*8)%6;")
s=s.replace("Math.floor(time*8),px,110", "selected==='purifying-talisman'?Math.floor(time*8)%6:pose,px,110").replace("Math.floor(time*8),354+(hit?5:0)","selected==='purifying-talisman'?pose:Math.floor(time*8)%6,340+(hit?5:0)").replace("Math.floor(time*8),448", "Math.floor(time*8)%6,448")
s=s.replace("Math.min(70,cycle*110)","Math.min(70,Math.max(0,et)*210)")
old="if(cycle<.7){if(selected==='purifying-talisman')draw(ctx,selected,fr,270,103,1,true);else draw(ctx,selected,fr,px+18,100)}"
new="if(et>=0&&et<specs[selected][2]/30){const m=assetMeta[selected],p=m.pivot;let ox=selected==='purifying-talisman'?372:274,oy=165;if(selected==='corruption')ox=320;if(selected==='shadow-dash')ox=274;draw(ctx,selected,fr,selected==='purifying-talisman'?ox-(m.frameWidth-p.x):ox-p.x,oy-p.y,1,selected==='purifying-talisman');}"
assert old in s;s=s.replace(old,new)
s=s.replace('초기 아트 시안 · 캐릭터 대기 6프레임 / 이펙트 12프레임','두 번째 시안 · 캐릭터 대기 + 공격 포즈 / 이펙트 30fps').replace('외부 에셋이나 코드를 복사하지 않은 자체 제작 시안.','').replace('의 코드 기반 픽셀 이펙트 접근을 참고한 자체 제작 시안.',' 라이브러리와 스킬을 사용했습니다. 오염 폭발은 dark-explosion 변형이며 나머지 이펙트는 전용 제작입니다.')
s=s.replace("light=false;", "light=false,freeze=0;")
s=s.replace("if(!paused)time+=Math.min(.05,(ms-last)/1000);last=ms;", "if(!paused){const dt=Math.min(.05,(ms-last)/1000);if(freeze>0)freeze=Math.max(0,freeze-dt);else{const next=time+dt,mark=selected==='hair-whip'?.54:selected==='purifying-talisman'?.85:-1;if(mark>0&&time%5<mark&&next%5>=mark){time=Math.floor(time/5)*5+mark;freeze=.1;}else time=next;}}last=ms;")
s=s.replace("selected=name;time=0;", "selected=name;time=0;freeze=0;")
p.write_text(s)
print('Integrated pixelfx sheets and three character attack pose sets.')
