// 범의 송곳니 F 스킬: 푸른 호랑이 머리 기공파 (입 벌린 호랑이 머리 + 꼬리 기운)
// 실행: node docs/mockups/tiger-fang/generate.mjs  → tiger-wave.png / tiger-wave.json / tiger-wave-x3.png
import {writeFileSync} from 'node:fs';
import {dirname,join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {encodePNG} from '../../../vendor/pixelfx/tools/lib/png.mjs';
const HERE=dirname(fileURLToPath(import.meta.url));
const FW=200,FH=112,COLS=6,N=12,CX=142,CY=58,FPS=20,S=1.28;
const BAY=[[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]];
const hex=h=>[1,3,5].map(i=>parseInt(h.slice(i,i+2),16));
const C={ol:hex('#081028'),d3:hex('#0f1f4a'),d2:hex('#1a3a78'),d1:hex('#2a5cac'),m:hex('#3f82d6'),l:hex('#78b8f2'),hl:hex('#b6e2ff'),
 tooth:hex('#ecf8ff'),tooth2:hex('#b8d4ea'),mouth:hex('#070d22'),tongue:hex('#4a8fcf'),eye:hex('#f4fdff'),stripe:hex('#0c1a40')};
const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
const inPoly=(p,x,y)=>{let c=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const[a,b]=p[i],[d,e]=p[j];if((b>y)!==(e>y)&&x<(d-a)*(y-b)/(e-b)+a)c=!c}return c};
const dseg=(px,py,ax,ay,bx,by)=>{const dx=bx-ax,dy=by-ay,l=dx*dx+dy*dy;let t=l?((px-ax)*dx+(py-ay)*dy)/l:0;t=clamp(t);return[Math.hypot(ax+t*dx-px,ay+t*dy-py),t]};
const hash=(x,y,s)=>{const v=Math.sin(x*127.1+y*311.7+s*74.7)*43758.5453;return v-Math.floor(v)};
function frame(fi){
  const ph=fi/N*Math.PI*2, px=new Uint8Array(FW*FH*4);
  const bob=Math.round(Math.sin(ph)*1.6), jaw=46+Math.round(Math.sin(ph*2)*4); // 턱 각도(도)
  const rot=([x,y],a)=>[x*Math.cos(a)-y*Math.sin(a),x*Math.sin(a)+y*Math.cos(a)];
  const T=([x,y])=>[CX+x*S,CY+bob+y*S];
  const Ts=([x,y])=>[CX+x,CY+bob+y];
  const put=(x,y,c)=>{x|=0;y|=0;if(x<0||y<0||x>=FW||y>=FH)return;px.set([...c,255],(y*FW+x)*4)};
  const mask=(fn,col,outline)=>{
    const m=new Uint8Array(FW*FH);
    for(let y=0;y<FH;y++)for(let x=0;x<FW;x++)m[y*FW+x]=fn(x+.5,y+.5)?1:0;
    if(outline)for(let y=0;y<FH;y++)for(let x=0;x<FW;x++){if(m[y*FW+x])continue;
      if((x>0&&m[y*FW+x-1])||(x<FW-1&&m[y*FW+x+1])||(y>0&&m[(y-1)*FW+x])||(y<FH-1&&m[(y+1)*FW+x]))put(x,y,outline)}
    for(let y=0;y<FH;y++)for(let x=0;x<FW;x++)if(m[y*FW+x]){const c=col(x+.5,y+.5);if(c)put(x,y,c)}
  };
  const poly=pts=>{const t=pts.map(T);return(x,y)=>inPoly(t,x,y)};
  // ── 꼬리 기운: 머리 뒤로 흩어지는 푸른 줄기 (디더로 끝이 풀림, 광 없음)
  const streams=[[-12,118,6.5,0],[-5,104,5.5,1.3],[3,126,6.2,2.1],[10,96,5,3.4],[-1,84,4.2,4.6],[-18,76,4,5.4]];
  streams.forEach(([y0,len,w,off],k)=>{
    const pts=[];for(let j=0;j<=12;j++){const t=j/12,x=-30-len*.8*t,y=y0*S*.8+Math.sin(t*5+ph*1.0+off)*(2+7*t)-t*3;pts.push([x,y])}
    const tp=pts.map(Ts);
    mask((x,y)=>{for(let i=0;i<tp.length-1;i++){const[d,t]=dseg(x,y,tp[i][0],tp[i][1],tp[i+1][0],tp[i+1][1]);const tt=(i+t)/12,r=Math.max(.6,w*1.15*(1-tt)**.85);
        if(d<=r){const th=(tt-.45)*1.7;return BAY[(y|0)&3][(x|0)&3]/16>=th}}return false},
      (x,y)=>{let best=9;for(let i=0;i<tp.length-1;i++){const[d,t]=dseg(x,y,tp[i][0],tp[i][1],tp[i+1][0],tp[i+1][1]);const tt=(i+t)/12,r=Math.max(.6,w*1.15*(1-tt)**.85);best=Math.min(best,d/r)}
        return best<.4?C.l:best<.75?C.m:C.d1},null);
  });
  // ── 귀: 둥근 반원 두 개 (뒤쪽은 어둡게)
  const ell=(cx,cy,rx,ry)=>{const[c0,c1]=T([cx,cy]);return(x,y)=>((x-c0)/(rx*S))**2+((y-c1)/(ry*S))**2<=1};
  mask(ell(-23,-30,6,7),()=>C.d2,C.ol);
  mask(ell(-12,-35,7.5,8.5),()=>C.d1,C.ol);
  mask(ell(-12,-34,4,5),()=>C.l,null);
  // ── 볼 털(갈기): 크고 뒤로 뻗는 가시
  [[[-22,-2],[-42,4],[-30,10]],[[-20,5],[-38,15],[-24,16]],[[-14,8],[-28,22],[-12,15]],[[-24,-10],[-40,-6],[-26,-2]]].forEach(t=>mask(poly(t),(x,y)=>C.d2,C.ol));
  // ── 머리 윗부분(둥근 두개골 + 짧고 높은 주둥이)
  const head=[[-26,-8],[-27,-20],[-20,-30],[-8,-35],[6,-33],[18,-27],[25,-22],[30,-18],[34,-14],[35,-8],[32,-4],[24,-3],[14,-1],[6,4],[-6,9],[-18,7],[-25,1]];
  const ht=head.map(T);
  // ── 입 안 + 아래턱 (크게 벌림)
  const hinge=[6,4],a=jaw*Math.PI/180;
  const jawPts=[[-4,-1],[24,2],[31,6],[27,12],[8,11],[-4,7]].map(p=>{const r=rot([p[0],p[1]],a);return[hinge[0]+r[0],hinge[1]+r[1]]});
  mask(poly([[8,-2],[31,-4],jawPts[2],jawPts[1],jawPts[0],[4,5]]),()=>C.mouth,null);
  const tg=[[12,5],[22,4],[28,6]].map(p=>{const r=rot([p[0]-hinge[0],p[1]-hinge[1]+1],a*.75);return[hinge[0]+r[0],hinge[1]+r[1]]});
  mask(poly([tg[0],tg[1],tg[2],[tg[2][0]-2,tg[2][1]+4],[tg[0][0]+2,tg[0][1]+5]]),()=>C.tongue,null);
  mask(poly(jawPts),(x,y)=>{const t=(y-(CY+bob+hinge[1]*S))/22;return t<.25?C.d1:t<.6?C.d2:C.d3},C.ol);
  const lf=[[20,3],[24,3],[22,-9]].map(p=>{const r=rot(p,a);return[hinge[0]+r[0],hinge[1]+r[1]]});
  mask(poly(lf),()=>C.tooth,C.ol);
  // ── 머리 본체
  mask((x,y)=>inPoly(ht,x,y),(x,y)=>{
    const ty=(y-(CY+bob))/-30,tx=(x-CX)/40;
    let c=ty>.62?C.l:ty>.25?C.m:ty>-.05?C.d1:C.d2; return c},C.ol);
  // 이마 줄무늬 (위에서 내려오는 굵은 줄 4개 + 왕(王) 느낌)
  [[[-17,-32],[-12,-34],[-12,-24],[-16,-22]],[[-9,-35],[-3,-35],[-4,-22],[-9,-23]],[[0,-34],[6,-32],[4,-20],[-1,-21]],[[10,-30],[15,-27],[12,-18],[8,-20]]].forEach(p=>mask(poly(p),()=>C.stripe,null));
  // 뺨 줄무늬
  [[[-20,-12],[-8,-6],[-9,-1],[-22,-6]],[[-20,0],[-9,2],[-12,7],[-22,5]]].forEach(p=>mask(poly(p),()=>C.stripe,null));
  // 주둥이 하이라이트 + 수염 패드
  mask(poly([[24,-21],[30,-17],[33,-13],[30,-14],[24,-18]]),()=>C.hl,null);
  mask(poly([[21,-8],[33,-9],[33,-3],[24,-2]]),()=>C.l,C.ol);
  // 코
  mask(poly([[31,-16],[36,-12],[35,-8],[31,-10]]),()=>C.d3,C.ol);
  // 송곳니 (위: 길고 굵게)
  mask(poly([[23,-3],[29,-3],[26,13]]),()=>C.tooth,C.ol);
  mask(poly([[31,-4],[34,-4],[33,2]]),()=>C.tooth2,null);
  // 눈: 치켜뜬 사나운 눈 + 짙은 눈썹
  mask(poly([[10,-18],[21,-15],[20,-11],[10,-13]]),()=>C.eye,C.ol);
  mask(poly([[16,-17],[20,-15.5],[19.5,-12.5],[16,-13.5]]),()=>C.d3,null);
  mask(poly([[8,-22],[23,-17],[23,-15],[8,-19]]),()=>C.stripe,null);
  // 수염 점
  [[28,-6],[26,-4],[30,-5]].forEach(([x,y])=>{const t=T([x,y]);put(t[0],t[1],C.d3)});
  return px;
}
const sheet=new Uint8Array(COLS*FW*Math.ceil(N/COLS)*FH*4);
const ROWS=Math.ceil(N/COLS);
for(let i=0;i<N;i++){const f=frame(i),cx=(i%COLS)*FW,cy=Math.floor(i/COLS)*FH;for(let y=0;y<FH;y++)sheet.set(f.subarray(y*FW*4,(y+1)*FW*4),((cy+y)*COLS*FW+cx)*4)}
const SW=COLS*FW,SH=ROWS*FH;
writeFileSync(join(HERE,'tiger-wave.png'),encodePNG(SW,SH,sheet));
const K=3,big=new Uint8Array(SW*K*SH*K*4);
for(let y=0;y<SH*K;y++)for(let x=0;x<SW*K;x++){const s=((y/K|0)*SW+(x/K|0))*4,o=(y*SW*K+x)*4;const a=sheet[s+3];const b=((x/K/FW|0)+(y/K/FH|0))%2?[34,38,52]:[26,30,44];
 big[o]=a?sheet[s]:b[0];big[o+1]=a?sheet[s+1]:b[1];big[o+2]=a?sheet[s+2]:b[2];big[o+3]=255}
writeFileSync(join(HERE,'tiger-wave-x3.png'),encodePNG(SW*K,SH*K,big));
writeFileSync(join(HERE,'tiger-wave.json'),JSON.stringify({frames:Array.from({length:N},(_,i)=>({filename:`tiger-wave ${i}`,frame:{x:(i%COLS)*FW,y:Math.floor(i/COLS)*FH,w:FW,h:FH},rotated:false,trimmed:false,spriteSourceSize:{x:0,y:0,w:FW,h:FH},sourceSize:{w:FW,h:FH},duration:Math.round(1000/FPS)})),
 meta:{app:'geuseundae tiger wave generator',version:'1',image:'tiger-wave.png',format:'RGBA8888',size:{w:SW,h:SH},scale:'1',frameTags:[{name:'fly',from:0,to:N-1,direction:'forward'}],
 pixelfx:{id:'geuseundae/tiger-wave',name:'범의 송곳니 · 푸른 호랑이 기공파',fps:FPS,loop:true,frames:N,frameSize:[FW,FH],pivot:[CX,CY],columns:COLS}}},null,1));
console.log('ok',SW,SH);
