import { fit, clamp, smooth, seg, ease, rand, TAU } from "../../core/index.js";

export const meta = {
  name: "Warden forced souls",
  desc: "Three anguished captive ghosts crawl from a wooden sealing rack, resist, then are crushed into the warden's red-brown shamanic grip.",
  tags: ["geuseundae", "ghost", "soul", "bind", "shaman", "boss", "cast"],
  size: [144, 136], origin: [72, 120], duration: 1.65, loop: false, fps: 24, bg: "ground",
  options: {
    palette: ["#090d14", "#17202b", "#293746", "#45596a", "#6f8491", "#a9bbc0", "#d8e2df"],
    force: ["#160b0e", "#35151a", "#62262b", "#963f43", "#c66b63", "#e2a58a"],
    seed: 31,
  },
};

const SOULS = [
  { x: -26, y: -55, d: 0.00, side: -1 },
  { x: -8,  y: -76, d: 0.10, side: 1 },
  { x: 10,  y: -58, d: 0.18, side: -1 },
];

function ghost(p, C, F, s, t, o) {
  const rise = ease.outCubic(clamp(seg(t, s.d, s.d + .56)));
  const seize = ease.inOutCubic(clamp(seg(t, .62 + s.d * .25, 1.10)));
  const fade = 1 - smooth(1.24, 1.63, t);
  const resist = Math.sin((t * 12 + s.x) * s.side) * (1 - seize) * 2.5;
  const sx = s.x + resist + (32 - s.x) * seize;
  const sy = s.y + 20 * (1 - rise) + (-41 - s.y) * seize;
  const squash = 1 - seize * .72;
  const a = smooth(s.d, s.d + .12, t) * fade;
  if (a <= 0) return;

  // Torn smoke tail stays tethered to the rack until the spirit is seized.
  for (let k = 0; k < 4; k++) {
    const u = k / 3, tx = sx - resist * u - s.side * Math.sin(t * 8 + k) * (2 + u * 2);
    const ty = sy + 8 + u * (15 + seize * 5);
    p.disc(tx, ty, (4.2 - u * 1.5) * squash, C[2 + (k < 2 ? 1 : 0)], a * (.3 - u * .045));
  }

  // Anguished head: dark open mouth, pin eyes and a stretched cheek rim.
  p.disc(sx, sy, 9 * squash, C[2], a * .34);
  p.ellipse(sx, sy, 6.7 * squash, 8, C[4], a * .96);
  p.arc(sx - s.side, sy, 6.7 * squash, 1.5, -2.5, 1.7, C[6], a * .9);
  p.px(sx - 2 * squash, sy - 1, C[0], a);
  p.px(sx + 2 * squash, sy - 1, C[0], a);
  p.ellipse(sx, sy + 3.5, 1.6 * squash, 2.8, C[0], a);

  // Both arms reach away from the forced destination before folding inward.
  const reach = (1 - seize) * (7 + Math.sin(t * 9 + s.x) * 2);
  for (const hand of [-1, 1]) {
    const hx = sx + hand * reach * squash, hy = sy + 5 + hand * s.side * 2;
    p.polyline([[sx + hand * 3 * squash, sy + 4], [hx, hy], [hx + hand * 2, hy - 2]], C[5], a * .84);
    p.px(hx + hand * 2, hy - 3, C[6], a);
  }
  p.glow(sx, sy, 14, C[4], .13 * a);

  // Red-brown bindings become visible only once the warden forces control.
  if (seize > .05) {
    p.arc(sx, sy + 1, 8 * squash, 1.5, -.4, 2.8, F[3], seize * fade);
    p.polyline([[sx, sy + 4], [sx + (32 - sx) * .35, sy + 1 + s.side * 3], [sx + (32 - sx) * .7, -43 - s.side * 2], [32, -41]], F[2], seize * fade * .72);
    p.px(sx + (32 - sx) * .7, -43 - s.side * 2, F[4], seize * fade);
    p.glow(sx, sy, 10, F[3], .08 * seize * fade);
  }
}

export function draw(p, t, o) {
  if (t >= meta.duration) return;
  const C = fit(o.palette, 7), F = fit(o.force, 6);
  const fade = 1 - smooth(1.38, 1.65, t);

  // Cracks and iron rings on the sealing rack: a restrained origin cue, not a magic circle.
  const rack = smooth(0, .18, t) * (1 - smooth(.72, 1.12, t));
  for (const x of [-30, -12, 7]) {
    p.line(x, -42, x + Math.sin(x) * 3, -84, C[1], rack * .8);
    p.px(x, -67, C[5], rack);
    for (let k = 0; k < 3; k++) {
      const drift = Math.sin(t * 5 + x + k) * 3;
      p.disc(x + drift, -48 - k * 13 - t * 5, 4 + k, C[2 + (k === 0 ? 1 : 0)], rack * (.18 - k * .025));
    }
  }
  p.glow(-10, -63, 34, C[3], .11 * rack);

  for (const s of SOULS) ghost(p, C, F, s, t, o);

  const bind = ease.outQuart(clamp(seg(t, .72, 1.15))) * fade;
  if (bind > 0) {
    // Jagged stolen power is compact and dirty, centred near the warden's chain hand.
    const cx = 32, cy = -41;
    for (let i = 0; i < 5; i++) {
      const a = i * TAU / 5 + t * (1.6 + i * .08);
      const r = 7 + 5 * rand(i, o.seed);
      p.line(cx + Math.cos(a) * 3, cy + Math.sin(a) * 3, cx + Math.cos(a) * r, cy + Math.sin(a) * r, i % 2 ? C[5] : F[4], bind * .8);
    }
    p.polyline([[-14, -62], [2, -55], [13, -48], [cx, cy]], F[2], bind * .72);
    p.ring(cx, cy, 5 + bind * 4, F[3], bind * .9);
    p.disc(cx, cy, 4, F[4], bind * .35);
    p.px(cx, cy, C[6], bind);
    p.glow(cx, cy, 24, F[3], .22 * bind);
  }
}
