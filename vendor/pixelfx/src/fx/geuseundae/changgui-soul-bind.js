import { fit, clamp, smooth, seg, rand, TAU } from "../../core/index.js";

export const meta = {
  name: "Changgui soul bind",
  desc: "A blue revenant dives onto a victim, locks around the chest in three spectral cords and burns there for four seconds.",
  tags: ["geuseundae", "soul", "ghost", "bind", "status", "blue"],
  size: [72, 96], origin: [36, 82], duration: 4, loop: false, fps: 24, bg: "dark",
  options: { palette: ["#050b18", "#0a1d38", "#123b67", "#17699b", "#27a9d1", "#73dbef", "#c9f7ff", "#ffffff"], seed: 17 },
};

const IN=.32, LOCK=.58, FADE=3.55;
export function draw(p,t,o){
  if(t>=meta.duration) return;
  const C=fit(o.palette,8), appear=smooth(0,.12,t), out=1-smooth(FADE,4,t), hold=appear*out;
  const dive=clamp(seg(t,0,LOCK)), y=-28-(1-dive)*(1-dive)*38;
  const pulse=.82+.18*Math.sin(t*TAU*2.1);
  const close=smooth(IN,LOCK,t);
  for(let j=0;j<3;j++){
    const yy=-35+j*10+Math.sin(t*4+j)*1.2, phase=t*5+j*2.1, rx=(16-j*2)*(1-.42*close)+Math.sin(phase)*.8;
    p.arc(Math.sin(phase*.7)*1.2,yy,rx,1.2,Math.PI*.08+Math.sin(phase)*.12,Math.PI*1.92,C[j===1?6:4],hold*(.55+.18*j));
    p.glowRing(0,yy,rx,C[4],.09*hold);
  }
  for(const side of [-1,1]){
    const sway=Math.sin(t*7+side)*2;
    p.polyline([[side*13,-40],[side*(18+sway),-31],[side*13,-20],[side*9,-7]],C[5],hold*.8);
    p.px(side*9,-7,C[7]); p.glow(side*10,-18,12,C[4],.18*hold);
  }
  const sx=Math.sin(t*5.2)*1.5, sy=y+Math.sin(t*6)*1.2;
  p.disc(sx,sy,10,C[3],.22*hold);
  p.poly([[sx-6,sy-4],[sx-3,sy-8],[sx+3,sy-8],[sx+6,sy-4],[sx+5,sy+3],[sx+2,sy+7],[sx,sy+5],[sx-2,sy+7],[sx-5,sy+3]],C[5],hold);
  p.poly([[sx-3,sy-3],[sx,sy-5],[sx+3,sy-3],[sx+2,sy+3],[sx,sy+1],[sx-2,sy+3]],C[1],hold);
  p.px(sx-2,sy-2,C[7]); p.px(sx+2,sy-2,C[7]); p.px(sx,sy+2,C[6]);
  for(let k=0;k<3;k++){
    const yy=sy+7+k*5, w=4.8-k*1.1, lean=Math.sin(t*6+k*1.7)*2.2;
    p.arc(sx+lean,yy,w,1.4,0,Math.PI,C[4+k],hold*(.72-k*.12));
  }
  for(let i=0;i<10;i++){
    const a=t*(1.4+(i%3)*.2)+i*TAU/10, r=18+5*rand(i,o.seed), my=-29+Math.sin(a*1.7)*23;
    const mx=Math.cos(a)*r, ma=hold*(.35+.65*Math.sin(a*2+i)*.5+.5);
    p.px(mx,my,C[5+(i%2)],ma); if(i%3===0) p.glow(mx,my,5,C[4],.12*ma);
  }
  if(t>IN&&t<.7){ const flash=1-seg(t,IN,.7); p.glow(0,-29,42,C[5],.38*flash); p.ring(0,-29,10+28*(1-flash),C[6],flash); }
  const pin=smooth(.38,.62,t)*out;
  p.ellipse(0,0,13+Math.sin(t*5),3,C[3],pin*.72);
  p.line(0,-1,0,-8,C[6],pin); p.px(-1,-8,C[7]); p.px(1,-8,C[7]);
  p.glow(0,-1,20,C[4],.12*pin);
  p.glow(0,-28,32*pulse,C[4],.18*hold);
}
