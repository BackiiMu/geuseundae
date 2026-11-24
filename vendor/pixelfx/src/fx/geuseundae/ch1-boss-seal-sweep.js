import { fit, clamp, smooth, ease, READY } from "../../core/index.js";

// Game hit: world centre (52,-37.5), radius 70. At 1.5x VFX scale this is
// local centre (35,-25), radius 47, so the blade path stays on that footprint.
export const meta={name:"Captain sealing sweep",desc:"One heavy sword edge sweeps through the captain's real forward circular hit area, with torn seal strips following the blade path.",tags:["boss","melee","sweep","seal","chapter1"],size:[150,140],origin:[42,108],duration:1.05,loop:false,fps:30,bg:"ground",actor:3,options:{palette:["#09090d","#21141a","#472128","#752d31","#a43f39","#c66b48","#ddb17a"],seed:31}};
const HOLD={...READY,weapon:"greatsword",two:true,fx:11,fy:-21,sa:-1};
export const act={target:{x:52},poses:[[-.5,{...HOLD,x:-5,lean:-5,fx:-8,fy:-28,sa:2.7}],[-.05,{...HOLD,x:-6,lean:-7,fx:-10,fy:-30,sa:2.8}],[.02,{...HOLD,x:5,lean:8,fx:23,fy:-20,sa:.08},"snap"],[.42,{...HOLD,x:6,lean:6,fx:21,fy:-18,sa:.2}],[1,HOLD]],hits:[{t:.07,stop:.14,shake:.22,amp:3,push:3}]};
export function draw(p,t,o){
 if(t>=meta.duration)return;
 const C=fit(o.palette,7),release=clamp((t-.50)/.14),decay=1-smooth(.66,1.02,t);
 if(release<=0)return;
 const cx=35,cy=-25,lead=-2.45+ease.outQuart(release)*3.9,tail=lead-(.34+release*.72),a=decay*(.9-.22*release);
 p.arc(cx,cy,47,9,tail,lead,C[0],a);
 p.arc(cx,cy,46,3,tail+.03,lead,C[3],a*.92);
 p.arc(cx,cy,49,1,tail+.07,lead-.03,C[6],a);
 p.arc(cx,cy,39,1,tail+.18,lead-.12,C[4],a*.76);
 const tx=cx+Math.cos(lead)*47,ty=cy+Math.sin(lead)*47;
 p.poly([[tx-2,ty-4],[tx+4,ty],[tx-1,ty+4],[tx-7,ty+1]],C[5],a);
 for(let i=0;i<9;i++){
  const d=.54+i*.018,u=clamp((t-d)/.42);if(u<=0||u>=1)continue;
  const ang=-2.1+i*.31+u*.58,r=33+i%3*6,x=cx+Math.cos(ang)*r,y=cy+Math.sin(ang)*r;
  p.rect(x,y,2+(i%2),4,C[i%3===0?5:2],(1-u)*decay*.72);
 }
}
