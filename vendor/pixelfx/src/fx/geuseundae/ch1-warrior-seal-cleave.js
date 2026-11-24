import { fit, clamp, smooth, ease, READY } from "../../core/index.js";

export const meta={name:"Sealed iron cleave",desc:"A broad iron cut tears a narrow pale edge through a black-vermilion seal trail; paper fibres and ember-red ink flecks peel away.",tags:["melee","slash","seal","chapter1","directional"],size:[184,128],origin:[48,108],duration:.9,loop:false,fps:30,bg:"ground",actor:2,options:{palette:["#110d12","#2c1922","#59242d","#873237","#b34a42","#d89d69","#f3dfb2"],seed:11}};
const GUARD={...READY,weapon:"sword",fx:12,fy:-21,sa:-.8};
export const act={target:{x:66},poses:[[-.48,{...GUARD,x:-6,crouch:3,lean:-4,fx:-5,fy:-34,sa:-2.5,bx:8,by:-24,armsFront:true}],[-.06,{...GUARD,x:-2,crouch:5,lean:-5}], [.02,{...GUARD,x:4,crouch:4,lean:6,fx:22,fy:-18,sa:.55,bx:-8,by:-23,ghost:1},"snap"],[.32,{...GUARD,x:5,crouch:6,lean:4,fx:20,fy:-16,sa:.72}],[.75,GUARD]],hits:[{t:.06,stop:.12,shake:.16,amp:2,push:2.5,straw:16}],dust:[{t:.06,x:14,n:6,dir:1}]};

export function draw(p,t,o){
  if(t>=meta.duration)return; const C=fit(o.palette,7), q=clamp(t/.10), tail=smooth(.11,.52,t), fade=1-smooth(.42,.88,t);
  const cx=31,cy=-27,R=50,a0=-2.17,a1=.28,head=a0+(a1-a0)*ease.outExpo(q),back=a0+(a1-a0)*tail;
  if(t<.55){
    const span=head-back;
    for(let j=0;j<9;j++){
      const r=R-j, k=1-j/10;
      p.arc(cx,cy,r,1,back,head,j===0?C[6]:j<2?C[4]:j<6?C[2]:C[0],fade*k*(j===0?.82:1));
    }
    p.arc(cx,cy,R+2,1,back,head,C[5],fade*.72);
  }
  // Torn sealing-paper corners and ink chips follow the blade instead of generic sparks.
  for(let i=0;i<13;i++){
    const delay=.08+i*.017, u=clamp((t-delay)/.48); if(u<=0||u>=1)continue;
    const a=-1.7+i*.23, x=35+Math.cos(a)*(18+u*(32+i%3*5)), y=-28+Math.sin(a)*(12+u*26)+u*u*20;
    const col=i%4===0?C[5]:i%3===0?C[3]:C[2];
    if(i%3===0)p.rect(x,y,2,3,col,(1-u)*.9); else p.line(x,y,x-3-u*3,y+1,col,(1-u)*.8);
  }
  if(t>.08&&t<.48){const u=(t-.08)/.4;p.line(6+u*68,-3,17+u*68,-3,C[2],(1-u)*.6);p.line(10+u*54,-6,18+u*54,-7,C[1],(1-u)*.45);}
}
