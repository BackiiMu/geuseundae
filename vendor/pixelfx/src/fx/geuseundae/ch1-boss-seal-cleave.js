import { fit, clamp, smooth, ease, READY } from "../../core/index.js";

// Game hit: world centre (54,-23.5), radius 105. At 1.5x VFX scale this is
// local centre (36,-16), radius 70. Fall and burst stay inside that footprint.
export const meta={name:"Captain execution cleave",desc:"A black execution blade drops on the actual hit centre and the ground breaks radially inside the real impact footprint.",tags:["boss","melee","cleave","impact","chapter1"],size:[190,206],origin:[54,154],duration:1.5,loop:false,fps:30,bg:"ground",actor:3,options:{palette:["#09090d","#23151b","#4b2228","#792d31","#a43e38","#c66a47","#ddb17a"],seed:37}};
const HOLD={...READY,weapon:"greatsword",two:true,fx:11,fy:-21,sa:-1};
export const act={target:{x:52},poses:[[-.85,{...HOLD,crouch:1,x:2,lean:-5,fx:1,fy:-41,sa:-2.45}],[-.08,{...HOLD,crouch:1,x:1,lean:-7,fx:0,fy:-43,sa:-2.5}],[.02,{...HOLD,crouch:8,x:2,lean:8,fx:18,fy:-18,sa:.75},"snap"],[.5,{...HOLD,crouch:8,x:2,lean:6,fx:18,fy:-18,sa:.75}],[1.3,HOLD]],hits:[{t:.08,stop:.18,shake:.36,amp:4,push:3.4}]};
export function draw(p,t,o){
 if(t>=meta.duration)return;
 const C=fit(o.palette,7),cx=36,cy=-16,drop=clamp((t-.78)/.14),fade=1-smooth(1.0,1.46,t);
 if(drop<=0)return;
 const tipY=-116+ease.inQuart(drop)*105;
 if(t<1.08){
  p.poly([[cx-9,-122],[cx+4,-122],[cx+8,tipY-13],[cx+2,tipY],[cx-7,tipY],[cx-12,tipY-13]],C[0],fade);
  p.line(cx-5,-120,cx-1,tipY-3,C[3],fade);
  p.line(cx+1,-120,cx+5,tipY-7,C[6],fade*.9);
 }
 const impact=clamp((t-.91)/.18);if(impact<=0)return;
 const ring=ease.outExpo(impact)*68,ringFade=(1-smooth(.18,.92,impact))*fade;
 for(let k=0;k<4;k++){
  const a0=-2.95+k*1.47,a1=a0+.82;
  p.arc(cx,cy,ring,3,a0,a1,k===0?C[6]:C[3],ringFade*(.92-k*.08));
 }
 for(let i=0;i<18;i++){
  const d=.91+i*.009,u=clamp((t-d)/.52);if(u<=0||u>=1)continue;
  const ang=-2.85+i*.34,r=(12+i%4*5)+ease.outQuart(u)*(28+i%5*4),x=cx+Math.cos(ang)*r,y=cy+Math.sin(ang)*r*.55;
  p.rect(x,y,2+i%2,2+i%3,C[i%5===0?5:1],(1-u)*fade*.78);
 }
}
