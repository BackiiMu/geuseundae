import { fit } from "../../core/index.js";

export const meta={name:"Chapter 1 talisman projectile",desc:"The authored vermilion charm used by the chapter-one adept; it stays upright while the game moves it along a straight trajectory.",tags:["paper","talisman","projectile","chapter1","loop"],size:[34,42],origin:[17,21],duration:.4,loop:true,fps:15,bg:"dark",options:{palette:["#1c1418","#4b2529","#87332f","#bd4b39","#d99b62","#e7d29e","#fff1c9"],seed:17}};

export function draw(p,t,o){
  const C=fit(o.palette,7),x=0,y=0,flutter=Math.sin(t*Math.PI*5);
  const left=x-7+(flutter>.45?1:0),right=x+7-(flutter<-.45?1:0);
  p.poly([[left,y-12],[right-2,y-12],[right,y-9],[right-1,y+11],[x+2,y+10],[x,y+12],[x-2,y+10],[left+1,y+11]],C[0]);
  p.poly([[left+2,y-10],[right-3,y-10],[right-2,y-8],[right-3,y+8],[x+2,y+8],[x,y+10],[x-2,y+8],[left+3,y+9]],C[5]);
  p.poly([[right-5,y-10],[right-2,y-8],[right-5,y-6]],C[6],.8);
  p.rect(x-4,y-8,8,2,C[2]);p.px(x-5,y-7,C[3]);p.px(x+4,y-7,C[3]);
  p.line(x,y-5,x,y+2,C[2]);p.line(x,y-3,x-3,y-1,C[3]);p.line(x,y-1,x+3,y+1,C[3]);
  p.line(x,y+1,x-2,y+4,C[2]);p.line(x,y+1,x+2,y+4,C[2]);
  p.rect(x-3,y+4,6,5,C[2]);p.rect(x-1,y+5,2,3,C[5],.85);p.px(x+2,y+7,C[4]);
  // A restrained ink wake; no sparkle and no area-looking flare.
  p.line(left-2,y-2,left-5-Math.max(0,flutter*2),y-2,C[3],.55);
  p.px(left-3,y+3,C[2],.45);
}
