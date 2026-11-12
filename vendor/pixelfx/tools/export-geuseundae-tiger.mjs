// 푸른 호랑이 기공파 시트를 시안 폴더로 내보낸다(게임 에셋 폴더에는 쓰지 않는다).
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { loadEffect, renderFrames, spriteSheet, contactSheet, save } from "./lib/fxlib.mjs";

const out = new URL("../../../docs/mockups/tiger-fang/", import.meta.url).pathname;
mkdirSync(out, { recursive: true });
for (const [id, name] of [["geuseundae/tiger-wave", "tiger-spirit-wave"], ["geuseundae/tiger-wave-mist", "tiger-spirit-wave-mist"]]) {
  const effect = await loadEffect(id);
  const rendered = renderFrames(effect, { actor: false });
  const sheet = spriteSheet(effect, rendered, name);
  save(join(out, name + ".png"), sheet.png);
  save(join(out, name + ".json"), JSON.stringify(sheet.json, null, 2));
  save(join(out, name + "-review.png"), contactSheet(effect, rendered, { max: 12, zoom: 3 }));
  console.log("exported", name, rendered.frames.length, "frames", rendered.w + "x" + rendered.h);
}
