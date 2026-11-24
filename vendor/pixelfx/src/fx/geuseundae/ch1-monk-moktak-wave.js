import { fit, clamp, smooth, ease, sparkle, READY } from "../../core/index.js";

export const meta={name:"Moktak binding wave",desc:"A wooden moktak strike flashes once, then layered ochre sound crests and a black-ink undertow scrape forward along the floor.",tags:["sound","wood","shockwave","monk","chapter1","directional"],size:[244,144],origin:[80,120],duration:1.3,loop:false,fps:30,bg:"ground",actor:2,options:{palette:["#120f13","#292027","#4a3732","#73533d","#9d774b","#c39b5b","#e1c986"],seed:23}};
const HOLD={...READY,weapon:"handle",two:true,fx:8,fy:-23,bx:-4,by:-23,sa:-.2};
export const act={target:{x:68},poses:[[-.65,{...HOLD,crouch:2,lean:-2,fx:6,fy:-31,bx:-8,by:-29,sa:-1.3}],[-.12,{...HOLD,crouch:4,lean:-4,fx:2,fy:-34,bx:-10,by:-28,sa:-1.8}],[0,{...HOLD,crouch:6,lean:5,fx:18,fy:-19,bx:-4,by:-20,sa:.45},"snap"],[.35,{...HOLD,crouch:5,lean:3}],[.95,HOLD]],hits:[{t:.18,stop:.13,shake:.18,amp:2,push:2.2,straw:14}],dust:[{t:.18,x:18,n:7,dir:1}]};

export function draw(p,t,o){
  if(t>=meta.duration)return;const C=fit(o.palette,7),strike=.12;
  if(t<.2){const u=t/.2,x=16,y=-25;p.ellipse(x,y,11,8,C[2]);p.arc(x,y,9,2,-2.8,.2,C[5]);p.line(x-3,y-8,x+8,y-18,C[3],1);p.line(x+7,y-18,x+12,y-19,C[5],1);if(t>strike)sparkle(p,x+8,y-12,8*(1-(t-strike)/.08),C[6],C[4],.3);}
  if(t>=strike){const u=(t-strike)/(meta.duration-strike),front=14+ease.outCubic(clamp(u/.55))*92,fade=1-smooth(.5,1,u);
    // Three unequal sound fronts keep it organic and directional, not a magic circle.
    for(let k=0;k<3;k++){const delay=k*.1,q=clamp((u-delay)/(.68-delay));if(q<=0||q>=1)continue;const x=14+ease.outCubic(q)*92,h=(29-k*4)*(1-q*.3);p.arc(x,1,h,3,-2.5,-.64,k===0?C[6]:C[5-k],(1-q)*.9);p.arc(x-3,1,h-5,1,-2.4,-.72,C[2],(1-q)*.7);p.glow(x,-8,15+h*.35,C[4],.13*(1-q));}
    // Low ink wave clings to the floor underneath the bright sound.
    p.line(12,-1,front,-1,C[0],fade*.9);p.line(20,-3,front-8,-3,C[2],fade*.65);p.px(front,-1,C[5],fade*.8);
    if(u<.28){const z=1-u/.28;p.line(18,-2,26,-28,C[5],z*.7);p.line(22,-2,31,-21,C[3],z*.75);}
    for(let i=0;i<12;i++){const d=.08+i*.026,q=clamp((u-d)/.72);if(q<=0||q>=1)continue;const x=16+q*(64+i*3),y=-2-Math.sin(i*1.7)*q*13+q*q*12;p.line(x,y,x-2-i%3,y+3,C[i%4===0?5:3],(1-q)*.8);}
  }
}
