// Crescent layering and stepped ramps informed by pixelfx sword-slash and crit-hit.
// Original game-specific grade silhouettes, timing and motifs.
import { fit, Rng, TAU, READY } from '../../core/index.js';
export const meta = {
  name:'Ghost equipment strike', desc:'Four grades: a spare pale cut grows into layered ghost trails, broken seals and a gilded spectral impact.',
  tags:['ghost','equipment','graded','combat'], size:[256,192], origin:[128,128], duration:.72, fps:25, loop:false, bg:'ground', actor:2,
  options:{tier:2,mode:'slash',seed:1103,palette:['#26363d','#436669','#89ada3','#e4e9ce','#fff9df']}
};
export const act={poses:[[-.22,{...READY,lean:-4,crouch:3}],[0,{...READY,lean:4,fx:19,fy:-24},'snap'],[.5,READY]],hits:[{t:.04,stop:.04,shake:.1,amp:1,push:1}]};
function spark(p,x,y,r,C,a){p.rect(x-r,y,2*r+1,1,C[3],a);p.rect(x,y-r,1,2*r+1,C[4],a);p.px(x,y,C[4]);}
function crescent(p,t,g,C,offset=0){
 const q=Math.min(1,t/.13), fade=Math.max(0,1-(t-.08)/(.19+g*.055));
 if(fade<=0)return;
 const cx=3,cy=-28,r=35+g*7, head=-2.1+q*3.8+offset;
 const span=(1.25+g*.27)*Math.min(1,t/.025);
 for(let i=0;i<3;i++){
  const age=i*.2,rr=r-i*3;
  p.arc(cx,cy,rr,Math.max(1,(2+g*1.5-i)*fade),head-span,head-age,C[Math.max(1,3-i)],i?fade*.6:1);
 }
 const x=cx+Math.cos(head)*r,y=cy+Math.sin(head)*r;
 if(t<.1)p.beam(x-4,y,x+2,y,2,C[4]);
 if(g>1)p.glow(x,y,12+g*3,C[3],.13*fade);
}
export function draw(p,t,o){
 if(t<=0||t>=meta.duration)return;
 const g=Math.max(1,Math.min(4,o.tier)),C=fit(o.palette,5),R=new Rng(o.seed),mode=o.mode;
 const out=Math.max(0,1-t/.72), fast=Math.min(1,t/.055), cool=Math.max(0,1-(t-.08)/.45);
 if(mode==='orb'){
  const pulse=1+Math.sin(t*TAU/.6)*.1,r=(3+g)*pulse;
  p.circle(0,0,r+2,C[0]);p.circle(0,0,r,C[2]);p.circle(-1,-1,Math.max(1,r-2),C[3]);p.rect(-2,-2,2,2,C[4]);
  for(let i=1;i<4+g;i++)p.rect(-i*4,-Math.round(Math.sin(t*14-i)*2),Math.max(1,4-i*.4),2,i<3?C[2]:C[1],1-i/(5+g));
  if(g>1)p.glow(0,0,10+g*3,C[2],.17);
 }else if(mode==='slash'){
  crescent(p,t,g,C);
  if(g>=3)crescent(p,Math.max(0,t-.055),g-1,C,-.22);
 }else if(mode==='fist'){
  const a=t<.22?1:Math.max(0,1-(t-.22)/.18),x=12+Math.min(1,t/.07)*27,y=-28;
  if(a>0){
   p.rect(x-26,y-23,51,41,C[0],a);p.rect(x-23,y-21,45,36,C[1],a);
   for(let i=0;i<4;i++){p.rect(x-22+i*11,y-28,10,20,C[2],a);p.rect(x-21+i*11,y-27,7,4,C[4],a);}
   p.rect(x-32,y-4,13,20,C[2],a);p.rect(x-20,y-7,40,17,C[3],a);
   for(let i=1;i<4;i++)p.line(x-23+i*11,y-25,x-23+i*11,y-12,C[0],a);
   p.line(x-29,y-2,x-21,y+7,C[0],a);p.line(x-18,y+7,x+16,y+7,C[2],a);
   if(t<.18){
    const k=1-t/.18;
    p.arc(x+20,y,18+30*(1-k),2,-1.2,1.2,C[3],k);
    for(let i=0;i<5;i++){const an=-1.1+i*.55; p.beam(x+26+Math.cos(an)*12,y+Math.sin(an)*12,x+26+Math.cos(an)*(18+k*28),y+Math.sin(an)*(18+k*28),1+i%2,C[3]);}
   }
   for(let i=0;i<5;i++)p.beam(x-40-i*8,y-17+i*8,x-14,y-17+i*8,1,C[2],a*.65);
   p.glow(x,y,48,C[2],a*.18);
  }
 }else if(mode==='tiger'){
  const x=-30+t*170,y=-9,a=Math.max(0,1-(t-.25)/.4);
  p.poly([[x-38,y-12],[x-12,y-21],[x+17,y-19],[x+36,y-5],[x+27,y+8],[x-23,y+7]],C[1],a);
  p.tri(x+13,y-18,x+23,y-35,x+28,y-15,C[3],a);
  p.beam(x-22,y+5,x-35,y+24,6,C[2],a);p.beam(x+17,y+5,x+35,y+20,6,C[3],a);
  p.rect(x+23,y-8,5,3,C[4],a);
  for(let i=0;i<4;i++)p.line(x-23+i*10,y-14,x-16+i*10,y+4,C[0],a);
  for(let j=0;j<3;j++)p.arc(x-37,y,18+j*9,2,-1.1,1,C[2],a*.7);
 }else if(mode==='seal'){
  const r=(17+g*8)*(1-Math.pow(1-fast,3)),a=cool*.8;
  p.arc(0,0,r,1,0,TAU,C[2],a);
  if(g>=2)for(let i=0;i<g*2;i++){
   const angle=i*TAU/(g*2)+t*.8;
   p.arc(0,0,r+5,2,angle,angle+.38,C[3],a);
   if(g>=3){const x=Math.cos(angle)*(r+10),y=Math.sin(angle)*(r+10);p.line(x-2,y-3,x+2,y+3,C[3],a);p.line(x+2,y-3,x-2,y+3,C[3],a);}
  }
  p.glow(0,0,r,C[2],a*.14);
 }else{
  const r=(mode==='bloom'?26:13)+g*6;
  for(let i=0;i<(mode==='bloom'?8:4)+g*2;i++){
   const angle=i*TAU/(8+g*2)+R.range(-.12,.12),d=(r+R.range(-7,8))*fast;
   const root=Math.max(0,t-.04)*r*3;
   const x=Math.cos(angle)*d,y=Math.sin(angle)*d*.8;
   if(cool>0)p.poly([[Math.cos(angle)*root,Math.sin(angle)*root*.8],[x-Math.sin(angle)*(1+g),y+Math.cos(angle)*(1+g)],[x*1.2,y*1.2]],i%3?C[2]:C[4],cool);
  }
  if(t<.12)p.circle(0,0,Math.max(1,(6+g*2)*(1-t/.12)),C[4]);
  if(g>1)p.arc(0,0,r*fast,1+(g>2?1:0),0,TAU,C[2],cool*.65);
  if(g>=3)p.glow(0,0,r+10,C[2],cool*.2);
 }
 // Grade changes density and hierarchy, not just scale. Common has no ambient glitter.
 const count=[0,0,7,13,22][g];
 for(let i=0;i<count;i++){
  const a=R.range(-Math.PI,Math.PI),speed=R.range(28,85),delay=R.range(0,.06),u=t-delay,life=R.range(.24,.57);
  if(u<0||u>life)continue;
  const x=Math.cos(a)*(12+speed*u),y=Math.sin(a)*(10+speed*u)+22*u*u;
  const alpha=Math.min(1,(life-u)/.16);
  if(i%4===0&&g>=3)spark(p,x,y,u<.18?2:1,C,alpha);
  else p.line(x-Math.cos(a)*(g+1),y-Math.sin(a)*(g+1),x,y,i%3?C[2]:C[3],alpha);
 }
 if(g===4&&t<.28)for(let i=0;i<6;i++){
  const a=i*TAU/6+.3,r=57+t*35;
  p.arc(0,0,r,1,a,a+.22,C[3],(1-t/.28)*.6);
 }
}
