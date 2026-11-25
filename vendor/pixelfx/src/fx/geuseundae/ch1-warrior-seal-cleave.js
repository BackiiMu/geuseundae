import { fit, clamp, smooth, ease, READY } from "../../core/index.js";

export const meta={name:"Sealed iron cleave",desc:"A restrained iron cut drags a dark black-vermilion seal trail with only a narrow dull-red blade edge.",tags:["melee","slash","seal","chapter1","directional"],size:[184,128],origin:[48,108],duration:.9,loop:false,fps:30,bg:"ground",actor:2,options:{palette:["#0d0b0f","#21151b","#3b1b23","#64252b","#8b3333","#ad4a3e","#ca6b4e"],seed:11}};
const GUARD={...READY,weapon:"sword",fx:12,fy:-21,sa:-.8};
export const act={target:{x:66},poses:[[-.48,{...GUARD,x:-6,crouch:3,lean:-4,fx:-5,fy:-34,sa:-2.5,bx:8,by:-24,armsFront:true}],[-.06,{...GUARD,x:-2,crouch:5,lean:-5}], [.02,{...GUARD,x:4,crouch:4,lean:6,fx:22,fy:-18,sa:.55,bx:-8,by:-23,ghost:1},"snap"],[.32,{...GUARD,x:5,crouch:6,lean:4,fx:20,fy:-16,sa:.72}],[.75,GUARD]],hits:[{t:.06,stop:.12,shake:.16,amp:2,push:2.5,straw:16}],dust:[{t:.06,x:14,n:6,dir:1}]};

export function draw(p,t,o){
  if(t>=meta.duration)return; const C=fit(o.palette,7), q=clamp(t/.10), tail=smooth(.11,.52,t), fade=1-smooth(.42,.88,t);
  const cx=31,cy=-27,R=50,a0=-2.17,a1=.28,head=a0+(a1-a0)*ease.outExpo(q),back=a0+(a1-a0)*tail;
  if(t<.55){
    p.arc(cx,cy,R-3,4,back,head,C[1],fade*.82);
    p.arc(cx,cy,R-1,2,back,head,C[2],fade*.66);
    p.arc(cx,cy,R+1,1,back,head,C[4],fade*.52);
  }
  // Torn sealing-paper corners and ink chips follow the blade instead of generic sparks.
  for(let i=0;i<4;i++){
    const delay=.12+i*.045, u=clamp((t-delay)/.38); if(u<=0||u>=1)continue;
    const a=-1.7+i*.23, x=35+Math.cos(a)*(18+u*(32+i%3*5)), y=-28+Math.sin(a)*(12+u*26)+u*u*20;
    const col=i%3===0?C[3]:i%2===0?C[2]:C[1];
    if(i%3===0)p.rect(x,y,2,2,col,(1-u)*.68); else p.line(x,y,x-2-u*2,y+1,col,(1-u)*.62);
  }
  if(t>.1&&t<.4){const u=(t-.1)/.3;p.line(10+u*58,-3,18+u*58,-3,C[1],(1-u)*.4);}
}
