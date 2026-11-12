// 손각시 도트 시트 생성기 (pixelfx PNG 인코더 사용, 의존 패키지 없음)
// 실행: node docs/mockups/songaksi-dot/generate.mjs
// 출력: songaksi-dot.png / songaksi-dot.json / songaksi-dot-x4.png (같은 폴더)
import {writeFileSync} from 'node:fs';
import {dirname,join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {encodePNG} from '../../../../vendor/pixelfx/tools/lib/png.mjs';
const HERE=dirname(fileURLToPath(import.meta.url));
const CW=96,CH=96,PXC=48,PYC=90,COLS=8,ROWS=4;
const hex=h=>[1,3,5].map(i=>parseInt(h.slice(i,i+2),16));
const SKIN=['#8a8298','#aaa3b8','#cdc7d6','#e3deea'].map(hex);
const FEET=['#6e6882','#968fa8'].map(hex);
const GOWN=['#6d667c','#9a93a3','#cfc9cb','#ece7de'].map(hex);
const RED=['#3d0f16','#6e1a22','#9a2630','#c04044'].map(hex);
const HAIR=['#08060f','#140f22','#221b38','#37305a'].map(hex);
const OUT=hex('#0f0a16'), HOUT=hex('#07050c'), EYE=hex('#e0453d');
const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
const rad=d=>d*Math.PI/180;
const JAG=[1.2,3.4,.6,2.8,1.0,3.2,.8,2.6,1.4];

function inPoly(pts,x,y){let c=false;for(let i=0,j=pts.length-1;i<pts.length;j=i++){const[a,b]=pts[i],[d,e]=pts[j];if((b>y)!==(e>y)&&x<(d-a)*(y-b)/(e-b)+a)c=!c}return c}
function segDist(px,py,ax,ay,bx,by){const dx=bx-ax,dy=by-ay,l=dx*dx+dy*dy;let t=l?((px-ax)*dx+(py-ay)*dy)/l:0;t=clamp(t);const cx=ax+t*dx-px,cy=ay+t*dy-py;return[Math.hypot(cx,cy),t]}

function renderFrame(P){
  const px=new Uint8Array(CW*CH*4);
  // 로컬(발끝 0,0, 위가 -y) → 셀 좌표
  const ca=Math.cos(P.tilt),sa=Math.sin(P.tilt),hip=[0,-26];
  const T=([x,y])=>{const vx=x-hip[0],vy=y-hip[1];return[PXC+P.ox+hip[0]+vx*ca-vy*sa,PYC+P.oy+hip[1]+vx*sa+vy*ca]};
  const paint=(maskFn,colorFn,outline)=>{
    const m=new Uint8Array(CW*CH);
    for(let y=0;y<CH;y++)for(let x=0;x<CW;x++)m[y*CW+x]=maskFn(x+.5,y+.5)?1:0;
    if(outline){for(let y=0;y<CH;y++)for(let x=0;x<CW;x++){const i=y*CW+x;if(m[i])continue;
      if((x>0&&m[i-1])||(x<CW-1&&m[i+1])||(y>0&&m[i-CW])||(y<CH-1&&m[i+CW])){px.set([...outline,255],i*4)}}}
    for(let y=0;y<CH;y++)for(let x=0;x<CW;x++)if(m[y*CW+x]){const c=colorFn(x+.5,y+.5);if(c)px.set([...c,255],(y*CW+x)*4)}
  };
  const chain=(pts,rs,thin)=>{const tp=pts.map(T);return(x,y)=>{for(let i=0;i<tp.length-1;i++){const[d,t]=segDist(x,y,tp[i][0],tp[i][1],tp[i+1][0],tp[i+1][1]);if(d<=rs[i]+(rs[i+1]-rs[i])*t)return true}return false}};
  const poly=pts=>{const tp=pts.map(T);return(x,y)=>inPoly(tp,x,y)};
  const ell=(cx,cy,rx,ry)=>{const[c0,c1]=T([cx,cy]);return(x,y)=>((x-c0)/rx)**2+((y-c1)/ry)**2<=1};
  const flat=c=>()=>c;

  const d=P.drop, bob=P.bob;
  const Hd=[2+P.lean+(P.headX||0),-47+d+bob+(P.headY||0)];
  const S=[.6+P.lean*.7,-40+d+bob];
  const Wc=[P.lean*.35,-27+d*.45];
  const hemY=-2.4;

  // ── 뒷머리 가닥 (몸 뒤)
  const hAng=P.hair, hl=P.hl;
  const strand=(k,front)=>{
    const dir=[-Math.sin(hAng),Math.cos(hAng)],perp=[dir[1],-dir[0]];
    const sx=Hd[0]-5.2+(k%3)*.6, sy=Hd[1]-4+k*1.15;
    const L=hl*(24+(k*7%5)*3.2), A=1.8+2.0*Math.abs(Math.sin(hAng)), ph=P.hp+k*.9;
    const pts=[],rs=[];
    for(let j=0;j<=10;j++){const t=j/10,w=A*t*Math.sin(t*4.2+ph);
      pts.push([sx+dir[0]*L*t+perp[0]*w,sy+dir[1]*L*t+perp[1]*w]);rs.push(Math.max(.6,3.4-2.8*t))}
    return{pts,rs};
  };
  const hairCol=(x,y)=>{const v=Math.sin(x*1.1-y*.65+P.hp)*.5+.5;return HAIR[v>.86?3:v>.58?2:v>.22?1:0]};
  for(let k=0;k<9;k++){const s=strand(k);paint(chain(s.pts,s.rs),hairCol,HOUT)}

  // ── 뒤쪽 팔 (소복 뒤)
  const arm=(near)=>{
    const sh=[S[0]+(near?1.4:-1.6),S[1]+2.6];
    const a1=rad(near?P.nA1:P.fA1),a2=rad(near?P.nA2:P.fA2),u=10,f=P.reach&&near?11:9;
    const E=[sh[0]+u*Math.sin(a1),sh[1]+u*Math.cos(a1)];
    const H=[E[0]+f*Math.sin(a2),E[1]+f*Math.cos(a2)];
    const tip=[H[0]+3.4*Math.sin(a2),H[1]+3.4*Math.cos(a2)];
    const tone=near?0:-1;
    paint(chain([sh,E,H],[2.2,2.9,3.3]),(x,y)=>{const i=(y<(sh[1]+E[1])/2-1&&false)?0:2;const v=Math.sin(x*.9+y*.7)>.65?-1:0;return GOWN[clamp(i+tone+v+ (near?1:0),0,3)|0]},OUT);
    paint(chain([H,tip],[1.9,1.5]),(x,y)=>SKIN[near?2:1],OUT);
    if(P.fingers&&near){for(const o of[-.55,0,.55]){const ang=a2+o,ft=[tip[0]+3*Math.sin(ang),tip[1]+3*Math.cos(ang)];paint(chain([tip,ft],[.75,.5]),flat(SKIN[2]),OUT)}}
  };
  arm(false);

  // ── 다리/발
  const foot=(x0,lift,sx)=>{
    const fp=[x0,-1.8-lift];
    if(lift>.5||P.legs)paint(chain([[x0*.5,-11],[(x0*.5+x0)/2-(P.legs?1:0),-6-lift*.5],fp],[2.1,1.7,1.5]),flat(SKIN[0]),OUT);
    paint(chain([fp,[x0+3.8*sx,fp[1]+(lift>2?1.2:0)]],[1.7,1.1]),(x,y)=>FEET[1],OUT);
  };
  foot(P.fF[0],P.fF[1],1);foot(P.fN[0],P.fN[1],1);

  // ── 목
  paint(chain([[Hd[0]-.2,Hd[1]+3],[S[0],S[1]+.5]],[1.8,2.2]),flat(SKIN[0]),OUT);

  // ── 소복
  const swz=P.sw, hf=12+P.skF, hb=-(13+P.skB);
  const wob=i=>Math.sin(P.hp*1.3+i*1.1)*P.skW;
  const hem=[];
  for(let i=0;i<9;i++){const t=i/8;hem.push([hf+(hb-hf)*t+wob(i),hemY-JAG[i]])}
  const gownPts=[[S[0]-4.4,S[1]],[S[0]+4.2,S[1]+.4],[Wc[0]+4.2,Wc[1]],[(Wc[0]+4.2+hf)/2+.8+swz*.3,(Wc[1]+hemY)/2],...hem,[(Wc[0]-3.4+hb)/2-1-swz*.5,(Wc[1]+hemY)/2],[Wc[0]-4.2,Wc[1]]];
  const gcx=Wc[0];
  paint(poly(gownPts),(x,y)=>{
    const u=(x-(PXC+P.ox+gcx))/10;let i=2+(u>.28?1:0)-(u<-.3?1:0);
    if(Math.sin((x-PXC)*1.25+y*.14+P.hp*.5)>.72)i--;
    if(y>PYC+P.oy-6.5)i--;
    return GOWN[clamp(i,0,3)|0]},OUT);
  // 깃(소복 앞섶): 밝은 V
  paint(poly([[S[0]-.5,S[1]-.2],[S[0]+3.2,S[1]+.2],[S[0]+2.4,S[1]+5],[S[0]-1,S[1]+1.6]]),(x,y)=>GOWN[3],OUT);
  // 고름(붉은 리본): 가슴→허리 늘어짐
  paint(chain([[S[0]+1.6,S[1]+3.2],[Wc[0]+2.2,Wc[1]-2.4],[Wc[0]+3,Wc[1]+4.5]],[1.2,1.4,1.0]),(x,y)=>RED[2],OUT);
  // 허리띠
  paint(poly([[Wc[0]-3.6,Wc[1]-2.2],[Wc[0]+3.9,Wc[1]-2.6],[Wc[0]+3.7,Wc[1]+1.8],[Wc[0]-3.5,Wc[1]+1.8]]),(x,y)=>RED[(y<PYC+P.oy+Wc[1]-1?3:y<PYC+P.oy+Wc[1]+.6?2:1)],OUT);
  // 허리띠 뒤 자락
  {const dir=[-Math.sin(P.sash),Math.cos(P.sash)],pp=[dir[1],-dir[0]];
   for(const[len,off] of[[12,0],[8,1.6]]){const pts=[],rs=[];for(let j=0;j<=6;j++){const t=j/6,w=1.6*t*Math.sin(t*3.6+P.hp+off);pts.push([Wc[0]-3.1+dir[0]*len*t+pp[0]*w,Wc[1]+off+dir[1]*len*t+pp[1]*w]);rs.push(1.5-.8*t)}
   paint(chain(pts,rs),(x,y)=>RED[1+(Math.sin(x+y)>.5?1:0)],OUT)}}

  // ── 머리
  paint(ell(Hd[0],Hd[1],5.3,5.9),(x,y)=>{const[hx,hy]=T([Hd[0],Hd[1]]);return SKIN[x>hx+2?3:2]},OUT);
  // 머리카락 덮개 (위·뒤)
  {const[c0,c1]=T([Hd[0]-1.3,Hd[1]-1.3]),[h0,h1]=T(Hd);
   paint((x,y)=>((x-c0)/6.5)**2+((y-c1)/7)**2<=1&&(x<h0+1.2||y<h1-3.4),hairCol,HOUT);}
  // 앞머리 가닥(얼굴 가림)
  paint(chain([[Hd[0]+2.4,Hd[1]-4.6],[Hd[0]+2.8,Hd[1]-.5],[Hd[0]+2.2+P.bx,Hd[1]+3.4]],[1.7,1.4,.7]),hairCol,HOUT);
  // 눈
  {const[e0,e1]=T([Hd[0]+3.4,Hd[1]+.2]);paint((x,y)=>Math.abs(x-e0)<.9&&Math.abs(y-e1)<.7,flat(EYE),null)}
  // 가슴 앞으로 내려온 머리 한 줄
  {const pts=[],rs=[];const dir=[-Math.sin(P.hair*.5)*.6,1];for(let j=0;j<=6;j++){const t=j/6;pts.push([Hd[0]+.8+dir[0]*14*t*(P.fl||1)+Math.sin(t*3+P.hp)*.8,Hd[1]+2+14*t*(P.fl||1)]);rs.push(1.6-.9*t)}
   if(P.front)paint(chain(pts,rs),hairCol,HOUT)}

  // ── 앞쪽 팔 (소복 위)
  arm(true);
  return px;
}

const base={tilt:0,ox:0,oy:0,drop:0,bob:0,lean:0,hair:.1,hl:1,hp:0,sw:0,skF:0,skB:0,skW:.6,sash:.12,bx:0,
  nA1:8,nA2:20,fA1:-5,fA2:-1,fN:[3,0],fF:[-3,0],front:true,reach:false,fingers:false,legs:false};
const P=o=>({...base,...o});
const frames=[];
// 0행 idle ───────────────
for(let i=0;i<8;i++){const a=i/8*Math.PI*2;
  frames.push(P({bob:Math.sin(a)*.8,hp:a,hair:.1+.05*Math.sin(a+1),skW:.7,nA1:8+2*Math.sin(a),nA2:20+3*Math.sin(a+.5),fA1:-5-2*Math.sin(a),sash:.12+.06*Math.sin(a+2),sw:Math.sin(a)*.8,skB:Math.sin(a)*.6}))}
// 1행 run ────────────────
for(let i=0;i<8;i++){const a=i/8*Math.PI*2,s=Math.sin(a),c=Math.cos(a);
  frames.push(P({tilt:.13,lean:2.2,bob:-Math.abs(s)*1.8,hair:1.15+.08*s,hl:1,hp:a*1.5,skB:5,skF:-2,skW:1.4,sash:1.0,sw:2,front:false,legs:true,
    nA1:-44*s,nA2:-44*s+34,fA1:44*s,fA2:44*s+30,fN:[7*s,Math.max(0,-c)*5.5],fF:[-7*s,Math.max(0,c)*5.5]}))}
// 2행 attack/windup/release ─
const AT=[
 {},
 {lean:-1.5,tilt:-.04,nA1:-62,nA2:-96,fA1:-20,fA2:-30,hair:.35,hp:1},
 {lean:2,tilt:.07,nA1:72,nA2:80,fA1:20,fA2:10,hair:-.55,hl:1.15,hp:2,fingers:true,reach:true,front:false},
 {lean:3.4,tilt:.12,nA1:86,nA2:90,fA1:30,fA2:40,hair:-1.15,hl:1.35,hp:3,fingers:true,reach:true,front:false,skB:3,fN:[5,0],fF:[-6,0]},
 {lean:3.6,tilt:.12,nA1:88,nA2:92,fA1:34,fA2:44,hair:-1.3,hl:1.45,hp:4,fingers:true,reach:true,front:false,skB:3,fN:[5,0],fF:[-6,0]},
 {lean:2,tilt:.06,nA1:56,nA2:62,fA1:14,fA2:20,hair:-.5,hl:1.1,hp:5,reach:true,front:false},
 {lean:.8,nA1:30,nA2:40,fA1:2,fA2:8,hair:.1,hp:6},
 {nA1:12,nA2:22,hair:.1,hp:7}];
AT.forEach((o,i)=>frames.push(P({hp:i*.8,...o})));
// 3행 hurt/jump/dash ─────
const AIR=[
 {drop:7,lean:-2.4,tilt:-.14,nA1:-24,nA2:-124,fA1:-40,fA2:-120,hair:.55,hp:1,headX:-1.5,headY:1,bob:0,fN:[4,0],fF:[-5,0],skW:1.2},
 {drop:1,lean:1,hair:.5,hp:2,nA1:58,nA2:112,fA1:-30,fA2:-100,fN:[6,6],fF:[0,9],legs:true,skB:2,skF:-1,skW:1.4},
 {drop:-1,lean:.5,hair:-.35,hl:1.1,hp:3,nA1:84,nA2:96,fA1:-58,fA2:-70,fN:[3,0],fF:[-3,0],skB:-1,skW:1.6,sash:-.3},
 {drop:4,lean:-.5,hair:.15,hp:4,nA1:32,nA2:40,fA1:-12,fA2:-18,fN:[5,0],fF:[-5,0],skB:4,skW:1.2},
 {tilt:1.2,oy:-23,ox:-2,lean:1,hair:1.5,hl:.8,hp:5,skB:7,skF:-6,skW:1.8,sash:1.4,nA1:-70,nA2:-78,fA1:-80,fA2:-86,fN:[-3,0],fF:[-8,0],legs:true,front:false},
 {tilt:1.24,oy:-24,ox:0,lean:1,hair:1.52,hl:.85,hp:6,skB:8,skF:-6,skW:2,sash:1.45,nA1:-76,nA2:-84,fA1:-70,fA2:-78,fN:[-4,0],fF:[-9,0],legs:true,front:false},
 {drop:5,lean:-3,tilt:-.2,headY:3,headX:-2,nA1:-10,nA2:-100,fA1:-30,fA2:-110,hair:.4,hp:7,fN:[4,0],fF:[-3,0],skW:1.1},
 {drop:6,lean:-3.5,tilt:-.26,headY:3.5,headX:-2.5,nA1:-5,nA2:-96,fA1:-24,fA2:-104,hair:.3,hp:8,fN:[4,0],fF:[-3,0],skW:1.1}];
AIR.forEach(o=>frames.push(P(o)));

const sheet=new Uint8Array(COLS*CW*ROWS*CH*4);
frames.forEach((p,i)=>{
  const f=renderFrame(p),cx=(i%COLS)*CW,cy=Math.floor(i/COLS)*CH;
  for(let y=0;y<CH;y++)sheet.set(f.subarray(y*CW*4,(y+1)*CW*4),((cy+y)*COLS*CW+cx)*4);
});
const SW=COLS*CW,SH=ROWS*CH;
writeFileSync(join(HERE,'songaksi-dot.png'),encodePNG(SW,SH,sheet));
// 4배 확대 검수용
const K=4,big=new Uint8Array(SW*K*SH*K*4);
for(let y=0;y<SH*K;y++)for(let x=0;x<SW*K;x++){const s=((y/K|0)*SW+(x/K|0))*4,o=(y*SW*K+x)*4;
  const a=sheet[s+3];const bg=((x/K/CW|0)+(y/K/CH|0))%2?[44,40,56]:[36,33,48];
  big[o]=a?sheet[s]:bg[0];big[o+1]=a?sheet[s+1]:bg[1];big[o+2]=a?sheet[s+2]:bg[2];big[o+3]=255}
writeFileSync(join(HERE,'songaksi-dot-x4.png'),encodePNG(SW*K,SH*K,big));
const NAMES=['idle','run','attack','air'];
const json={frames:frames.map((_,i)=>({filename:`songaksi-dot ${i}`,frame:{x:(i%COLS)*CW,y:Math.floor(i/COLS)*CH,w:CW,h:CH},rotated:false,trimmed:false,spriteSourceSize:{x:0,y:0,w:CW,h:CH},sourceSize:{w:CW,h:CH},duration:83})),
 meta:{app:'geuseundae songaksi generator',version:'1',image:'songaksi-dot.png',format:'RGBA8888',size:{w:SW,h:SH},scale:'1',
  frameTags:[{name:'idle',from:0,to:7,direction:'forward'},{name:'run',from:8,to:15,direction:'forward'},{name:'attack',from:16,to:23,direction:'forward'},
   {name:'hurt',from:24,to:24,direction:'forward'},{name:'jump',from:25,to:25,direction:'forward'},{name:'fall',from:26,to:26,direction:'forward'},{name:'land',from:27,to:27,direction:'forward'},
   {name:'dash',from:28,to:29,direction:'forward'},{name:'stagger',from:30,to:31,direction:'forward'}],
  pixelfx:{id:'songaksi-dot',name:'손각시 도트',fps:12,loop:true,frames:frames.length,frameSize:[CW,CH],pivot:[PXC,PYC],columns:COLS,rows:ROWS,
   rows_info:{'0':'idle','1':'run','2':'attack(windup 16-17, reach 18-21, recover 22-23)','3':'hurt 24, jump 25, fall 26, land 27, dash 28-29, stagger 30-31'}}}};
writeFileSync(join(HERE,'songaksi-dot.json'),JSON.stringify(json,null,1));
console.log('ok',SW,SH);
