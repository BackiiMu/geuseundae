import {fit,clamp,ease,sparkle,READY} from '../../core/index.js';
export const meta={name:'Come to me / 이리 오너라',desc:'Five hair bundles seek, wrap and drag visible enemies into a knot in front of the child.',tags:['hair','heart','gather','ghost','crowd-control'],size:[480,260],origin:[170,210],duration:3.6,fps:30,loop:false,bg:'ground',options:{palette:['#10121b','#202331','#363a4b','#535b6e','#7c8998','#afc6c0','#e0e5d3'],seed:9}};
export const targets=[{x:-115,y:0,kind:'dosa'},{x:-60,y:-65,kind:'mudang'},{x:100,y:0,kind:'dosa'},{x:190,y:-85,kind:'mudang'},{x:245,y:0,kind:'dosa'}];
export const times={reach:.3,bind:1,pull:1.38,land:2.22,release:2.65,end:3.5};
export function position(t,i){const a=targets[i],v=clamp((t-times.pull)/(times.land-times.pull)),q=v*v*(3-2*v),tx=62+(i-2)*7,ty=(i%2)*3;return{x:a.x+(tx-a.x)*q,y:a.y+(ty-a.y)*q-Math.sin(v*Math.PI)*20};}
export const act={targets:targets.map(a=>({x:a.x,y:a.y})),poses:[[-.3,{...READY,crouch:4,lean:-5}],[.3,{...READY,crouch:3,lean:3},'snap'],[1.35,{...READY,crouch:7,lean:-6},'snap'],[2.22,{...READY,crouch:5,lean:-3}],[3.6,READY]],hits:[{t:2.22,stop:.12,shake:.12,amp:1,target:false}]};
function bundle(p,t,o,front){if(t<times.reach||t>=times.end)return;const C=fit(o.palette,7),fade=1-clamp((t-times.release)/.85);
for(let i=0;i<targets.length;i++){const a=targets[i],b=position(t,i),reach=clamp((t-times.reach-i*.026)/.46),ex=b.x,ey=b.y-23,sy=-34,sx=-2,taut=clamp((t-times.pull)/.18);
if(!front){for(let j=0;j<9;j++){let prev=null;for(let k=0;k<=56;k++){const u=k/56*ease.outCubic(reach),slack=(1-taut)*(Math.sin(u*Math.PI)*(-24-i*4)+Math.sin(u*9+t*5+i)*7),off=(j-4)*1.1*Math.sin(u*Math.PI);let x=sx+(ex-sx)*u,y=sy+(ey-sy)*u+slack+off;if(prev){p.beam(prev[0],prev[1],x,y,j===4?2.6:1,C[j===1?4:j===5?3:j%3],fade);};prev=[x,y];}}}
if(front&&t>times.pull&&t<times.land){for(let z=0;z<3;z++){const xx=b.x+(a.x-b.x)*.08+z*(a.x>62?4:-4);p.line(xx,b.y-5+z*4,xx+(a.x>62?6:-6),b.y-5+z*4,C[3],.45);}}
if(reach>.92){const bind=clamp((t-(.76+i*.026))/.24),wrap=bind*Math.PI*5;for(let ring=0;ring<3;ring++){let prev=null;for(let k=0;k<=40;k++){const a=k/40*wrap,x=ex+Math.cos(a)*11,y=ey-7+ring*6+Math.sin(a)*3;if((Math.sin(a)>0)===front&&prev)p.line(prev[0],prev[1],x,y,C[ring===1?4:2],fade);prev=[x,y];}}if(t<1.3&&front){p.glow(ex,ey,17,C[4],.16*bind);}}
}
if(front&&t>times.land&&t<times.land+.25){const q=(t-times.land)/.25;sparkle(p,62,-17,10*(1-q),C[6],C[4],.18);p.ellipse(62,3,27*q,2,C[4],1-q);}}
export function drawBack(p,t,o){bundle(p,t,o,false);}
export function draw(p,t,o){bundle(p,t,o,true);if(t>.04&&t<.3){const C=fit(o.palette,7);p.glow(0,-22,12,C[4],Math.sin((t-.04)/.26*Math.PI)*.3);}}
