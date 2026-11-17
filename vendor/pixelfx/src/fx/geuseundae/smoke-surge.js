// 두억시니 세트 주먹 보강: 기존 주먹 이펙트는 그대로 두고, 그 앞쪽 사거리 끝까지 검은 연기가 바닥을 따라 밀려 나간다.
// 단단한 덩어리가 아니라 겹치는 반투명 검은 연기이고, 반짝임이나 빛 번짐은 쓰지 않는다.
import { rng, fit, clamp, smooth, ease, TAU } from "../../core/index.js";

export const meta = {
  name: "Smoke surge",
  desc: "Black smoke rolls forward along the floor from the point of impact out to the far reach, billowing up and thinning away; no glow, no sparks.",
  tags: ["geuseundae", "smoke", "shadow", "melee", "reach", "one-shot"],
  size: [430, 170],
  origin: [30, 146],
  duration: 1.5,
  loop: false,
  fps: 20,
  bg: "ground",
  options: {
    palette: ["#040406", "#0c0c12", "#16161e", "#222230", "#33334a", "#4a4a62"],
    reach: 340,
    seed: 13,
  },
};

const D = meta.duration;
// one-shot이라 입자마다 한 번만 태어난다 (cycle은 반복용이라 쓰지 않는다)
function each(n, seed, fn) { for (let i = 0; i < n; i++) fn(rng(seed, i), i); }

export function draw(p, t, o) {
  const C = fit(o.palette, 6), R = o.reach, S = o.seed;
  // 앞으로 밀려 나가는 연기: 충격 지점(앞 60~120)에서 시작해 거리마다 도착 시각이 다르다 (멀수록 늦고 빠르게 번짐)
  const rolls = (layer, n, seedOff, yLo, yHi, sLo, sHi, aMax) => {
    each(n, S * 17 + seedOff, (r) => {
      // 모든 입자가 0~0.18초 사이에 태어나 약 0.9초 산다
      const born = r.range(0, 0.18), a = t - born;
      if (a < 0) return;
      const life2 = r.range(0.7, 1.0), k = a / life2;
      if (k >= 1) return;
      const x0 = r.range(50, 120), xe = r.range(R * 0.5, R * 1.0);
      const x = x0 + (xe - x0) * ease.outCubic(clamp(k * 2.2)) + k * 12;
      const rise = r.range(4, 20) * k, base = r.range(yLo, yHi);
      const y = -base - rise;
      const sz = r.range(sLo, sHi) * (0.55 + 0.85 * smooth(0, 0.7, k));
      const env = smooth(0, 0.14, k) * (1 - smooth(0.55, 1, k));
      // 거의 검은색: 몸통은 가장 어두운 두 단계, 위쪽 가장자리만 아주 약하게 밝다
      const tone = r.next() < 0.6 ? 0 : 1;
      p.disc(x, y, sz, C[tone], aMax * env);
      p.disc(x + sz * 0.12, y + sz * 0.1, sz * 0.7, C[0], aMax * 0.8 * env);
      if (base > yHi * 0.6) p.disc(x - sz * 0.2, y - sz * 0.38, sz * 0.42, C[3], 0.28 * env);
    });
  };
  rolls(0, 70, 1, 8, 56, 13, 24, 0.62);   // 뒤쪽: 크고 짙음
  rolls(1, 84, 2, 4, 42, 11, 21, 0.78);  // 중간
  // 위로 솟는 연기 줄기: 기둥처럼 높이 올라가다 흩어짐
  each(26, S * 29 + 5, (r) => {
    const born = r.range(0.04, 0.3), a = t - born;
    if (a < 0) return;
    const life2 = r.range(0.7, 1.1), k = a / life2;
    if (k >= 1) return;
    const x = r.range(80, R * 0.95) + k * 10, y = -6 - k * r.range(40, 95);
    const sz = r.range(7, 13) * (0.7 + 0.9 * k), env = smooth(0, 0.18, k) * (1 - smooth(0.45, 1, k));
    p.disc(x, y, sz, C[1], 0.7 * env);
    p.disc(x, y - sz * 0.25, sz * 0.55, C[2], 0.45 * env);
  });
  rolls(2, 60, 3, 0, 28, 10, 18, 0.88);  // 앞쪽: 아주 짙게 바닥을 훑음
}
