import {fit,clamp,ease,READY} from '../../core/index.js';
export const meta={name:'Shadow seep',desc:'A cold floor trail breaks into curled shadow and ghost sparks.',tags:['shadow','dash'],size:[248,112],origin:[90,94],duration:1.3,fps:30,loop:false,bg:'ground',options:{palette:['#10121e','#24283b','#3e5365','#62848c','#81b4b2','#b4e0cd','#eff2dc'],seed:7}};
export const act={poses:[[-.25,{...READY,crouch:6,lean:-5}],[0,{...READY,crouch:12,lean:9},'snap'],[.3,{...READY,x:60,crouch:10,lean:8}],[.7,{...READY,x:65}],[1.3,{...READY,x:65}]]};
export function draw(p,t,o){if(t>=1.25||t<.025)return;const C=fit(o.palette,7),q=clamp(t/.35),fade=1-clamp((t-.22)/1.03),head=75*ease.outExpo(q);
for(let j=0;j<12;j++){const x=head-j*7,h=(1-j/13)*20*fade; p.beam(x,-2,x-10,-h,1+(j%3)*(1-j/15),C[j%3],fade);p.line(x-10,-h,x-5,-h-2,C[4],fade*.65);}
p.ellipse(head-35,0,45*fade,3,C[1],fade);p.glow(head-20,-3,38,C[4],.22*fade);p.line(head-70,0,head+2,0,C[5],fade);
for(let i=0;i<16;i++){const a=i*2.4,x=head-i*5,y=-4-Math.sin(a+t*4)**2*(5+t*16);p.dot(x,y,C[4+i%2],fade*(1-i/18));}}
