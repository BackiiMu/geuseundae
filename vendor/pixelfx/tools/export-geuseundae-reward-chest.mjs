import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { loadEffect, renderFrames, spriteSheet, contactSheet, save } from "./lib/fxlib.mjs";

const output = new URL("../../../godot/assets/vfx/pickups/", import.meta.url).pathname;
const review = new URL("../../../docs/mockups/reward-chest/", import.meta.url).pathname;
mkdirSync(output, { recursive: true });
mkdirSync(review, { recursive: true });
const effect = await loadEffect("geuseundae/reward-chest");
const rendered = renderFrames(effect, { actor: false });
const sheet = spriteSheet(effect, rendered, "reward-chest");
save(join(output, "reward-chest.png"), sheet.png);
save(join(output, "reward-chest.json"), JSON.stringify(sheet.json, null, 2));
save(join(review, "reward-chest-review.png"), contactSheet(effect, rendered, { max: 16, zoom: 3 }));
console.log("Exported sealed reward chest PNG, JSON and review sheet");
