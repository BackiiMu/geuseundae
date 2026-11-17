// 검은비늘 도깨비불 공격: 도깨비불 색(청록)의 반투명한 큰 불덩이와 그 둘레를 떠도는 먼지 같은 불티.
// 가운데 구체는 도깨비불처럼 가장자리가 일렁이고(위로 혀가 일어남), 속은 비어 은은하다.
import { cycle, fit, clamp, smooth, TAU } from "../../core/index.js";

export const meta = {
  name: "Wisp orb",
  desc: "A big translucent ghost-fire orb whose rim wavers and licks upward, a hollow glowing heart, and a drift of dust-like teal motes floating and orbiting around it.",
  tags: ["geuseundae", "ghost-fire", "orb", "dokkaebi", "aoe", "loop"],
  size: [200, 160],
  origin: [100, 116],
  duration: 3,
  loop: true,
  fps: 20,
  bg: "ground",
  options: {
    palette: ["#0a2a2c", "#14606a", "#22a89a", "#4fd0b0", "#8ae8cc", "#c4f8e4", "#effffa"],
    radius: 22,
    seed: 7,
  },
};

const D = meta.duration, Y = -46;

export function draw(p, t, o) {
  const C = fit(o.palette, 7), R = o.radius, S = o.seed, w = (n, ph = 0) => TAU * (n * t / D) + ph;
  // 바닥에 비치는 희미한 도깨비불 빛
  p.glow(0, -2, 64, C[2], 0.08);
  p.glow(0, Y, R * 2.6, C[3], 0.16 + 0.05 * Math.sin(w(2)));

  // 뒤쪽 먼지: 구체 뒤를 도는 어두운 불티
  const motes = (front) => {
    cycle(t, D, 140, S * 9 + 1, (q) => q.range(1.8, 3), (age, life, r) => {
      const k = age / life, env = smooth(0, 0.2, k) * (1 - smooth(0.55, 1, k));
      const base = r.range(0, TAU), rr = R * r.range(0.7, 3.6), z = Math.sin(base + k * r.range(-1.4, 1.4));
      if ((z >= 0) !== front) return;
      // 먼지처럼 천천히 떠돌며 위로 조금씩 올라간다 (가끔 구체 쪽으로 빨려 들어감)
      const pull = r.next() < 0.25 ? smooth(0.4, 1, k) * 0.55 : 0;
      const x = Math.cos(base + k * 0.9) * rr * (1 - pull) + Math.sin(w(1.3, r.range(0, TAU))) * 4;
      const y = Y + Math.sin(base + k * 0.9) * rr * 0.5 * (1 - pull) - k * r.range(4, 28) + Math.sin(w(2.1, r.range(0, TAU))) * 3;
      const tw = 0.85; // 반짝이지 않고 일정하게 떠다닌다
      const col = C[clamp(Math.floor(r.range(2, 6.9)), 1, 6)];
      p.dot(x, y, col, 0.7 * env * tw * (front ? 1 : 0.65));
      if (r.next() < 0.5) { p.dot(x + 1, y, col, 0.5 * env * tw); p.dot(x, y + 1, col, 0.4 * env * tw); }
    });
  };
  motes(false);

  // 구체: 가장자리가 일렁이고 위로 불 혀가 오르는 반투명 도깨비불
  const x0 = -Math.ceil(R * 1.9), x1 = Math.ceil(R * 1.9), y0 = Math.floor(Y - R * 2.2), y1 = Math.ceil(Y + R * 1.4);
  for (let y = y0; y <= y1; y++) {
    for (let x = x0; x <= x1; x++) {
      const dx = x + 0.5, dy = y + 0.5 - Y, a = Math.atan2(dy, dx), d = Math.hypot(dx, dy), up = Math.max(0, -Math.sin(a));
      // 가장자리: 아래는 둥글고 위쪽은 여러 갈래의 불 혀가 서로 다른 박자로 일렁인다
      const re = R * (1 + 0.07 * Math.sin(3 * a + w(2)) + 0.05 * Math.sin(5 * a - w(3, 1))
        + up * up * (0.42 + 0.28 * Math.sin(w(3, 0.4) + 5 * a) + 0.16 * Math.sin(w(5, 2.1) - 7 * a)));
      if (d > re) continue;
      const f = d / re;
      // 속이 비어 은은하고 가장자리로 갈수록 밝아지는 도깨비불. 띠 대신 일렁이는 얼룩으로 색을 섞는다
      const n = Math.sin(x * 0.2 + w(2, y * 0.1)) * Math.sin(y * 0.17 - w(3, x * 0.07)) * 0.5 + 0.5;
      const g = clamp(f + (n - 0.5) * 0.3 + 0.05 * Math.sin(w(4, a * 2)), 0, 1);
      const col = g > 0.86 ? C[5] : g > 0.68 ? C[4] : g > 0.46 ? C[3] : g > 0.25 ? C[2] : C[1];
      const al = (0.14 + 0.36 * smooth(0.3, 0.95, g)) * (1 - 0.5 * smooth(0.93, 1, f)) * (0.88 + 0.12 * Math.sin(w(7, n * 6)));
      p.blend(x, y, col, al);
    }
  }
  // 속 알맹이: 작고 연한 불빛이 일렁이며 움직임
  const hx = Math.sin(w(2)) * 2.5, hy = Y + 3 + Math.cos(w(3)) * 2;
  p.glow(hx, hy, R * 0.9, C[5], 0.1);
  p.disc(hx, hy, R * 0.28, C[6], 0.18);

  // 앞쪽 먼지: 구체 앞을 지나는 밝은 불티
  motes(true);
}
