import {writeFileSync,mkdirSync,copyFileSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {loadEffect,renderFrames,spriteSheet,contactSheet,save} from './lib/fxlib.mjs';
const output=new URL('../../../godot/assets/vfx/',import.meta.url).pathname;mkdirSync(output,{recursive:true});
const fx=await loadEffect('geuseundae/equipment-strike');
const palettes=[['#28343a','#56706e','#849e94','#c9d8bb','#eef1d8'],['#202d40','#3a657a','#70aaa8','#b3e1cf','#f5ffec'],['#29223d','#66517b','#ac80bb','#e6bbda','#fff4e3'],['#29202e','#725239','#c18f54','#f3d294','#fff8dd']];
const manifest={};
for(let tier=1;tier<=4;tier++)for(const mode of ['slash','bloom','impact','seal','orb',...(tier===4?['fist','tiger']:[])]){
 const name=`${mode}-${tier}`,r=renderFrames(fx,{actor:false,options:{tier,mode,palette:palettes[tier-1],seed:1103}}),s=spriteSheet(fx,r,name);
 save(join(output,name+'.png'),s.png);save(join(output,name+'.json'),JSON.stringify(s.json));
 manifest[name]={...s.json.meta.pixelfx,path:`res://assets/vfx/${name}.png`};
 if(mode==='slash'||mode==='fist')save(join(output,name+'-review.png'),contactSheet(fx,r,{max:8,zoom:2}));
}
writeFileSync(join(output,'manifest.json'),JSON.stringify(manifest,null,2));
copyFileSync(new URL('../LICENSE',import.meta.url),join(output,'PIXELFX-LICENSE.txt'));
console.log(Object.keys(manifest).length+' transparent sprite sheets exported');
// Use the actual site's layered library recipes instead of simplified lookalikes.
async function library(key,id,palette,start=0,span=.72,anchor=[0,0],extra={}){
 const original=await loadEffect(id), source=original.mod;
 const mod={meta:{...original.meta,duration:.72,fps:25,loop:false,options:{...original.meta.options,...extra,...(palette?{palette}:{})}},create(o){
  let t=0;const sim=source.create?source.create(o):null;
  if(sim&&start>0)for(let u=0;u<start;u+=1/120)sim.update(Math.min(1/120,start-u));
  return {update(dt){t+=dt;if(sim)sim.update(dt*span/.72);},draw(p){if(t>=.72)return;if(sim)sim.draw(p);else source.draw(p,start+t*span/.72,o);},drawBack(p){if(t>=.72)return;if(sim?.drawBack)sim.drawBack(p);else if(source.drawBack)source.drawBack(p,start+t*span/.72,o);}};
 }};
 const adapted={id,mod,meta:mod.meta},r=renderFrames(adapted,{actor:false});
 // End with a brief alpha fade, preserving solid shapes while alive.
 for(let i=15;i<r.frames.length;i++){const alpha=(18-i)/3;for(let j=3;j<r.frames[i].clear.length;j+=4)r.frames[i].clear[j]*=Math.max(0,alpha);}
 const s=spriteSheet(adapted,r,key);save(join(output,key+'.png'),s.png);save(join(output,key+'.json'),JSON.stringify(s.json));
 manifest[key]={...s.json.meta.pixelfx,path:`res://assets/vfx/${key}.png`,source:id,anchor};
 if(key==='fist-4')save(join(output,'fist-4-review.png'),contactSheet(adapted,r,{max:9,zoom:2}));
}
async function dedicated(key,id){
 const effect=await loadEffect(id),r=renderFrames(effect,{actor:false}),s=spriteSheet(effect,r,key);
 save(join(output,key+'.png'),s.png);save(join(output,key+'.json'),JSON.stringify(s.json));
 manifest[key]={...s.json.meta.pixelfx,path:`res://assets/vfx/${key}.png`,source:id};
 save(join(output,key+'-review.png'),contactSheet(effect,r,{max:15,zoom:2}));
}
const pale=['#18202b','#35424c','#5c727a','#9bb2b1','#c3d2c2','#e0e5cf','#f1f1db'];
const ink=['#080910','#11131e','#222637','#3f465d','#656d8b','#959fb9','#c6d0e4','#edf0fa'];
await library('slash-1','melee/sword-slash',pale,0,.72);
await library('slash-2','melee/double-slash',pale,0,.8);
await library('slash-3','melee/scythe-reap',ink,.18,1.3);
await library('slash-4','melee/heavy-cleave',ink,.35,1.25);
await library('impact-1','impacts/hit-spark',pale,0,.5,[0,-20]);
await library('impact-2','impacts/blunt-hit',pale,0,.8,[0,-24]);
await library('impact-3','impacts/crit-hit',null,0,.85,[0,-26]);
await library('impact-4','impacts/crit-hit',ink,0,.85,[0,-26]);
await library('bloom-3','shadow/dark-explosion',null,.48,1.85,[0,-54]);
await library('bloom-4','shadow/dark-explosion',ink,.48,1.85,[0,-54]);
await library('seal-3','shadow/hex-sigil',null,1.4,1.6,[0,-50]);
await library('seal-4','shadow/hex-sigil',ink,1.4,1.6,[0,-50]);
await library('fist-4','geuseundae/shadow-fist',null,0,.72);
await library('beam-3','arcane/arcane-beam',null,0,1.2,[15,-24]);
await dedicated('dash-2','geuseundae/shadow-dash');
writeFileSync(join(output,'manifest.json'),JSON.stringify(manifest,null,2));
console.log('13 profiles now use the original layered recipes, dedicated shadow fist and ghost dash');
