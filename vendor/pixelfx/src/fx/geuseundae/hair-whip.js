import {fit,clamp,ease,sparkle,READY} from '../../core/index.js';
export const meta={name:'Borrowed hair / 그슨대',desc:'Black hair coils behind the child, snaps into a hooked whip and unravels into cold strands.',tags:['hair','ghost','combat'],size:[200,128],origin:[58,106],duration:1.25,fps:30,loop:false,bg:'ground',options:{palette:['#11131f','#24283b','#4a5266','#687f8c','#7da8ab','#a8d7c5','#e4eee0','#fff8dc'],seed:7}};
const HIT=.19;
export const act={target:{x:75},poses:[[-.3,{...READY,lean:-4,crouch:4}],[-.08,{...READY,lean:-7,crouch:6}],[.08,{...READY,lean:7,crouch:3},'snap'],[.5,{...READY,lean:3}],[1.25,READY]],hits:[{t:HIT,stop:.1,shake:.16,amp:2,push:3,skin:'shadow'}]};
export function draw(p,t,o){if(t>=1.2||t<.025)return;const C=fit(o.palette,8),release=ease.outExpo(clamp(t/.2)),fade=1-clamp((t-.36)/.82);
 for(let j=0;j<11;j++){let prev=null;for(let k=0;k<=50;k++){let u=k/50,x=-9+u*91*release,y=-26-Math.sin(u*4.5-Math.min(t,.3)*6)*24*u+(j-5)*1.2*(1-u)+Math.sin(u*10+t*5+j)*u*3+Math.max(0,t-.35)*u*14;
 if(prev)p.line(prev[0],prev[1],x,y,C[j%4],fade);if(j===1&&prev)p.line(prev[0],prev[1]-1,x,y-1,C[5],fade*.8);prev=[x,y];}
 }
 if(t>.15&&t<.55){for(let i=0;i<10;i++){const a=i*2.399,q=(t-.15)/.4,x=74+Math.cos(a)*q*25,y=-23+Math.sin(a)*q*20+q*q*9;p.line(x,y,x-Math.cos(a)*3,y-Math.sin(a)*3,C[5],1-q);}}
 if(t>.12&&t<.4){let q=(t-.12)/.28;sparkle(p,74,-23,10*(1-q),C[7],C[5],.3);p.glow(73,-23,24,C[4],.35*(1-q));}
}
