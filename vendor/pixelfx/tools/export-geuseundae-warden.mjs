import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { loadEffect, renderFrames, spriteSheet, contactSheet, save } from "./lib/fxlib.mjs";

const output = new URL("../../../godot/assets/monster_vfx/", import.meta.url).pathname;
const review = new URL("../../../docs/mockups/chapter3/soul-warden/", import.meta.url).pathname;
mkdirSync(output, { recursive: true });
mkdirSync(review, { recursive: true });
const effect = await loadEffect("geuseundae/warden-forced-souls");
const rendered = renderFrames(effect, { actor: false });
const sheet = spriteSheet(effect, rendered, "warden-forced-souls");
save(join(output, "warden-forced-souls.png"), sheet.png);
save(join(output, "warden-forced-souls.json"), JSON.stringify(sheet.json, null, 2));
save(join(review, "warden-forced-souls-review.png"), contactSheet(effect, rendered, { max: 16, zoom: 3 }));
console.log("Exported Soul Warden forced-souls sheet, JSON and review");
