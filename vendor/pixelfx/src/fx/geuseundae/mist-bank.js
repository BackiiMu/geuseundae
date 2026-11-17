// 검은비늘 안개 공격: 적 자리에 넓게 깔리는 옅은 안개. 단단한 연기 덩어리가 아니라 반투명한 안개 층이
// 바닥을 따라 퍼지고, 위로 얇은 안개 줄기가 올라가다 흩어진다.
import { cycle, fit, clamp, smooth, TAU } from "../../core/index.js";

export const meta = {
  name: "Mist bank",
  desc: "A wide low bank of pale translucent fog: soft layers roll out along the floor, thin wisps lift off it and thin away, a faint cold light hangs inside.",
  tags: ["geuseundae", "fog", "mist", "aoe", "ambient", "loop"],
  size: [330, 140],
  origin: [165, 116],
  duration: 3,
  loop: true,
  fps: 20,
  bg: "ground",
  options: {
    palette: ["#1f2833", "#34414f", "#4d5d6e", "#6f8296", "#95a7b8", "#bccad6", "#e3ecf2"],
    spread: 100,
    seed: 5,
  },
};

const D = meta.duration;

export function draw(p, t, o) {
  const C = fit(o.palette, 7), W = o.spread, S = o.seed;
  // 바닥 안개 층: 가로로 길고 납작한 반투명 덩어리가 천천히 퍼지고 겹친다 (먼 층일수록 어둡고 흐릿)
  const layer = (n, seedOff, yLo, yHi, rLo, rHi, aMax, tone) => {
    cycle(t, D, n, S * 13 + seedOff, (q) => q.range(2.2, 3), (age, life, R) => {
      const k = age / life, env = smooth(0, 0.28, k) * (1 - smooth(0.62, 1, k));
      const x0 = R.range(-W, W), dir = R.sign ? R.sign() : (R.next() < 0.5 ? -1 : 1);
      const x = x0 + dir * (6 + 18 * k) + Math.sin(TAU * (k + R.next())) * 3;
      const edge = 1 - Math.pow(Math.abs(x0) / W, 2) * 0.7;
      const y = -R.range(yLo, yHi) - 4 * k + Math.sin(TAU * (k * 1.3 + R.next())) * 1.6;
      const r = R.range(rLo, rHi) * (0.8 + 0.5 * k);
      const col = C[clamp(tone + (R.next() < 0.35 ? 1 : 0) + (y < -26 ? 1 : 0), 0, 6)];
      p.disc(x, y, r, col, aMax * env * edge);
      p.disc(x - r * 0.15, y - r * 0.18, r * 0.62, C[clamp(tone + 1, 0, 6)], aMax * 0.7 * env * edge);
      // 가로로 길게 늘어난 가장자리: 안개가 바닥을 타고 번지는 느낌
      p.disc(x + dir * r * 0.9, y + r * 0.2, r * 0.55, col, aMax * 0.6 * env * edge);
    });
  };
  layer(36, 1, 4, 26, 13, 22, 0.1, 2);   // 뒤쪽: 어둡고 흐림
  layer(34, 2, 2, 22, 11, 19, 0.13, 3);  // 중간
  // 안개 줄기: 층 위로 가늘게 올라가며 흩어진다
  cycle(t, D, 22, S * 7 + 3, (q) => q.range(1.6, 2.6), (age, life, R) => {
    const k = age / life, env = smooth(0, 0.2, k) * (1 - smooth(0.4, 1, k));
    const x = R.range(-W * 0.8, W * 0.8) + Math.sin(TAU * (k * 0.8 + R.next())) * 7, y = -8 - k * R.range(30, 52);
    const r = R.range(5, 9) * (0.8 + k * 1.1);
    p.disc(x, y, r, C[4], 0.09 * env);
    p.disc(x + r * 0.2, y - r * 0.1, r * 0.6, C[5], 0.08 * env);
  });
  layer(26, 3, 0, 14, 9, 16, 0.16, 4);   // 앞쪽: 밝고 또렷
  // 안쪽의 은은한 찬 빛
  p.glow(0, -14, 70, C[5], 0.07);
}
