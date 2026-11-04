// Original equipment icons for Geuseundae. The hovering/glint presentation follows
// pixelfx pickup recipes; every item silhouette is project-specific.
import { fit, clamp, smooth, ease, TAU, WHITE, hex } from '../../core/index.js';

export const meta = {
  name: 'Geuseundae equipment icon',
  desc: 'A compact Korean-ghost equipment sprite with a rarity-scaled glint and floor light.',
  tags: ['equipment', 'icon', 'pickup', 'geuseundae', 'loop'],
  size: [42, 42], origin: [21, 33], duration: 1.6, fps: 12, loop: true, bg: 'dark',
  options: { item: 'hair', tier: 1, seed: 1103, palette: ['#111820','#34434a','#718185','#b6c1b5','#f0f0d7'] },
};

const INK = hex('#0b0d12');
const RED_DARK = hex('#5b2734');
const RED = hex('#9f3945');
const RED_LIGHT = hex('#cf6975');
const BONE = hex('#d5ccb0');
const WOOD = hex('#765037');
const WATER = hex('#5796a6');
const FOX = hex('#d97a51');
const GOLD_DARK = hex('#806637');
const GOLD = hex('#d5ad58');
const SICK = hex('#7f9b58');

function beam(p, a, b, w, c) { p.beam(a[0], a[1], b[0], b[1], w, c); }
function shine(p, x, y, k, c = WHITE) {
  if (k <= 0) return;
  p.line(x - 2, y, x + 2, y, c, k);
  p.line(x, y - 2, x, y + 2, c, k);
  p.px(x, y, WHITE);
}
function edge(p, pts, fill, rim) {
  p.poly(pts, INK);
  const q = pts.map(([x, y]) => [24 + (x - 24) * .88, -13 + (y + 13) * .88]);
  p.poly(q, fill);
  if (q.length > 2) p.line(q[0][0], q[0][1], q[1][0], q[1][1], rim);
}
function claw(p, x, y, flip, C) {
  for (let i = 0; i < 3; i++) {
    const yy = y + i * 5;
    p.arc(x, yy, 10 + i, 2, flip ? -1.2 : -1.95, flip ? .25 : -.45, C[3 - (i > 1 ? 1 : 0)]);
    p.px(x + (flip ? 8 : -8), yy - 5, C[4]);
  }
}
function eye(p, x, y, rx, C) {
  p.poly([[x-rx,y],[x,y-6],[x+rx,y],[x,y+6]], INK);
  p.poly([[x-rx+2,y],[x,y-4],[x+rx-2,y],[x,y+4]], C[2]);
  p.circle(x,y,3,C[4]); p.circle(x,y,1,INK); p.px(x-1,y-1,WHITE);
}
function vessel(p, x, y, C, poison=false) {
  p.rect(x-5,y-14,10,3,INK); p.rect(x-3,y-12,6,4,C[3]);
  p.ellipse(x,y,10,11,INK); p.ellipse(x,y,8,9,poison?SICK:C[2]);
  p.arc(x,y,7,2,-2.8,-.35,C[4]);
  if(poison){ p.circle(x-3,y-1,2,C[1]); p.circle(x+3,y+3,2,C[3]); }
}
function foot(p, x, y, C, wet=false) {
  beam(p,[x-2,y-13],[x+1,y],6,C[2]);
  p.poly([[x-2,y-2],[x+2,y-2],[x+9,y+2],[x+8,y+5],[x-3,y+5]],INK);
  p.poly([[x-1,y-1],[x+2,y],[x+7,y+2],[x+6,y+3],[x-2,y+3]],C[3]);
  if(wet){ p.circle(x+7,y+7,3,WATER,.65); p.dot(x+2,y+6,WATER,.8); }
}
function materialDetails(p,id,C){
  switch(id){
    case 'hair': p.px(-8,-22,C[3]);p.px(8,-17,C[2]);break;
    case 'pin': p.px(-3,-6,RED);p.px(5,-18,C[1]);break;
    case 'ribbon': p.line(-7,-20,-2,-17,C[3]);p.px(8,-4,C[1]);break;
    case 'mirror': p.px(0,-21,BONE);p.px(7,-11,GOLD);break;
    case 'eggshell': p.polyline([[-5,-23],[-2,-18],[-5,-14],[0,-10]],C[1]);p.px(5,-21,WHITE);break;
    case 'blank_face': p.polyline([[4,-25],[1,-20],[5,-16],[3,-11]],C[1]);p.px(-5,-23,WHITE);break;
    case 'gaze': p.line(-8,-15,-3,-14,RED);p.line(4,-15,9,-17,RED);p.px(1,-14,WHITE);break;
    case 'nails': case 'claws': p.px(-8,-19,BONE);p.px(-4,-14,C[1]);p.px(2,-8,RED);break;
    case 'goose': p.line(-8,-20,2,-17,C[1]);p.line(-6,-14,2,-11,C[2]);p.px(4,-24,WHITE);break;
    case 'mongdal_rush': p.px(-9,-19,RED);p.px(6,-15,RED);p.line(-1,-5,4,-1,C[4]);break;
    case 'call': p.px(-5,-14,WHITE);p.line(-6,-24,0,-21,C[4]);break;
    case 'tiger_soul': p.line(-9,-13,-4,-16,C[3]);p.line(4,-16,9,-13,C[3]);p.px(0,-21,C[4]);break;
    case 'tiger_fang': p.line(-8,-20,-5,-10,C[1]);p.line(7,-22,5,-14,C[4]);p.px(-2,-7,RED);break;
    case 'water_bucket': p.line(-6,-15,6,-12,BONE);p.px(-3,-6,WATER);p.px(8,-2,WHITE);break;
    case 'water_hand': p.line(-7,-20,-5,-9,WHITE);p.px(7,-4,WATER);p.px(1,3,WATER);break;
    case 'well_bucket': p.line(-7,-17,7,-17,C[4]);p.line(-8,-10,8,-10,C[1]);p.px(6,-4,WATER);break;
    case 'fox_bead': p.arc(0,-14,5,1,-2.8,1.8,WHITE);p.px(4,-11,FOX);break;
    case 'tails': p.px(-7,-15,WHITE);p.px(1,-9,WHITE);p.px(8,-4,WHITE);break;
    case 'fox_fire': p.px(0,-17,WHITE);p.line(-4,-8,2,-4,C[1]);break;
    case 'fox_mirror': p.polyline([[-4,-21],[1,-15],[-2,-10],[4,-6]],WHITE);p.px(5,-21,FOX);break;
    case 'club': p.px(8,-25,GOLD);p.px(11,-20,GOLD);p.line(-6,-5,1,-15,C[1]);break;
    case 'goblin_fire': p.px(0,-8,WHITE);p.px(-8,-21,C[4]);break;
    case 'broom': p.line(-8,-3,1,-8,C[4]);p.line(-5,1,5,-6,C[1]);p.px(6,-24,GOLD);break;
    case 'belt': p.arc(0,-13,10,1,-2.7,2.7,C[4]);p.line(-6,-21,7,-9,C[1]);break;
    case 'tooth': p.line(-9,-20,-7,-11,C[1]);p.line(6,-19,4,-9,C[1]);p.px(-1,-22,RED);break;
    case 'tongue': p.line(-10,-21,-4,-22,WHITE);p.px(5,-10,WHITE);p.px(6,0,RED);break;
    case 'shadow': p.line(-8,-22,-5,-13,C[3]);p.px(5,-24,C[4]);p.px(10,-8,C[2]);break;
    case 'voice': p.line(-9,-23,-5,-18,C[4]);p.px(-1,-14,RED);break;
    case 'plague': p.polyline([[-4,-18],[0,-13],[-3,-8],[2,-4]],C[1]);p.px(5,-11,WHITE);break;
    case 'whistle': p.px(-7,-14,WHITE);p.px(5,-19,C[4]);p.px(11,-10,C[3]);break;
    case 'mouth': p.line(-8,-13,8,-13,WHITE);p.px(-11,-9,RED);p.px(10,-16,RED);break;
    case 'fist': p.line(-10,-24,-7,-17,C[4]);p.line(1,-27,4,-19,C[3]);p.px(11,-15,WHITE);break;
    case 'wig': p.line(-8,-20,-10,-8,C[4]);p.line(3,-22,6,-5,C[1]);break;
    case 'duo_head': p.line(-10,-23,-6,-18,C[3]);p.px(0,-27,C[4]);p.line(6,-11,9,-8,C[1]);break;
    case 'bent_leg': p.line(-5,-21,-2,-14,BONE);p.line(-7,-4,-3,-8,RED);break;
    case 'mongdal_legs': p.line(-9,-10,-5,-8,C[4]);p.line(4,-9,9,-7,C[4]);break;
    case 'wet_shoes': p.px(-9,3,WHITE);p.px(9,4,WHITE);p.px(0,6,WATER);break;
    case 'single_shoe': p.px(4,-2,C[4]);p.line(-4,-10,3,-7,C[1]);break;
    case 'stomach': p.line(-5,-20,-2,-12,WHITE);p.px(5,-8,C[4]);break;
    case 'duo_curse': p.px(-8,-22,WHITE);p.px(8,-7,C[4]);p.arc(0,-14,5,1,-2.2,1.1,C[4]);break;
  }
}
function drawItem(p, id, C) {
  switch(id) {
    case 'hair':
      p.poly([[-14,-22],[-11,-26],[-6,-24],[-5,-19],[-10,-16],[-15,-18]],INK);
      p.poly([[-12,-22],[-10,-24],[-7,-23],[-7,-20],[-10,-18],[-13,-19]],RED_DARK);
      p.line(-11,-23,-8,-22,RED_LIGHT);
      const locks=[
        [[-7,-22],[0,-26],[8,-24],[14,-20]],
        [[-7,-20],[0,-21],[8,-18],[13,-12]],
        [[-8,-18],[-2,-14],[5,-10],[8,-2]],
      ];
      for(let i=0;i<locks.length;i++){
        const q=locks[i];
        for(let j=1;j<q.length;j++){beam(p,q[j-1],q[j],5,INK);beam(p,q[j-1],q[j],3,i===1?C[2]:C[1]);}
        if(i<2)p.polyline(q.map(([x,y])=>[x,y-1]),i===0?C[3]:C[2]);
      }
      p.polyline([[-5,-20],[1,-16],[10,-16],[15,-11]],C[2]);
      p.poly([[-13,-18],[-8,-13],[-10,-6],[-14,-11]],RED);p.line(-12,-16,-10,-10,RED_LIGHT); break;
    case 'pin':
      beam(p,[-14,5],[7,-19],6,INK);beam(p,[-13,4],[8,-20],3,C[2]);p.line(-11,1,7,-20,C[3]);
      p.poly([[-15,6],[-11,-1],[-8,1],[-12,6]],RED_DARK);p.line(-13,3,-11,0,RED_LIGHT);
      p.circle(8,-21,6,INK);
      p.poly([[8,-28],[11,-24],[15,-24],[12,-20],[13,-16],[8,-18],[4,-16],[5,-21],[1,-24],[6,-24]],GOLD_DARK);
      p.poly([[8,-27],[10,-23],[14,-23],[11,-21],[12,-18],[8,-20],[5,-18],[6,-22],[3,-24],[7,-24]],GOLD);
      p.circle(8,-22,2,RED);p.px(7,-23,RED_LIGHT);
      p.arc(3,-25,5,2,-2.7,.2,GOLD_DARK);p.arc(8,-21,9,2,-2.8,-1.5,C[2]);
      p.line(12,-18,14,-13,GOLD);p.px(14,-12,BONE); break;
    case 'ribbon':
      p.poly([[-3,-19],[-11,-25],[-15,-21],[-9,-14],[-14,-9],[-8,-7],[0,-13]],INK);
      p.poly([[-3,-17],[-10,-23],[-13,-21],[-7,-14],[-11,-10],[-8,-9],[1,-14]],RED_DARK);
      p.polyline([[-9,-21],[-5,-16],[-8,-11]],RED_LIGHT);
      p.poly([[3,-19],[11,-24],[15,-20],[8,-14],[14,-9],[9,-7],[0,-13]],INK);
      p.poly([[3,-17],[10,-22],[13,-20],[6,-14],[11,-10],[9,-9],[-1,-14]],BONE);p.line(5,-17,10,-20,C[3]);
      p.circle(0,-15,6,INK);p.circle(0,-15,4,RED);p.line(-2,-17,2,-14,RED_LIGHT);
      p.poly([[-3,-11],[-9,4],[-4,1],[-1,4],[2,-10]],RED);p.line(-4,-8,-7,0,RED_LIGHT);
      p.px(-9,4,RED_LIGHT);p.px(-3,3,RED_DARK);
      p.poly([[2,-10],[7,4],[10,0],[13,2],[5,-12]],BONE);p.line(5,-8,7,0,C[3]);p.px(13,2,C[3]);break;
    case 'mirror':
      p.poly([[-14,-7],[-12,-22],[-7,-28],[-2,-26],[1,-30],[5,-25],[10,-27],[13,-20],[14,-7],[10,-3],[-10,-3]],INK);
      p.poly([[-11,-9],[-10,-21],[-6,-25],[-2,-23],[1,-27],[4,-22],[8,-24],[10,-19],[11,-9]],C[1]);
      p.poly([[-10,-19],[-7,-24],[-4,-22],[-5,-9],[-10,-8]],RED_DARK);p.line(-8,-21,-6,-11,RED_LIGHT);
      p.poly([[5,-22],[8,-23],[11,-18],[10,-8],[5,-10]],RED);p.line(7,-21,9,-11,RED_LIGHT);
      p.rect(-10,-13,20,4,GOLD_DARK);p.rect(-9,-13,18,2,GOLD);p.line(-7,-13,7,-13,BONE);
      p.circle(0,-20,5,GOLD_DARK);p.circle(0,-20,3,GOLD);p.circle(0,-20,1,RED_LIGHT);
      p.line(10,-18,15,-17,GOLD_DARK);p.px(15,-17,GOLD);
      for(let i=-1;i<=1;i++){const x=i*7;p.line(x,-8,x,-2,GOLD_DARK);p.circle(x,0,2,RED);p.px(x-1,-1,RED_LIGHT);p.line(x,2,x,5,BONE);} break;
    case 'eggshell':
      p.ellipse(0,-14,12,15,INK); p.ellipse(0,-14,10,13,BONE);
      p.poly([[-10,-11],[-4,-15],[0,-10],[5,-16],[10,-12],[10,-3],[-10,-3]],C[1]); break;
    case 'blank_face':
      p.ellipse(0,-14,11,15,INK); p.ellipse(0,-14,9,13,BONE); p.line(-4,-17,-2,-17,C[1]); p.line(3,-17,5,-17,C[1]); break;
    case 'gaze': eye(p,0,-15,15,C); p.line(-12,-23,-5,-20,C[3]); p.line(5,-20,12,-23,C[3]); break;
    case 'nails':
      p.poly([[-13,1],[-12,-12],[-9,-23],[-5,-24],[-4,-12],[-2,-28],[2,-28],[3,-12],[6,-26],[10,-24],[9,-9],[13,-18],[16,-15],[12,-2],[5,4]],INK);
      p.poly([[-10,0],[-9,-11],[-7,-20],[-5,-20],[-4,-8],[-1,-23],[1,-23],[2,-8],[5,-21],[8,-20],[7,-6],[11,-14],[13,-12],[9,0],[4,2]],C[1]);
      p.line(-7,-20,-6,-25,C[4]);p.line(-1,-23,0,-29,C[4]);p.line(6,-20,8,-26,C[4]);p.line(11,-13,15,-17,C[3]);break;
    case 'goose':
      p.poly([[-13,-7],[-10,-23],[-2,-27],[6,-23],[11,-14],[7,-10],[2,-18],[-3,-20],[-5,-5]],WOOD);
      p.circle(6,-23,2,C[3]); p.px(7,-24,WHITE); p.poly([[8,-22],[15,-19],[8,-18]],GOLD); break;
    case 'mongdal_rush':
      p.circle(-3,-16,8,INK); p.circle(-3,-16,5,C[1]);
      p.poly([[-7,-12],[-13,-1],[-5,-4],[-1,3],[1,-9]],RED);
      p.poly([[1,-12],[7,-2],[11,-6],[14,1],[5,-3]],C[2]);
      for(let i=0;i<3;i++)p.line(3+i*3,-24+i*3,12+i*2,-20+i*4,C[4]); break;
    case 'claws':
      p.poly([[-14,2],[-13,-14],[-8,-23],[1,-24],[7,-18],[6,-6],[1,3]],INK);
      p.poly([[-11,0],[-10,-13],[-6,-20],[0,-21],[4,-17],[3,-7],[-1,1]],C[1]);
      for(let i=0;i<3;i++){
        const y=-20+i*6;p.poly([[-4,y],[-1,y-3],[15,y-9],[11,y-3],[0,y+3]],i===1?BONE:C[3]);p.line(0,y-1,12,y-7,C[4]);
      } break;
    case 'call':
      p.poly([[-12,-25],[-5,-29],[1,-23],[-5,-18]],INK);
      p.poly([[-9,-24],[-5,-26],[-1,-23],[-5,-20]],C[3]);
      p.line(-5,-19,-2,-11,GOLD); p.circle(-1,-8,4,INK); p.circle(-1,-8,2,C[4]);
      p.arc(1,-10,10,2,-1.0,1.0,C[3]); p.arc(1,-10,17,2,-.8,.8,C[4]); break;
    case 'tiger_soul':
      p.poly([[-13,-6],[-11,-24],[-5,-29],[-1,-23],[5,-28],[11,-21],[13,-5],[4,-12],[0,-6],[-5,-12]],C[1]);
      p.rect(-6,-19,4,3,C[4]); p.rect(3,-19,4,3,C[4]); break;
    case 'tiger_fang':
      for(let s of [-1,1]) p.poly([[s*2,-26],[s*12,-23],[s*9,-4],[s*2,-13]],s<0?C[3]:C[2]);
      p.line(-8,-21,-5,-8,C[4]); break;
    case 'water_bucket': vessel(p,0,-13,C); p.arc(-4,-24,11,2,-2.7,-.35,WOOD); p.circle(7,-1,3,WATER,.7); break;
    case 'water_hand':
      p.poly([[-12,1],[-10,-16],[-7,-26],[-3,-25],[-2,-14],[0,-29],[4,-28],[4,-13],[8,-25],[11,-23],[9,-7],[4,1]],WATER);
      p.line(-8,-15,7,-11,C[4]); break;
    case 'well_bucket':
      p.poly([[-12,-20],[12,-20],[9,0],[-9,0]],INK); p.poly([[-9,-18],[9,-18],[7,-2],[-7,-2]],WOOD);
      p.arc(0,-20,13,2,-2.8,-.35,C[3]); p.line(-5,-14,6,-14,C[4]); break;
    case 'fox_bead': p.circle(0,-14,11,INK); p.circle(0,-14,8,C[2]); p.circle(-2,-16,4,C[3]); p.circle(-4,-18,2,WHITE); break;
    case 'tails':
      for(let i=0;i<5;i++) p.arc(-5+i*2,-5,13+i,3,-2.8+i*.12,-.55+i*.08,i%2?FOX:C[3]); break;
    case 'fox_fire':
      p.poly([[0,-29],[6,-20],[11,-15],[7,-4],[0,1],[-8,-5],[-10,-15],[-4,-21]],C[2]);
      p.poly([[0,-21],[4,-15],[3,-7],[-2,-4],[-5,-11]],C[4]); break;
    case 'fox_mirror':
      p.ellipse(0,-15,12,15,GOLD); p.ellipse(0,-15,9,12,INK); p.ellipse(0,-15,7,10,C[2]);
      p.poly([[-4,-20],[0,-24],[4,-20],[2,-12],[5,-7],[-1,-9],[-4,-5],[-3,-13]],C[4]); break;
    case 'club':
      beam(p,[-10,2],[8,-24],7,WOOD); p.poly([[1,-28],[8,-32],[15,-27],[13,-17],[5,-17]],C[2]);
      p.px(7,-27,C[4]); p.px(12,-23,C[4]); break;
    case 'goblin_fire':
      p.poly([[0,-30],[4,-23],[11,-25],[8,-17],[13,-10],[6,-2],[-2,1],[-10,-4],[-13,-12],[-7,-18],[-9,-26],[-2,-23]],C[2]);
      p.poly([[-1,-23],[5,-20],[5,-13],[1,-7],[-5,-9],[-7,-16]],C[4]);
      p.px(-3,-15,INK); p.px(3,-15,INK); break;
    case 'broom':
      beam(p,[-11,3],[8,-27],4,WOOD); for(let i=0;i<5;i++) beam(p,[-12+i*3,2],[1+i,-9],3,C[2]); break;
    case 'belt':
      p.arc(0,-13,13,5,-2.9,2.9,C[2]); p.arc(0,-13,8,3,-2.9,2.9,WOOD);
      p.poly([[8,-5],[14,-1],[8,3],[3,-3]],C[4]); break;
    case 'tooth':
      for(let i=0;i<4;i++) p.poly([[-13+i*8,-25],[-7+i*8,-22],[-9+i*8,-4],[-14+i*8,-15]],i%2?BONE:C[3]); break;
    case 'tongue':
      p.polyline([[-13,-22],[-5,-26],[2,-21],[8,-13],[3,-6],[-4,-10],[0,-1],[8,2]],RED);
      p.line(-12,-21,-3,-24,C[4]); break;
    case 'shadow':
      p.poly([[-13,0],[-11,-17],[-7,-27],[-2,-24],[0,-13],[3,-29],[8,-26],[8,-12],[13,-21],[14,-6],[8,1]],C[0]);
      p.line(-8,-18,6,-14,C[3]); break;
    case 'voice':
      p.poly([[-13,-21],[-5,-27],[0,-23],[-2,-11],[-8,-7]],C[1]);
      p.arc(-4,-16,12,2,-.8,.8,C[3]); p.arc(-4,-16,18,2,-.7,.7,C[4]); break;
    case 'plague': vessel(p,0,-13,C,true); break;
    case 'whistle':
      p.poly([[-14,-20],[-5,-22],[0,-17],[-4,-11],[-14,-12]],INK);
      p.poly([[-11,-18],[-5,-19],[-2,-17],[-5,-14],[-11,-15]],BONE); p.rect(-5,-18,3,2,C[1]);
      p.arc(-4,-16,10,2,-.8,.8,C[2]); p.arc(-4,-16,17,2,-.7,.7,C[3]); p.arc(-4,-16,23,1,-.6,.6,C[4]); break;
    case 'mouth':
      p.ellipse(0,-13,15,12,INK); p.ellipse(0,-13,12,8,RED);
      for(let i=-2;i<=2;i++){p.poly([[i*4-2,-21],[i*4+1,-14],[i*4+3,-21]],BONE);p.poly([[i*4-2,-5],[i*4+1,-12],[i*4+3,-5]],BONE);} break;
    case 'fist':
      p.poly([[-16,4],[-16,-7],[-13,-20],[-8,-29],[-1,-30],[1,-25],[5,-32],[12,-30],[15,-20],[13,-5],[7,2],[-3,2],[-8,8]],C[0]);
      for(let i=0;i<4;i++){p.rect(-11+i*7,-27-(i%2)*3,6,13,C[1]);p.line(-10+i*7,-27-(i%2)*3,-6+i*7,-27-(i%2)*3,C[4]);}
      p.poly([[-14,-8],[-7,-14],[10,-11],[13,-4],[6,1],[-6,0]],C[1]);
      p.line(-8,-12,10,-10,C[3]); p.polyline([[-15,1],[-10,-3],[-7,2],[-11,6]],C[2]); break;
    case 'wig':
      p.arc(0,-13,13,7,-3.05,-.1,C[2]); for(let i=-10;i<=10;i+=4)p.polyline([[i,-18],[i-2,-7],[i+1,2]],i%8?C[2]:C[3]); break;
    case 'duo_head':
      p.poly([[-14,-5],[-13,-21],[-8,-30],[-2,-27],[1,-31],[6,-27],[10,-30],[14,-21],[13,-5],[6,2],[-6,2]],C[0]);
      p.poly([[-11,-23],[-7,-29],[-3,-25],[-5,-18]],C[1]); p.poly([[5,-27],[10,-25],[11,-18],[6,-20]],C[1]);
      p.rect(-8,-17,6,3,C[4]); p.rect(3,-17,6,3,C[4]); p.line(-6,-7,7,-7,C[3]); p.px(0,-11,C[2]); break;
    case 'bent_leg': beam(p,[-6,-27],[-3,-11],7,C[2]); beam(p,[-3,-11],[-11,1],7,C[2]); beam(p,[-11,1],[1,1],5,C[3]); break;
    case 'mongdal_legs': foot(p,-6,-4,C); foot(p,7,-4,C); p.line(-5,-17,8,-17,C[4]); break;
    case 'wet_shoes': foot(p,-5,-4,C,true); foot(p,7,-4,C,true); break;
    case 'single_shoe': foot(p,0,-4,C,false); p.line(-5,-13,5,-8,RED); break;
    case 'stomach':
      p.ellipse(0,-14,12,15,INK); p.ellipse(0,-14,9,12,RED); p.arc(-1,-13,6,2,-2.6,2.3,C[4]); p.line(-6,-25,5,-2,C[1]); break;
    case 'duo_curse':
      p.ring(0,-14,13,3,C[1]); p.arc(0,-14,9,3,-2.8,1.8,C[3]); p.line(-8,-22,8,-6,C[4]); p.line(8,-22,-8,-6,C[4]); break;
  }
}

export function drawBack(p, t, o) {
  const C=fit(o.palette,5), tier=clamp(Math.round(o.tier),1,4), k=.08+tier*.035;
  if(tier>=3) p.glow(0,-13,18+tier*3,C[2],k);
  if(tier===4){
    const ph=t/meta.duration*TAU;
    for(let i=0;i<3;i++){
      const a=ph+i*TAU/3, x=Math.cos(a)*17, y=-13+Math.sin(a)*7;
      p.dot(x,y,C[3],.65); p.glow(x,y,5,C[3],.12);
    }
  }
}

export function draw(p, t, o) {
  const C=fit(o.palette,5), tier=clamp(Math.round(o.tier),1,4);
  drawItem(p,o.item,C);
  materialDetails(p,o.item,C);
  if(tier>=2){
    const phase=((t/meta.duration)-(tier===2?.38:.18)+1)%1;
    if(phase<.18){const q=Math.sin(phase/.18*Math.PI);shine(p,-8+16*ease.inOutSine(phase/.18),-24+8*phase/.18,Math.min(1,q*1.4),tier===4?GOLD:C[4]);}
  }
  if(tier===3){
    const ph=t/meta.duration*TAU;
    p.dot(Math.cos(ph)*16,-13+Math.sin(ph)*8,C[3],.6);
  }
  if(tier===4){
    const a=1-smooth(.45,1,((t/meta.duration)+.1)%1),r=18+8*(1-a);
    for(let i=0;i<3;i++)p.arc(0,-13,r+i*3,1,-2.6+i*.5,-2.25+i*.5,C[3],a*.65);
  }
}
