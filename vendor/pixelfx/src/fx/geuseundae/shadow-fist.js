// Smoke volume recipe uses pixelfx shadow/_lib.js, adapted from Sprite Fusion shadow effects.
// MIT License, Copyright (c) 2026 Hugo Duprez. Original fist silhouette and choreography.
import {Particles,P,Rng,fit,clamp,ease,noise,TAU,READY} from '../../core/index.js';
import {Puffs,PK} from '../shadow/_lib.js';
export const meta={name:'Duo shadow fist',desc:'A near-black knuckled fist tears out of ink smoke, slams forward, then unravels into curling shadow ribbons.',size:[288,176],origin:[116,132],duration:.72,fps:25,loop:false,bg:'ground',actor:2,tags:['shadow','fist','legendary'],options:{seed:1103,palette:['#080910','#11131e','#222637','#3f465d','#7b84a3','#bdc8de']}};
export const act={poses:[[-.3,{...READY,lean:-4,crouch:4,fx:-5,fy:-27}],[0,{...READY,lean:5,crouch:2,fx:18,fy:-24},'snap'],[.45,READY]],hits:[{t:.04,stop:.08,shake:.12,amp:2,push:2}]};
const BODY=[[-45,-8],[-25,-17],[-19,-28],[-9,-34],[3,-35],[8,-39],[20,-39],[24,-37],[34,-37],[45,-31],[50,-23],[52,-10],[47,1],[45,15],[32,23],[17,24],[5,20],[-16,22],[-30,15],[-47,13]];
function inside(x,y,points){let c=false;for(let i=0,j=points.length-1;i<points.length;j=i++)if((points[i][1]>y)!=(points[j][1]>y)&&x<(points[j][0]-points[i][0])*(y-points[i][1])/(points[j][1]-points[i][1])+points[i][0])c=!c;return c;}
export function create(o){
 const C=fit(o.palette,8),R=new Rng(o.seed),ps=new Particles({rng:R,ground:()=>2,sparks:[C[6],C[5],C[3],C[2]]});
 const smoke=new Puffs({rng:R,flame:[C[6],C[5],C[4],C[3],C[2],C[1],C[0]],soot:[C[1],C[2]],cap:C[3],rim:["#817898","#5e5878",C[3]],floor:()=>3});
 for(let i=0;i<24;i++)smoke.spawn(PK.SOOT,R.range(-24,24),R.range(-47,-16),R.range(-75,-24),R.range(-35,8),R.range(.3,.58),R.range(5,11),R.range(0,.14));
 for(let i=0;i<18;i++){const a=R.range(-1.2,1.1);ps.spawn(P.SPARK,78,-34,Math.cos(a)*R.range(50,150),Math.sin(a)*R.range(40,120)-15,R.range(.12,.4),R.pick([C[5],C[4],C[3]]),1,.025);}
 const chunks=Array.from({length:17},()=>({x:R.range(0,64),y:R.range(-57,-12),vx:R.range(-150,-45),vy:R.range(-50,30),r:R.range(2,6),d:R.range(.16,.29)}));
 for(let i=0;i<12;i++)smoke.spawn(PK.FLAME,R.range(-35,4),R.range(-51,-22),R.range(-70,-30),R.range(-25,3),R.range(.25,.4),R.range(2,4),R.range(.01,.1),false);
 let t=0;
 return {update(dt){t+=dt;ps.update(dt);smoke.update(dt);},draw(p){
  if(t<=0||t>=.72)return;
  smoke.draw(p);
  p.disc(-12,-38,21,"#343047",.2*Math.max(0,1-t/.48));
  const fade=clamp(1-(t-.25)/.28),rush=ease.outQuart(clamp(t/.07)),x=-10+rush*40-ease.outQuad(clamp((t-.17)/.22))*9,y=-36;
  // Wrist is smoke, not a rectangular gauntlet. Broad ribbons tighten into a solid fist.
  for(let j=0;j<5;j++){
   const pts=[];for(let i=0;i<=18;i++){const u=i/18;pts.push([x-70+u*64,y+(j-2)*5+Math.sin(u*7-t*18+j)*(1-u)*9]);}
   p.polyline(pts,C[j%2?2:1],fade*.8);
   if(j<2)p.polyline(pts.map(([xx,yy])=>[xx,yy-1]),C[4],fade*.45);
  }
  if(fade>0){
   p.shade(x-50,y-43,x+56,y+28,(px,py)=>{
    const xx=px-x,yy=py-y;if(!inside(xx,yy,BODY))return;
    // Coherent 5px shadow chunks peel away; never checkerboard the hand itself.
    if(t>.25&&xx < -50+(1-fade)*110+Math.sin(yy*.21+t*13)*5)return;
    if(xx<-20&&noise(Math.floor(xx/4),Math.floor(yy/5))>(xx+50)/38)return;
    return yy<-25?C[2]:xx>34?C[2]:yy>12?C[1]:C[0];
   });
   if(t<.29){
    // Asymmetric knuckle planes and curled fingers, lit only along the upper ridges.
    const fingers=[[-14,-28,-6,-35,3,-34,7,-23], [3,-34,9,-39,19,-38,23,-24], [20,-34,25,-37,34,-35,38,-22],[35,-29,41,-31,47,-26,48,-14]];
    for(const q of fingers){p.poly([[x+q[0],y+q[1]],[x+q[2],y+q[3]],[x+q[4],y+q[5]],[x+q[6],y+q[7]]],C[3]);p.line(x+q[2],y+q[3],x+q[4],y+q[5],C[5]);}
    p.poly([[x-12,y-5],[x+10,y-10],[x+37,y+1],[x+30,y+14],[x+15,y+18],[x-4,y+10]],C[2]);
    p.polyline([[x-10,y-5],[x+10,y-9],[x+34,y+2]],C[4]);
    p.line(x+5,y+11,x+27,y+14,C[0]);p.line(x+32,y-17,x+45,y-11,C[0]);
    p.polyline([[x+46,y-24],[x+50,y-13],[x+46,y-2],[x+44,y+12],[x+31,y+21]],C[3]);
    p.px(x+13,y-39,C[6]);p.px(x+28,y-36,C[6]);
   }
  }
  // One compressed air blade ahead of the hit, not a decorative magic circle.
  if(t<.18){const k=1-t/.18;p.arc(x+35,y-8,26+20*(1-k),2,-.9,.9,C[5],k*.7);p.glow(x+45,y-18,22,C[4],k*.12);}
  for(const q of chunks){const u=t-q.d;if(u<0||u>.32)continue;const xx=q.x+q.vx*u,yy=q.y+q.vy*u;const r=q.r*(1-u/.32);p.poly([[xx-r,yy],[xx,yy-r*.7],[xx+r,yy+r*.4],[xx-r*.6,yy+r]],C[1]);p.line(xx-r,yy,xx,yy-r*.7,C[3]);}
  ps.draw(p);
 }};
}
