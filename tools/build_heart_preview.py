from pathlib import Path
from PIL import Image,ImageDraw
import json,math
R=Path(__file__).resolve().parents[1];A=R/'assets';D=A/'heart-final/geuseundae/heart-gather';j=json.loads((D/'heart-gather.json').read_text());motion=json.loads((A/'heart-motion.json').read_text());fx=Image.open(D/'heart-gather.png');sprites={n:Image.open(A/f'{n}.png') for n in ['songaksi','dosa','mudang']};origin=motion['origin'];W,H=480,260
bg=Image.new('RGBA',(W,H),'#161722');d=ImageDraw.Draw(bg)
# a haunted courtyard with balconies: the enemies really leave their original platforms
for x in range(0,W,40):
 d.rectangle((x,178,x+36,207),fill='#20232c');d.line((x,190,x+36,190),fill='#2e303a')
d.rectangle((0,211,W,259),fill='#23262d');d.line((0,211,W,211),fill='#51545a',width=2)
for x in range(0,W,17):d.line((x,231+(x%3)*5,x+5,231+(x%3)*5),fill='#393d42')
for x,y,width in [(80,145,61),(331,125,66)]:
 d.rectangle((x,y,x+width,y+4),fill='#4b4c54');d.rectangle((x+5,y+5,x+10,209),fill='#292b35');d.rectangle((x+width-10,y+5,x+width-5,209),fill='#292b35')
d.polygon([(147,69),(182,49),(221,69)],fill='#2e303d');d.rectangle((157,70,162,208),fill='#34343e');d.rectangle((207,70,212,208),fill='#34343e');d.rectangle((163,80,206,210),fill='#1c1d29');d.line((185,80,185,209),fill='#373541');d.rectangle((151,68,216,71),fill='#46414b')
frames=[]
for f,rec in enumerate(j['frames']):
 t=f/30;im=bg.copy();g=ImageDraw.Draw(im)
 def actor(kind,x,y,pose=0,flip=False,angle=0):
  sp=sprites[kind].crop((pose*64,0,(pose+1)*64,64));sp=sp.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if flip else sp
  if angle:sp=sp.rotate(angle,resample=Image.Resampling.NEAREST,center=(32,48))
  im.alpha_composite(sp,(round(x-32),round(y-55)))
 # player clearly braces then leans back as the hair is reeled in
 pose=6 if t<.3 else 7 if t<1.35 else 8 if t<2.6 else 9 if t<3 else f//4%6
 actor('songaksi',origin[0],origin[1],pose)
 for i,p in sorted(enumerate(motion['positions'][f]),key=lambda z:z[1]['y']):
  x=origin[0]+p['x'];y=origin[1]+p['y'];g.ellipse((x-11,y-1,x+11,y+3),fill='#11141c')
  angle=((-13 if p['x']>62 else 13) if 1.38<t<2.22 else 0)
  actor(motion['targets'][i]['kind'],x,y,f//4%6,flip=p['x']>0,angle=angle)
 r=rec['frame'];overlay=fx.crop((r['x'],r['y'],r['x']+W,r['y']+H));im.alpha_composite(overlay)
 frames.append(im)
atlas=Image.new('RGBA',(W*11,H*10))
for i,im in enumerate(frames):atlas.paste(im,((i%11)*W,(i//11)*H))
atlas.save(A/'heart-scene.png');bg.save(A/'heart-background.png')
durations=[33]*len(frames);durations[0]=650;durations[67]=150;durations[-1]=850
large=[im.convert('RGB').resize((960,520),Image.Resampling.NEAREST) for im in frames];large[0].save(A/'heart-gather.gif',save_all=True,append_images=large[1:],duration=durations,loop=0,optimize=True)
board=Image.new('RGB',(960,560),'#11121b');g=ImageDraw.Draw(board)
for idx,(f,label) in enumerate([(16,'01 / REACH'),(35,'02 / BIND'),(54,'03 / PULL'),(72,'04 / GATHER')]):
 x=(idx%2)*480;y=(idx//2)*280;board.paste(frames[f].convert('RGB'),(x,y+20));g.text((x+14,y+5),label,fill='#a8c4bc')
board.save(A/'heart-sequence.png')
html='''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>손각시의 심장 · 이리 오너라</title><style>*{box-sizing:border-box}body{margin:0;background:#101118;color:#e9e6d8;font:15px/1.7 system-ui}main{max-width:1120px;margin:auto;padding:42px 24px}small{color:#9ac4bb;letter-spacing:3px;font-size:11px}h1{margin:8px 0;font-size:42px;letter-spacing:-2px}p{color:#a3a5b1}header{display:flex;justify-content:space-between;gap:12px}a{color:#a3c4bb}canvas{display:block;width:100%;image-rendering:pixelated;background:#161722}.stage{border:1px solid #343643;margin-top:28px}.controls{padding:18px;background:#191c26;display:flex;gap:10px;flex-wrap:wrap;align-items:center}button,select{font:inherit;background:#232d34;color:#c4ddd2;border:1px solid #536268;border-radius:3px;padding:8px 16px;cursor:pointer}button:hover{background:#3c5055}input{width:100%;accent-color:#a0c9bd}label{color:#a5adb6;font-size:13px}.phases{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-top:20px}.phase{border-top:2px solid #343a45;padding:15px 5px;color:#7c8493}.phase b{display:block;font-size:17px}.phase.active{color:#d4e4d7;border-color:#a7cbbd}.notes{padding:18px 0;border-bottom:1px solid #343643}.status{color:#a7cbbd;margin-left:auto;font-size:13px}@media(max-width:650px){h1{font-size:32px}main{padding:24px 12px}header{display:block}.phase b{font-size:13px}.phase{font-size:11px}.controls{padding:12px}button,select{padding:7px 10px}}</style><main><header><div><small>GEUSEUNDAE / HEART SKILL STUDY</small><h1>이리 오너라.</h1><p>손각시의 심장 · 낮은 HP / 재사용 대기시간 30초</p></div><a href="index.html">캐릭터 시안으로 ↗</a></header><div class="stage"><canvas width="480" height="260" aria-label="머리카락이 적 다섯 명에게 뻗어 휘감고 그슨대 앞에 끌어모으는 애니메이션"></canvas><div class="controls"><button id="play">Ⅱ 일시정지</button><button id="replay">↺ 다시 보기</button><label>속도 <select id="speed"><option value="1">1×</option><option value="0.5">0.5×</option><option value="0.25">0.25×</option></select></label><span class="status" id="status">준비</span><input id="timeline" aria-label="애니메이션 시간" type="range" min="0" max="4.9" step="0.01" value="0"></div></div><div class="phases"><div class="phase"><b>01 · 뻗기</b>각 적에게 머리카락 발사</div><div class="phase"><b>02 · 휘감기</b>몸통을 여러 겹 포박</div><div class="phase"><b>03 · 당기기</b>몸을 젖혀 한꺼번에 회수</div><div class="phase"><b>04 · 집결</b>내 앞 한곳에 모으고 풀기</div></div><p class="notes">양옆과 높은 곳의 적 5명에게 각각 연결됩니다. 적은 머리카락에 붙잡힌 채 움직이며, 그슨대 앞에 모인 뒤 풀려납니다.<br>연출 확인을 위해 반복 재생합니다. 실제 스킬 쿨타임은 30초입니다.</p><p><a href="assets/heart-gather.gif" download>애니메이션 GIF ↓</a>　<a href="assets/heart-final/geuseundae/heart-gather/heart-gather.png" download>투명 이펙트 시트 ↓</a>　<a href="assets/heart-final/geuseundae/heart-gather/heart-gather.json" download>프레임 정보 ↓</a></p></main><script>
const canvas=document.querySelector('canvas'),ctx=canvas.getContext('2d'),image=new Image();image.src='assets/heart-scene.png';let time=0,last=0,playing=true,speed=1;const slider=document.querySelector('#timeline'),button=document.querySelector('#play');
function render(ms){if(!last)last=ms;if(playing)time=(time+Math.min(.05,(ms-last)/1000)*speed)%4.9;last=ms;let t=Math.max(0,time-.65);if(t>2.22)t=Math.max(2.22,t-.12);const f=Math.min(108,Math.floor(t*30));ctx.imageSmoothingEnabled=false;if(image.complete&&image.naturalWidth)ctx.drawImage(image,(f%11)*480,Math.floor(f/11)*260,480,260,0,0,480,260);slider.value=time;const phase=t<.3?-1:t<.9?0:t<1.38?1:t<2.22?2:3;document.querySelectorAll('.phase').forEach((el,i)=>el.classList.toggle('active',i===phase));document.querySelector('#status').textContent=phase<0?'준비':phase===0?'머리카락을 뻗는 중':phase===1?'적을 휘감는 중':phase===2?'내 앞으로 끌어오는 중':t<2.65?'집결 완료':'머리카락 풀기';requestAnimationFrame(render)}requestAnimationFrame(render);
button.onclick=()=>{playing=!playing;button.textContent=playing?'Ⅱ 일시정지':'▶ 재생'};document.querySelector('#replay').onclick=()=>{time=0;playing=true;button.textContent='Ⅱ 일시정지'};document.querySelector('#speed').onchange=e=>speed=Number(e.target.value);slider.oninput=e=>{time=Number(e.target.value);playing=false;button.textContent='▶ 재생'};
</script></html>'''
(R/'heart.html').write_text(html)
print('Created heart.html, GIF, scene atlas and four-phase contact image.')
