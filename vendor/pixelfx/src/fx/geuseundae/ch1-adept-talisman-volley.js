import { fit, clamp, smooth, ease, READY } from "../../core/index.js";

export const meta={name:"Vermilion talisman shot",desc:"A folded rice-paper charm snaps open, then advances slowly across a longer straight lane with ink-stroke afterimages.",tags:["paper","talisman","projectile","chapter1","directional"],size:[296,140],origin:[50,110],duration:1.95,loop:false,fps:30,bg:"ground",actor:2,options:{palette:["#1c1418","#4b2529","#87332f","#bd4b39","#d99b62","#e7d29e","#fff1c9"],seed:17}};
export const act={target:{x:152},poses:[[-.55,{...READY,turn:1,fx:-8,fy:-30,bx:8,by:-27,crouch:2}],[-.12,{...READY,turn:1,fx:5,fy:-33,bx:11,by:-25,lean:-3}],[0,{...READY,fx:19,fy:-25,bx:3,by:-24,lean:5},"snap"],[.42,{...READY,fx:14,fy:-23,lean:2}],[.9,READY]],hits:[{t:.46,stop:.07,shake:.1,amp:1,push:1.5,skin:"holy"}]};

function paper(p,x,y,C,a=1,fold=0){
  const left=x-7+fold,right=x+7-fold;
  // Dark cut-paper silhouette, aged inner paper, folded gold corner.
  p.poly([[left,y-12],[right-2,y-12],[right,y-9],[right-1,y+11],[x+2,y+10],[x,y+12],[x-2,y+10],[left+1,y+11]],C[0],a);
  p.poly([[left+2,y-10],[right-3,y-10],[right-2,y-8],[right-3,y+8],[x+2,y+8],[x,y+10],[x-2,y+8],[left+3,y+9]],C[5],a);
  p.poly([[right-5,y-10],[right-2,y-8],[right-5,y-6]],C[6],a*.8);
  // Bespoke vermilion header and forked spirit-binding glyph.
  p.rect(x-4,y-8,8,2,C[2],a); p.px(x-5,y-7,C[3],a); p.px(x+4,y-7,C[3],a);
  p.line(x,y-5,x,y+2,C[2],a); p.line(x,y-3,x-3,y-1,C[3],a); p.line(x,y-1,x+3,y+1,C[3],a);
  p.line(x,y+1,x-2,y+4,C[2],a); p.line(x,y+1,x+2,y+4,C[2],a);
  // Square stamp makes it read as an authored talisman even at game scale.
  p.rect(x-3,y+4,6,5,C[2],a);p.rect(x-1,y+5,2,3,C[5],a*.85);p.px(x+2,y+7,C[4],a);
  p.line(left+2,y-4,left+4,y-4,C[1],a*.7);p.line(right-4,y+2,right-2,y+2,C[1],a*.7);
}
export function draw(p,t,o){
  if(t>=meta.duration)return; const C=fit(o.palette,7), launch=.18, hit=1.35;
  if(t<launch){const u=t/launch,x=12+u*10,y=-26-u*2;paper(p,x,y,C,.45+.55*u,Math.round((1-u)*4));p.glow(x,y,13,C[4],.16*u);}
  if(t>=launch&&t<hit){
    const u=(t-launch)/(hit-launch),x=22+u*190,y=-28;
    for(let k=4;k>0;k--){const ku=clamp(u-k*.035),kx=22+ku*190,ky=-28;paper(p,kx,ky,C,(5-k)*.07,0);}
    paper(p,x,y,C,1,0); p.glow(x,y,16,C[4],.22);
    for(let j=1;j<7;j++)p.line(x-j*7,y+2+(j%2),x-j*7-3,y+2,C[j<3?4:3],(1-j/7)*.65);
  }
  if(t>=hit){const u=(t-hit)/(meta.duration-hit),fade=1-smooth(.45,1,u),cx=212,cy=-27;
    if(u<.17){const z=1-u/.17;p.line(cx-10,cy-7,cx+9,cy+6,C[5],z);p.line(cx-7,cy+9,cx+8,cy-8,C[3],z*.9);}
    const rr=7+ease.outExpo(clamp(u/.38))*19;
    // Broken, angular seal strokes: deliberately not a complete magic circle.
    for(let k=0;k<4;k++){
      const a=k*Math.PI/2+.2, x1=cx+Math.cos(a)*rr, y1=cy+Math.sin(a)*rr;
      const b=a+.46, x2=cx+Math.cos(b)*rr, y2=cy+Math.sin(b)*rr;
      p.line(x1,y1,x2,y2,k%2?C[3]:C[4],fade*.72);
      p.line(x2,y2,x2-Math.cos(a)*5,y2-Math.sin(a)*5,C[5],fade*.5);
    }
    for(let i=0;i<13;i++){const a=i*2.399,rr2=7+u*(25+i%4*4),x=cx+Math.cos(a)*rr2,y=cy+Math.sin(a)*rr2+u*u*18; if(i%3===0)p.rect(x,y,2,3,C[4],fade);else p.line(x,y,x-Math.cos(a)*4,y-Math.sin(a)*4,C[2+i%3],fade*.8);}
    p.glow(cx,cy,22,C[3],.18*fade);
  }
}
