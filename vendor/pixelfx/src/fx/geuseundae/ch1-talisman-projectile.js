import { fit } from "../../core/index.js";

export const meta={name:"Chapter 1 plain paper projectile",desc:"A rigid blank rectangle of old paper flying straight without flutter, symbols, seals, glow or particles.",tags:["paper","projectile","chapter1","loop"],size:[26,30],origin:[13,15],duration:1,loop:true,fps:1,bg:"dark",options:{palette:["#171318","#4a403b","#786754","#a38b68","#c4aa7b","#dcc99e","#eee1bd"],seed:17}};

export function draw(p,t,o){
  const C=fit(o.palette,7);
  p.rect(-7,-10,14,20,C[0]);
  p.rect(-6,-9,12,18,C[5]);
}
