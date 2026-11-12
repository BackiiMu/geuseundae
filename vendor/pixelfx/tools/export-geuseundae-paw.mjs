// 장산범 앞발 발톱 초승달 시트를 시안 폴더로 내보낸다(게임 에셋 폴더에는 쓰지 않는다).
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { loadEffect, renderFrames, spriteSheet, contactSheet, save } from "./lib/fxlib.mjs";
const out = new URL("../../../docs/mockups/equipment/jangsan-paw/", import.meta.url).pathname;
mkdirSync(out, { recursive: true });
const effect = await loadEffect("geuseundae/paw-claws");
const rendered = renderFrames(effect, { actor: false });
const sheet = spriteSheet(effect, rendered, "paw-claws");
save(join(out, "paw-claws.png"), sheet.png);
save(join(out, "paw-claws.json"), JSON.stringify(sheet.json, null, 2));
save(join(out, "paw-claws-review.png"), contactSheet(effect, rendered, { max: 16, zoom: 3 }));
console.log("exported", rendered.frames.length, "frames", rendered.w + "x" + rendered.h);
