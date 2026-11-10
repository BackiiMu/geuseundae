import { fit, smooth, ease, rand, hex, TAU } from "../../core/index.js";

export const meta = {
  name: "Geuseundae sealed soul chest",
  desc: "A restrained black-lacquered exorcist chest breaks its paper seal and releases a few cold soul fragments without gold, coins, gems or a loot explosion.",
  tags: ["geuseundae", "pickup", "chest", "reward", "soul", "sealed", "one-shot"],
  size: [80, 64], origin: [40, 56], duration: 1.8, loop: false, fps: 24, bg: "ground",
  options: {
    wood: ["#080b0e", "#11171b", "#1d272b", "#303b3d", "#4b5550"],
    metal: ["#13161a", "#292d31", "#454a49", "#6b6e61", "#96927a"],
    soul: ["#17232a", "#2e4b52", "#52767a", "#83a29b", "#bdd0bc", "#edf0d8"],
    seed: 1103,
  },
};

const PAPER = hex("#a89b76"), PAPER_HI = hex("#c8ba8b"), RED = hex("#65333a"), INK = hex("#080a0c");

function chestBody(p, W, M, a, shake) {
  const x = shake;
  p.rect(x-15,-14,30,14,W[0],a); p.rect(x-14,-13,28,11,W[2],a);
  p.rect(x-13,-12,26,4,W[3],a); p.rect(x-13,-7,26,4,W[1],a);
  p.line(x-14,-8,x+14,-8,W[0],a); p.line(x-14,-2,x+14,-2,M[0],a);
  for (const sx of [-11,10]) {
    p.rect(x+sx,-14,2,13,M[1],a);
    p.line(x+sx,-13,x+sx,-2,M[3],a*.75);
  }
  p.rect(x-3,-12,6,7,M[1],a); p.line(x-2,-11,x+1,-11,M[4],a*.8); p.px(x,-8,INK,a);
}

function lid(p, W, M, a, shake, open) {
  const x = shake;
  if (open <= .02) {
    p.rect(x-15,-20,30,6,W[0],a); p.rect(x-14,-19,28,4,W[3],a);
    p.line(x-13,-19,x+11,-19,W[4],a*.72); p.line(x-15,-14,x+15,-14,M[3],a);
    for (const sx of [-11,10]) p.rect(x+sx,-20,2,6,M[1],a);
    return;
  }
  const rise = Math.round(ease.outBack(open)*11), narrow = Math.round(open*2);
  p.poly([[x-15+narrow,-15-rise],[x+15-narrow,-15-rise],[x+13,-11-rise],[x-13,-11-rise]],W[0],a);
  p.poly([[x-13+narrow,-15-rise],[x+13-narrow,-15-rise],[x+11,-12-rise],[x-11,-12-rise]],W[3],a);
  p.line(x-12+narrow,-15-rise,x+10-narrow,-15-rise,W[4],a*.65);
  p.line(x-13,-11-rise,x+13,-11-rise,M[2],a);
}

function seal(p, t, shake, a) {
  if (t >= .58) return;
  const tear = smooth(.46,.58,t), x = shake+Math.round(tear*5);
  p.rect(x-2,-23+Math.round(tear*3),4,17+Math.round(tear*2),PAPER,a*(1-tear));
  p.line(x-1,-22,x-1,-8,PAPER_HI,a*.7*(1-tear));
  for (let y=-19;y<=-10;y+=3) p.px(x+((y/3)&1),y,RED,a*(1-tear));
}

function soulFragment(p, S, t, i, seed, a) {
  const age=t-(.56+i*.11);
  if (age<=0 || age>=.86) return;
  const u=age/.86, fade=Math.min(1,age/.12,(.86-age)/.25), side=i===1?0:i===0?-1:1;
  const x=side*(6+u*7)+Math.sin(u*TAU*(1.1+i*.18)+rand(i,seed,4)*TAU)*2;
  const y=-18-ease.outCubic(u)*(25+i*4), c=S[3+(i&1)];
  p.disc(x,y,3.2-u*1.1,c,.28*fade*a); p.px(Math.round(x),Math.round(y),S[5],fade*a);
  p.px(Math.round(x+side),Math.round(y+1),S[3],fade*a);
  p.line(x,y+2,x-side*2,y+7+u*3,S[2],.7*fade*a); p.glow(x,y,8,S[3],.12*fade*a);
}

export function drawBack(p,t,o) {
  const S=fit(o.soul,6), open=smooth(.5,.7,t), fade=1-smooth(1.5,1.8,t);
  if (fade<=0 || open<=0) return;
  p.ellipse(0,0,18,4,S[1],.12*open*fade); p.glow(0,-14,25,S[2],.1*open*fade);
}

export function draw(p,t,o) {
  const W=fit(o.wood,5), M=fit(o.metal,5), S=fit(o.soul,6), fade=1-smooth(1.5,1.8,t);
  if (fade<=0) return;
  const strain=smooth(.15,.52,t), shake=t<.56?Math.round(Math.sin(t*58)*strain):0, open=smooth(.5,.72,t);
  lid(p,W,M,fade,shake,open); chestBody(p,W,M,fade,shake); seal(p,t,shake,fade);
  for (let i=0;i<3;i++) soulFragment(p,S,t,i,o.seed,fade);
}
