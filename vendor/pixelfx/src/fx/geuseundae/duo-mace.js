// 두억시니 세트 완성 주먹: 검은 연기에 둘러싸인 거대한 쇠 철퇴를 머리 위에서 앞으로 휘둘러 바닥에 내리찍는다.
// 연기는 둥근 덩어리가 아니라 노이즈로 찢어지는 연기 질감이고, 철퇴 둘레를 감싸며 휘두른 자리에 꼬리를 끌고,
// 내려찍은 뒤에는 앞쪽 범위 끝까지 바닥을 따라 밀려 나간다. 반짝임·빛 번짐은 쓰지 않는다.
import { fit, clamp, smooth, ease, fbm, TAU } from "../../core/index.js";

export const meta = {
  name: "Duo mace",
  desc: "A giant spiked iron mace wreathed in black smoke is raised, swung down in an arc and slammed into the floor; torn smoke trails the swing and rolls out over the whole reach.",
  tags: ["geuseundae", "mace", "smoke", "melee", "slam", "one-shot"],
  size: [480, 480],
  origin: [90, 286],
  duration: 1.7,
  loop: false,
  fps: 20,
  bg: "ground",
  options: {
    palette: ["#0a0a12", "#14141e", "#21212f", "#32323f", "#474758", "#62627a"],
    iron: ["#030304", "#030304", "#030304", "#030304", "#030304", "#030304"],
    reach: 340,
    seed: 31,
  },
};

const HAND = [8, -46], L = 190, HEAD_R = 36, SHAFT_W = 10;   // 자루 굵기(반폭) 10
const WIND = 0.3, SWING = 0.36;               // 치켜들기 → 180° 휘두르기(0.3~0.66초)
const A0 = -1.75, A1 = 1.39;                   // 시작: 위·뒤(그대로) → 끝: 아래(180° 휘두름), 라디안
const FLOOR_CLIP = 196;                        // 바닥 아래로도 철퇴와 연기를 끝까지 그린다 (180° 전부 보이게)
function angleAt(t) {
  if (t < WIND) return A0 + 0.05 * Math.sin(t * 40) * smooth(0.1, WIND, t);       // 치켜든 채 떨림
  const k = clamp((t - WIND) / SWING);
  return A0 + (A1 - A0) * ease.inCubic(k);
}
function headAt(t) { const a = angleAt(t); return [HAND[0] + Math.cos(a) * L, HAND[1] + Math.sin(a) * L]; }
// 철퇴 머리가 바닥(y=-8)에 닿는 순간: 이때부터 연기가 바닥을 따라 밀려 나간다
const CONTACT = (() => { for (let t = WIND; t < WIND + SWING; t += 0.005) if (headAt(t)[1] >= -8) return t; return WIND + SWING; })();

export function draw(p, t, o) {
  const C = fit(o.palette, 6), I = fit(o.iron, 6), R = o.reach, S = o.seed;
  const [hx, hy] = headAt(t), ang = angleAt(t);
  const slamT = CONTACT;   // (연기는 더 이상 바닥에서 따로 퍼지지 않는다)
  const fadeAll = 1 - smooth(1.1, 1.65, t);

  // ---- 연기 원천(가우시안 덩어리들): 합친 밀도에 노이즈를 곱해 찢어진 연기 모양을 만든다 ----
  const src = [];   // 월드 기준 연기(꼬리·바닥·기둥): [x, y, ax, ay, 세기]
  const aura = [];  // 철퇴를 따라다니는 연기(머리·자루 둘레): 노이즈도 철퇴와 같이 움직인다
  // 철퇴 둘레: 머리와 자루를 감싼다
  const wrap = smooth(0, 0.18, t) * fadeAll;
  const aY = hy;
  aura.push([hx, aY, 56, 50, 1.6 * wrap]);
  for (let i = 1; i <= 5; i++) {
    const u = i / 6, sx = HAND[0] + (hx - HAND[0]) * u, sy = HAND[1] + (hy - HAND[1]) * u;
    aura.push([sx, sy, 32, 30, 1.05 * wrap]);
  }
  // 철퇴에 끌려오는 연기 꼬리: 지나간 머리 위치에 남지 않고, 철퇴 쪽으로 계속 끌려 붙어 함께 움직인다
  for (let i = 1; i <= 10; i++) {
    const tt = t - i * 0.02; if (tt < WIND - 0.05) continue;
    const age = t - tt, [px, py] = headAt(Math.min(tt, WIND + SWING));
    const pull = 0.5 + 0.04 * i;                       // 오래된 꼬리일수록 철퇴 쪽으로 더 끌려옴
    const cx = px + (hx - px) * pull, cy = py + (aY - py) * pull - age * 14;
    const spread = 1 + age * 1.6;
    aura.push([cx, cy, 44 * spread, 38 * spread, 0.85 * (1 - smooth(0, 0.3, age)) * wrap]);
  }
  // 철퇴와 함께 180° 도는 연기 부채꼴: 손(회전 중심)에서 판정 반타원 끝까지, 철퇴가 지나온 각도만큼 뒤를 따라 채운다.
  // 연기 무늬도 회전 중심 기준으로 같이 돌아서, 연기 덩어리 자체가 철퇴와 함께 180° 움직인다.
  const ellR = (a2) => 1 / Math.sqrt((Math.cos(a2) / R) ** 2 + (Math.sin(a2) / (R * 0.5)) ** 2);   // 판정 반타원 둘레 반지름
  const fanOn = smooth(WIND - 0.06, WIND + 0.06, t) * fadeAll;
  if (fanOn > 0.02) {
    for (let j = 0; j < 16; j++) {
      const a2 = ang - j * 0.085, rr = ellR(a2) * 0.98, age = j / 15;
      for (const f of [0.34, 0.58, 0.82, 1.0]) {
        const r2 = rr * f * (0.92 + 0.08 * Math.sin(j * 1.7 + f * 5));
        const cx = HAND[0] + Math.cos(a2) * r2, cy = HAND[1] + Math.sin(a2) * r2;
        aura.push([cx, cy, 30 + 24 * f, 26 + 20 * f, 0.62 * (1 - 0.8 * age) * (0.55 + 0.45 * f) * fanOn]);
      }
    }
  }

  const smokePass = (list, k, am, ox, oy, rot) => {
    const cr = Math.cos(-(rot || 0)), sr = Math.sin(-(rot || 0));
    // 원천들의 영역 안에서만 계산한다
    let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9;
    for (const s of list) { if (s[4] <= 0.02) continue; x0 = Math.min(x0, s[0] - s[2] * 2.2); x1 = Math.max(x1, s[0] + s[2] * 2.2); y0 = Math.min(y0, s[1] - s[3] * 2.2); y1 = Math.max(y1, s[1] + s[3] * 2.2); }
    x0 = Math.max(-88, Math.floor(x0)); x1 = Math.min(388, Math.ceil(x1)); y0 = Math.max(-286, Math.floor(y0)); y1 = Math.min(194, Math.ceil(y1));
    for (let y = y0; y <= y1; y++) {
      for (let x = x0; x <= x1; x++) {
        let d = 0;
        for (const s of list) {
          if (s[4] <= 0.02) continue;
          const dx = (x - s[0]) / s[2], dy = (y - s[1]) / s[3], q = dx * dx + dy * dy;
          if (q < 4.8) d += s[4] * Math.exp(-q * 1.15);
        }
        if (d < 0.12) continue;
        // 찢어진 연기 모양: 흐르며 일렁이는 노이즈를 곱한다 (위로 말려 오르는 흐름)
        const ux = (x - ox) * cr - (y - oy) * sr, uy = (x - ox) * sr + (y - oy) * cr;   // 회전 중심 기준 좌표: 연기 무늬가 철퇴와 같이 돈다
        const n = fbm(ux * 0.04 + t * 0.35, uy * 0.046 - t * 0.5, S, 4) * 0.5 + 0.5;
        const v = d * (0.26 + 1.05 * n) * k;
        let c, a;
        if (v > 1.38) { c = C[0]; a = 0.94; }
        else if (v > 1.05) { c = C[1]; a = 0.82; }
        else if (v > 0.78) { c = C[2]; a = 0.66; }
        else if (v > 0.55) { c = C[3]; a = 0.46; }
        else if (v > 0.4) { c = C[4]; a = 0.28; }
        else continue;
        p.blend(x, y, c, a * am);
      }
    }
  };

  // 1) 뒤쪽 연기
  smokePass(aura, 1.0, 0.72, HAND[0], HAND[1], ang);

  // 2) 철퇴: 단색 검정 실루엣(자루 굵게, 가시 고정). 땅 아래로 파고든 부분은 보이지 않게 잘라낸다
  const maceA = Math.min(fadeAll, 1 - smooth(0.64, 0.96, t));   // 휘두른 뒤 연기 속으로 사라진다
  const K = I[0], w = SHAFT_W, ca = Math.cos(ang), sa = Math.sin(ang), base = 0.26;
  const spikes = [];
  for (let i = 0; i < 12; i++) { const a2 = base + (i / 12) * TAU, c = Math.cos(a2), s2 = Math.sin(a2); spikes.push([[hx + c * HEAD_R * 0.85 - s2 * 6, hy + s2 * HEAD_R * 0.85 + c * 6], [hx + c * (HEAD_R + 15), hy + s2 * (HEAD_R + 15)], [hx + c * HEAD_R * 0.85 + s2 * 6, hy + s2 * HEAD_R * 0.85 - c * 6]]); }
  const inTri = (x, y, T) => { const d = (a, b) => (x - b[0]) * (a[1] - b[1]) - (a[0] - b[0]) * (y - b[1]); const d1 = d(T[0], T[1]), d2 = d(T[1], T[2]), d3 = d(T[2], T[0]); return !((d1 < 0 || d2 < 0 || d3 < 0) && (d1 > 0 || d2 > 0 || d3 > 0)); };
  const minX = Math.floor(Math.min(HAND[0], hx) - HEAD_R - 24), maxX = Math.ceil(Math.max(HAND[0], hx) + HEAD_R + 24);
  const minY = Math.floor(Math.min(HAND[1], hy) - HEAD_R - 24), maxY = Math.min(FLOOR_CLIP, Math.ceil(Math.max(HAND[1], hy) + HEAD_R + 24));
  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      const dx = x + 0.5 - HAND[0], dy = y + 0.5 - HAND[1];
      const along = dx * ca + dy * sa, perp = -dx * sa + dy * ca;
      let hit = (along >= -8 && along <= L && Math.abs(perp) <= w) || (dx * dx + dy * dy <= (w + 3) * (w + 3)) || ((x + 0.5 - hx) ** 2 + (y + 0.5 - hy) ** 2 <= HEAD_R * HEAD_R);
      if (!hit && (x + 0.5 - hx) ** 2 + (y + 0.5 - hy) ** 2 <= (HEAD_R + 16) ** 2) for (const T of spikes) if (inTri(x + 0.5, y + 0.5, T)) { hit = true; break; }
      if (hit && maceA > 0.03) p.px(x, y, K, maceA);
    }
  }

  // 3) 앞쪽 연기: 철퇴 앞을 덮되 반투명이라 실루엣만 비친다
  smokePass(aura, 1.0, 0.5, HAND[0], HAND[1], ang);
}
