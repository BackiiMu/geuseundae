// Banded after-images and heel dust are informed by Sprite Fusion's open-source movement dash
// (https://www.spritefusion.com/pixel-art-vfx/movement), MIT License, Copyright (c) 2026 Hugo Duprez.
import { fit, clamp, smooth, ease, TAU } from '../../core/index.js';

export const meta = {
  name: 'Ghost dash',
  desc: 'A short Korean-horror dash: ink-dark hair ribbons tear backward, cold speed lines snap past, heel dust rolls out and the trail pinches shut.',
  tags: ['shadow', 'dash', 'speed', 'hair', 'movement', 'directional', 'one-shot'],
  size: [168, 96],
  origin: [112, 72],
  duration: 0.44,
  fps: 30,
  loop: false,
  bg: 'ground',
  options: {
    palette: ['#080b12', '#111925', '#1c2b37', '#31505a', '#548083', '#91b8aa', '#dce5cc'],
    seed: 1103,
  },
};

const sat = (v) => clamp(v, 0, 1);
const window = (t, a, b, c, d) => smooth(a, b, t) * (1 - smooth(c, d, t));

export function drawBack(p, t, o) {
  if (t <= 0 || t >= meta.duration) return;
  const C = fit(o.palette, 7);
  const release = ease.outExpo(sat(t / 0.11));
  const fade = 1 - smooth(0.21, meta.duration, t);
  const tail = -14 - release * 72;

  // A torn ink mass gives the trail one readable silhouette before the fine strands split off.
  const mass = window(t, 0.005, 0.035, 0.16, 0.31) * fade;
  p.poly([[4, -57], [tail * 0.58, -54], [tail, -43], [tail * 0.72, -31], [2, -36]], C[0], mass * 0.78);
  p.poly([[-2, -52], [tail * 0.52, -49], [tail * 0.83, -42], [-1, -39]], C[2], mass * 0.42);

  // Three hair-like ribbons: broad at the body, torn and tapered behind.
  for (let strand = 0; strand < 3; strand++) {
    const y = -46 + strand * 15;
    const sway = Math.sin(t * 28 + strand * 1.9) * (2 + strand);
    const points = [];
    for (let n = 0; n < 7; n++) {
      const u = n / 6;
      points.push([tail * u, y + sway * u + Math.sin(u * 8 + strand) * (1 + u * 3)]);
    }
    p.polyline(points, strand === 1 ? C[3] : C[2 + strand], fade * (0.9 - strand * 0.12));
    p.polyline(points.map(([x, py]) => [x - 2, py + 2]), C[0], fade * 0.75);
    const tip = points[points.length - 1];
    p.dot(tip[0] - 2, tip[1], C[5], fade * 0.7);
  }

  // Low rolling dust stays readable against the dark floor.
  const dustLife = window(t, 0.02, 0.07, 0.24, 0.42);
  for (let i = 0; i < 7; i++) {
    const u = i / 6;
    const age = sat((t - i * 0.012) / 0.34);
    const x = -10 - u * 52 - age * (16 + i * 2);
    const y = -1 - Math.sin(u * TAU) * 2 - age * (3 + i % 3);
    const r = 2.2 + age * 3.4 + (i % 2);
    p.disc(x, y, r, i % 3 === 0 ? C[4] : C[2], dustLife * (1 - age * 0.55) * 0.45);
    p.disc(x - 1, y - 1, r * 0.5, C[5], dustLife * (1 - age) * 0.22);
  }
  p.glow(-28, -24, 34, C[3], 0.2 * fade);
}

export function draw(p, t, o) {
  if (t <= 0 || t >= meta.duration) return;
  const C = fit(o.palette, 7);
  const release = ease.outExpo(sat(t / 0.1));
  const flash = window(t, 0, 0.018, 0.055, 0.11);
  const fade = 1 - smooth(0.18, meta.duration, t);

  // The air folds around the leading edge for two frames, then opens behind it.
  const fold = window(t, 0.005, 0.025, 0.09, 0.19);
  p.arc(1, -31, 25, 2.2, -1.2, 1.12, C[5], fold);
  p.arc(-3, -31, 31, 1.2, -0.78, 0.72, C[3], fold * 0.75);
  p.glow(5, -31, 26, C[4], fold * 0.18);

  // A white one-frame snap at the leading shoulder, then a cool leading edge.
  if (flash > 0) {
    p.beam(-4, -49, 22, -39, 2.2, C[6], flash);
    p.glowLine(-8, -50, 25, -38, 12, C[5], flash * 0.5);
  }

  // Speed lines arrive quickly and break into dotted tails instead of a flat triangle.
  for (let i = 0; i < 6; i++) {
    const phase = sat((t - i * 0.006) / 0.13);
    if (phase <= 0) continue;
    const y = -58 + i * 11 + Math.sin(i * 2.1) * 2;
    const head = 24 - release * (23 + (i % 4) * 10);
    const len = 21 + (i % 3) * 9;
    p.line(head - len, y, head, y, i < 2 ? C[5] : C[4], fade * (0.95 - i * 0.06));
    p.dot(head + 2, y, i % 3 === 0 ? C[6] : C[5], fade);
    for (let d = 5; d < len; d += 6) p.dot(head - len - d, y, C[3], fade * (1 - d / (len + 8)));
  }

  // The floor seam pinches closed behind the dash.
  const seam = window(t, 0.01, 0.04, 0.17, 0.36);
  p.line(-88 * release, 0, 13, 0, C[5], seam);
  p.line(-72 * release, 1, -8, 1, C[1], seam * 0.8);
  p.glowLine(-62 * release, 0, 10, 0, 7, C[4], seam * 0.28);
}
