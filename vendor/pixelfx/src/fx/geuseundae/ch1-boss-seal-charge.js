import { fit, clamp, smooth, ease, READY } from "../../core/index.js";

// During the 0.28 s charge the game checks a world r42 circle at (34,-22).
// At 1.5x this is local (23,-15), r28: the hot wedge occupies that space.
export const meta={name:"Captain shadow charge",desc:"A forward shoulder wedge marks the moving hit volume while chained human shadows stretch behind the charging captain.",tags:["boss","charge","afterimage","seal","chapter1"],size:[196,126],origin:[122,108],duration:1.12,loop:false,fps:30,bg:"ground",actor:3,options:{palette:["#08090c","#1e1419","#462128","#752d31","#a43f39","#c66a48","#ddb17a"],seed:41}};
const HOLD={...READY,crouch:7,lean:8};
export const act={target:{x:112},poses:[[-.35,{...HOLD,x:-4,lean:-6}],[-.04,{...HOLD,x:-5,lean:-7}],[.02,{...HOLD,x:6},"snap"],[.45,{...HOLD,x:8}],[.82,READY]],hits:[{t:.12,stop:.06,shake:.12,amp:2,push:4}]};
export function draw(p,t,o){
 if(t>=meta.duration)return;
 const C=fit(o.palette,7),charge=clamp((t-.72)/.12),fade=1-smooth(.96,1.11,t);
 if(t<.72){
  const gather=ease.inCubic(clamp(t/.72));
  for(let i=0;i<5;i++){
   const x=-18-i*9+gather*(8+i*5),y=-4-(i%2)*5;
   p.rect(x,y,3,3,C[i%2?2:1],(.18+.28*gather)*(1-i*.08));
  }
  return;
 }
 const wedge=ease.outExpo(charge);
 p.poly([[8,-43],[31+wedge*12,-33],[51+wedge*5,-15],[33+wedge*8,6],[8,-1],[-2,-18]],C[0],fade*.9);
 p.line(11,-38,42+wedge*8,-17,C[4],fade*.86);
 p.line(15,-33,48+wedge*6,-15,C[6],fade*.9);
 for(let g=0;g<3;g++){
  const gx=-24-g*27-charge*(8+g*5),gy=-1-g%2*3,a=fade*(.5-g*.11);
  p.disc(gx,gy-48,6,C[g===0?2:1],a);
  p.poly([[gx-6,gy-41],[gx+6,gy-41],[gx+9,gy-17],[gx+16,gy-2],[gx+3,gy],[gx,gy-20],[gx-4,gy],[gx-15,gy-2],[gx-9,gy-18]],C[g===0?2:0],a);
  p.line(gx-7,gy-28,gx-20,gy-10,C[3],a*.7);
  p.line(gx+7,gy-28,gx+20,gy-13,C[1],a*.7);
 }
 for(let i=0;i<11;i++){
  const u=clamp((t-.72-i*.012)/.38);if(u<=0||u>=1)continue;
  const x=-5-u*(34+i%4*9),y=-4-Math.sin(i*1.7)*u*7+u*u*8;
  p.rect(x,y,2+i%2,2,C[i%5===0?5:1],(1-u)*fade*.72);
 }
 p.poly([[-82-charge*18,0],[10,0],[2,-6],[-68-charge*12,-7]],C[0],fade*.72);
}
