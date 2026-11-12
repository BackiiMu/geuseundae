// 장산범의 앞발: 초승달 곡선을 따라 위에서 아래로 훑는 굵은 발톱 자국 4줄(처음부터 그림).
// 원점은 캐릭터 가슴. 앞(+x)으로 볼록한 초승달, 위·아래 끝으로 갈수록 가늘고 뾰족하다.
// 가장자리는 면 채우기(poly)로 또렷하게 그리고, 사라질 때만 painter의 디더 알파를 쓴다. 광·반짝임 없음.
import {fit,clamp,smooth,TAU} from '../../core/index.js';

export const meta = {
  name: 'Paw claw crescent',
  desc: 'Four thick claw gashes sweep top to bottom along a forward-bulging crescent, then break apart with an ordered dither fade.',
  tags: ['geuseundae', 'claw', 'melee', 'jangsan'],
  size: [180, 190], origin: [32, 112], duration: .5, loop: false, fps: 30, bg: 'ground',
  options: {
    palette: ['#0c101c', '#6f788f', '#a9b1c8', '#d7dcec', '#f6f7fb', '#3b4358', '#8a93ab'],
    seed: 5,
    reach: 145, a: 105, b: 85, cy: -14, thickness: 150, claws: 4, width: 17, tilt: -26,
  },
};

const PM = 100.8 * Math.PI / 180;
const STEPS = 44;

export function create(o) {
  const C = fit(o.palette, 7);
  const R = o.reach ?? 145, A = o.a ?? 105, B = o.b ?? 85, CY = o.cy ?? -14, TH = o.thickness ?? 150, N = o.claws ?? 4, W = o.width ?? 8;
  const CX = R - A, TL = (o.tilt ?? -26) * Math.PI / 180, PCX = CX + A * .45, PCY = CY;
  // 곡선을 기울여 비스듬한 대각 할퀴기로 만든다(거의 세로인 곡선은 계단이 길고 불규칙해 보인다)
  const rot = ([x, y, w]) => { const dx = x - PCX, dy = y - PCY; return [PCX + dx * Math.cos(TL) - dy * Math.sin(TL), PCY + dx * Math.sin(TL) + dy * Math.cos(TL), w]; };
  let t = 0;
  // φ(-PM..PM)에서 클로 k의 중심선 점과 폭
  const pt = (k, ph) => {
    const th = TH * Math.cos(ph / PM * Math.PI / 2);
    const ox = CX + A * Math.cos(ph), oy = CY + B * Math.sin(Math.max(-Math.PI / 2, Math.min(Math.PI / 2, ph)));
    const f = N === 1 ? .4 : .06 + .68 * k / (N - 1);                // 0=바깥(앞쪽) 1=안쪽
    const w = 1.4 + W * Math.pow(Math.max(0, Math.cos(ph / PM * Math.PI / 2)), .62);
    return rot([ox - th * f, oy, w]);
  };
  return {
    update(dt) { t += dt; },
    draw(p) {
      if (t > meta.duration) return;
      const sweep = clamp(t / .1);                                  // 위→아래 드러남
      const fade = 1 - smooth(.30, .50, t);                         // 0.3초 유지 후 0.2초에 디더로 사라짐
      if (fade <= 0) return;
      for (let k = 0; k < N; k++) {
        const delay = k * .012, s = clamp((t - delay) / .1);
        const n = Math.floor(STEPS * s); if (n < 2) continue;
        const rows = [];
        for (let i = 0; i <= n; i++) { const ph = -PM + 2 * PM * i / STEPS; rows.push(pt(k, ph)); }
        const band = (f, d = 0) => {
          const L = rows.map(([x, y, w]) => [x - w * f / 2 - d, y]), Rr = rows.map(([x, y, w]) => [x + w * f / 2 + d, y]);
          return L.concat(Rr.slice().reverse());
        };
        // 외곽선 → 본체 → 밝은 속 → 가장 밝은 중심선 (가운데가 빛나는 굵은 할퀸 자국)
        p.poly(band(1, 1.3), C[0], fade);
        p.poly(band(1), C[1], fade);
        p.poly(band(.78), C[2], fade);
        p.poly(band(.5), C[3], fade);
        p.poly(band(.2), C[4], fade);
      }
      // 맞은 자국에서 튀는 작은 조각(초반 짧게)
      if (t < .2) {
        const u = t / .2;
        for (let i = 0; i < 8; i++) {
          const ph = -PM * .8 + 1.6 * PM * (i / 7), [x, y] = pt(0, ph);
          p.px(x + 4 + u * (10 + (i % 3) * 5), y + (i % 2 ? 1 : -1) * u * 8, C[i % 2 ? 3 : 4]);
        }
      }
    },
  };
}
