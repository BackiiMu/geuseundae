// 두억시니 세트 완성 주먹: 검은 연기가 먼저 주먹 자리를 감싸며 뭉쳤다가, 내려찍는 순간 판정 범위(앞쪽 반타원)를
// 통째로 덮는 검은 연기 돔이 밀려 나가고, 바닥에는 균열과 충격 고리가 번진다. 반짝임·빛 번짐은 쓰지 않는다.
import { rng, fit, clamp, smooth, ease, TAU } from "../../core/index.js";

export const meta = {
  name: "Duo slam",
  desc: "Black smoke winds round the raised fist, then a dome of it slams out over the whole reach as the floor cracks and shock rings roll along it; no glow.",
  tags: ["geuseundae", "smoke", "shadow", "melee", "slam", "aoe", "one-shot"],
  size: [460, 270],
  origin: [40, 248],
  duration: 1.9,
  loop: false,
  fps: 20,
  bg: "ground",
  options: {
    palette: ["#030305", "#0a0a10", "#14141c", "#20202c", "#303042", "#46465c"],
    rx: 340,
    ry: 170,
    cx: 120,
    seed: 21,
  },
};

const SLAM = 0.32;               // 연기가 뭉치는 시간 → 내려찍는 순간
const each = (n, seed, fn) => { for (let i = 0; i < n; i++) fn(rng(seed, i), i); };
const disc = (p, x, y, r, c, a) => { if (a > 0.03 && r > 0.5) p.disc(x, y, r, c, a); };

export function draw(p, t, o) {
  const C = fit(o.palette, 6), RX = o.rx, RY = o.ry, CX = o.cx, S = o.seed;
  const HY = -118;                // 주먹이 들려 있는 높이

  // ① 감싸기: 0~SLAM 동안 검은 연기가 주먹 자리 둘레를 나선으로 돌며 뭉친다
  if (t < SLAM + 0.12) {
    const g = clamp(t / SLAM), fade = 1 - smooth(SLAM, SLAM + 0.12, t);
    each(52, S * 3 + 1, (r, i) => {
      const a0 = r.range(0, TAU), rad = r.range(20, 58) * (1 - 0.55 * ease.inCubic(g)), turn = TAU * (1.2 + r.range(0, 0.8)) * g;
      const a = a0 + turn, x = CX + Math.cos(a) * rad, y = HY + Math.sin(a) * rad * 0.9 + r.range(-8, 8);
      const sz = r.range(9, 16) * (0.6 + 0.6 * g);
      disc(p, x, y, sz, C[r.next() < 0.6 ? 0 : 1], 0.75 * smooth(0, 0.2, g) * fade);
      if (r.next() < 0.3) disc(p, x - sz * 0.2, y - sz * 0.3, sz * 0.45, C[3], 0.25 * fade);
    });
    // 기둥처럼 솟는 연기가 주먹 아래로 모인다
    each(18, S * 5 + 2, (r) => {
      const k = clamp(g * 1.2 - r.range(0, 0.3)), x = CX + r.range(-26, 26), y = lerp(-6, HY + 30, ease.outCubic(k));
      disc(p, x, y, r.range(8, 14) * (0.6 + k), C[1], 0.6 * smooth(0, 0.2, k) * fade);
    });
  }

  // ② 내려찍기: SLAM 순간부터 판정 반타원 전체로 검은 연기가 밀려 나간다
  const ts = t - SLAM;
  if (ts >= 0) {
    const g = clamp(ts / 0.34), e = ease.outCubic(g);            // 퍼지는 진행도
    const fade = 1 - smooth(0.55, 1.3, ts);                       // 오래 머물다 흩어짐
    // 바닥 충격 고리: 납작한 타원이 앞으로 두 번 번진다
    for (let ring = 0; ring < 2; ring++) {
      const tr = clamp((ts - ring * 0.1) / 0.36), er = ease.outCubic(tr);
      if (tr <= 0 || tr >= 1) continue;
      const rxr = RX * er, ryr = 10 + 18 * er, a = (1 - tr) * 0.9;
      for (let k = 0; k < 90; k++) {
        const th = (k / 90) * Math.PI - Math.PI / 2;
        const x = Math.cos(th) * rxr, y = Math.sin(th) * ryr * 0.35 - 1;
        if (a > 0.04) { p.px(Math.round(x), Math.round(y), C[2], a); p.px(Math.round(x), Math.round(y) + 1, C[0], a); }
      }
    }
    // 균열: 충격 지점에서 앞쪽 바닥으로 뻗는 검은 금
    each(9, S * 7 + 3, (r, i) => {
      const len = r.range(70, RX * 0.95) * e, ang = r.range(-0.25, 0.25), x0 = CX * 0.6;
      let x = x0, y = 0;
      const steps = Math.floor(len / 6);
      for (let s = 0; s < steps; s++) {
        x += 6; y += r.range(-1.2, 1.2) + ang * 3;
        if (fade > 0.04) p.px(Math.round(x), Math.round(Math.max(-2, Math.min(3, y * 0.3))), C[0], fade);
      }
    });
    // 돔의 몸통: 겹치는 검은 덩어리가 반타원 안을 채운다 (아래는 짙고 위로 갈수록 옅다)
    each(340, S * 11 + 4, (r, i) => {
      const th = r.range(-Math.PI / 2, Math.PI / 2), depth = Math.sqrt(r.next()) , born = r.range(0, 0.06);
      const a = ts - born; if (a < 0) return;
      const spread = ease.outCubic(clamp(a / 0.34));
      const px = Math.cos(th) * RX * depth * spread + 20, py = -Math.abs(Math.sin(th)) * RY * depth * spread;
      const k = clamp(a / 1.4);
      const x = px + k * 18 * Math.cos(th), y = py - k * r.range(6, 34);
      const sz = r.range(12, 26) * (0.5 + 0.7 * smooth(0, 0.5, k)) * (0.7 + 0.5 * depth);
      const lowness = 1 - clamp(-y / RY);
      const env = smooth(0, 0.08, a) * fade * (1 - smooth(0.55, 1, k) * 0.6);
      disc(p, x, y, sz, C[r.next() < 0.7 ? 0 : 1], (0.42 + 0.5 * lowness) * env * (0.6 + 0.4 * depth));
      if (y < -30 && r.next() < 0.3) disc(p, x - sz * 0.2, y - sz * 0.4, sz * 0.4, C[3], 0.22 * env);
    });
    // 돔의 앞면(가장자리): 짙고 크게 말려 올라가는 테두리 — 범위 끝이 한눈에 보이게
    each(46, S * 13 + 5, (r, i) => {
      const th = (i / 45) * Math.PI - Math.PI / 2 + r.range(-0.03, 0.03), a = ts - r.range(0, 0.05);
      if (a < 0) return;
      const spread = ease.outCubic(clamp(a / 0.34)), k = clamp(a / 1.5);
      const x = Math.cos(th) * RX * spread * 0.98 + 20, y = -Math.abs(Math.sin(th)) * RY * spread * 0.98 - k * r.range(4, 22);
      const sz = r.range(9, 22) * (0.6 + 0.5 * smooth(0, 0.4, k));
      const env = smooth(0, 0.06, a) * fade;
      disc(p, x, y, sz, C[0], 0.7 * env);
      disc(p, x + sz * 0.1, y + sz * 0.1, sz * 0.7, C[1], 0.5 * env);
      if (r.next() < 0.45) disc(p, x - sz * 0.25, y - sz * 0.45, sz * 0.4, C[3], 0.3 * env);
    });
    // 위로 솟는 연기 기둥 몇 줄기
    each(16, S * 17 + 6, (r) => {
      const born = r.range(0.04, 0.4), a = ts - born; if (a < 0) return;
      const k = clamp(a / r.range(0.8, 1.2)); if (k >= 1) return;
      const x = r.range(40, RX * 0.9), y = -6 - k * r.range(60, 130);
      disc(p, x, y, r.range(9, 16) * (0.7 + k), C[1], 0.6 * smooth(0, 0.15, k) * (1 - smooth(0.4, 1, k)));
    });
  }
}
function lerp(a, b, t) { return a + (b - a) * t; }
