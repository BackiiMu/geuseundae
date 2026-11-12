// 범의 송곳니 F 스킬: 푸른 영혼 호랑이 머리 기공파.
// 머리 도트는 tiger-head-data.js(JSON 데이터: 산호랑이 시트의 머리를 파랗게 바꾼 것)를 p.sprite()로 그리고,
// 뒤로 흐르는 기운 띠와 잔상은 pixelfx painter로 그린다. 광·반짝임은 쓰지 않는다.
import {fit,clamp,smooth,seg,ease,TAU,hex} from '../../core/index.js';
import HEAD from './tiger-head-data.js';

export const meta = {
  name: 'Tiger spirit wave',
  desc: 'A blue spirit tiger head with its mouth wide open flies forward like a ki wave, trailing ribbons of pale blue energy and fading afterimages.',
  tags: ['geuseundae', 'tiger', 'projectile', 'beast', 'spirit'],
  size: [260, 120], origin: [190, 62], duration: 1.2, loop: true, fps: 20, bg: 'ground',
  options: {
    palette: ['#0b1a3e', '#16306a', '#25508f', '#3f7dc9', '#6fb0ee', '#a9d8ff', '#e6f6ff'],
    seed: 11,
  },
};

const SCALE = 2;
// 턱이 벌어졌다 닫히는 순서(0=입 조금 열림, 1=크게 벌림)
const JAW = [0, 1, 1, 1, 0, 0];

// 머리 도트를 한 칸씩 그린다. 왼쪽 아래(잘라 낸 목)는 디더로 풀려 뒤따르는 기운 속으로 녹는다.
function head(p, x, y, frameIndex, alpha) {
  const f = HEAD.frames[frameIndex], [w, h] = HEAD.size, pal = HEAD._pal || (HEAD._pal = Object.fromEntries(Object.entries(HEAD.palette).map(([k, v]) => [k, hex(v)])));
  const x0 = Math.round(x - (w * SCALE) / 2), y0 = Math.round(y - (h * SCALE) / 2);
  for (let r = 0; r < h; r++) for (let q = 0; q < w; q++) {
    const ch = f[r][q];
    if (ch === '.') continue;
    const k = q + (h - r) * .6;                    // 왼쪽 아래일수록 작다
    const a = alpha * clamp((k - 8) / 18);
    if (a <= 0) continue;
    p.rect(x0 + q * SCALE, y0 + r * SCALE, SCALE, SCALE, pal[ch], a);
  }
}

// trail: 'none' = 머리만(목은 디더로 풀림) / 'mist' = 푸른 안개 덩어리가 뒤로 흩어짐 (원형 디더 덩어리, 가는 선 없음)
export function makeCreate(trail) {
  return function create(o) {
    const C = fit(o.palette, 7);
    let t = 0;
    return {
      update(dt) { t += dt; },
      draw(p) {
        const tt = t % meta.duration;
        const ph = tt / meta.duration * TAU;
        const bob = Math.round(Math.sin(ph * 2) * 2);
        const jawIndex = JAW[Math.floor(tt * meta.fps / 2) % JAW.length];
        if (trail === 'mist') {
          // 머리 뒤로 흩어지는 안개 덩어리: 뒤로 갈수록 작고 옅어진다 (alpha는 디더로 풀림)
          for (let i = 0; i < 9; i++) {
            const u = i / 8, drift = (tt * 90 + i * 12) % 100;
            const x = -34 - u * 96, y = bob + Math.sin(ph + i * 1.3) * (3 + u * 8) + (i % 2 ? 4 : -4) * (1 - u);
            const r = 15 - u * 10, a = .62 * (1 - u) ** 1.3;
            // 한 칸씩 찍어 알파가 디더 무늬로 풀리게 한다(부드러운 원이 아니라 도트 덩어리)
            const col = i % 3 === 0 ? C[4] : i % 3 === 1 ? C[3] : C[2];
            for (let yy = -Math.ceil(r); yy <= Math.ceil(r); yy++) for (let xx = -Math.ceil(r); xx <= Math.ceil(r); xx++) {
              const d = Math.hypot(xx, yy);
              if (d <= r) p.dot(Math.round(x + xx), Math.round(y + yy), d > r - 1.6 ? C[2] : col, a * (d > r * .65 ? .75 : 1));
            }
          }
          for (let i = 0; i < 12; i++) {                           // 흩날리는 작은 조각
            const q = (i * 37 % 100) / 100, x = -50 - ((q * 120 + tt * 150) % 110), y = Math.sin(i * 2.7 + ph) * 22 + bob;
            const a = 1 - (-50 - x) / 110;
            if (a > 0) p.rect(Math.round(x), Math.round(y), 2, 2, C[i % 2 ? 5 : 3], a * .8);
          }
        }
        head(p, 0, bob, jawIndex, 1);
      },
    };
  };
}
export const create = makeCreate('none');
