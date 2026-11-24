import {mkdirSync} from 'node:fs';
import {join} from 'node:path';
import {loadEffect,renderFrames,spriteSheet,contactSheet,save} from './lib/fxlib.mjs';

const root=new URL('../../../',import.meta.url).pathname;
const review=join(root,'docs/mockups/chapter1-boss-vfx');
const game=join(root,'godot/assets/monster_vfx');
mkdirSync(review,{recursive:true});mkdirSync(game,{recursive:true});
const effects=[
 ['geuseundae/ch1-boss-seal-sweep','boss-seal-sweep','captain-sweep'],
 ['geuseundae/ch1-boss-seal-cleave','boss-seal-cleave','captain-cleave'],
 ['geuseundae/ch1-boss-seal-charge','boss-seal-charge','captain-charge-fx'],
];
for(const [id,previewName,gameName] of effects){
 const effect=await loadEffect(id),frames=renderFrames(effect,{actor:false}),sheet=spriteSheet(effect,frames,previewName);
 save(join(review,previewName+'.png'),sheet.png);save(join(review,previewName+'.json'),JSON.stringify(sheet.json));
 save(join(review,previewName+'-review.png'),contactSheet(effect,frames,{max:14,zoom:2}));
 const gameSheet=spriteSheet(effect,frames,gameName);
 save(join(game,gameName+'.png'),gameSheet.png);save(join(game,gameName+'.json'),JSON.stringify(gameSheet.json));
}
console.log('Exported Chapter 1 boss VFX previews and game sheets');
