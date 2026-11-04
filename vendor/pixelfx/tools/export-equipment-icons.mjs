import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { loadEffect, renderFrames, canvas, save, upscale } from './lib/fxlib.mjs';
import { encodePNG } from './lib/png.mjs';

const items = [
 ['hair','손각시의 머리카락',1],['pin','녹슨 비녀',2],['ribbon','끊어진 댕기',2],['mirror','피 묻은 족두리',3],
 ['eggshell','깨진 달걀껍데기',1],['blank_face','민얼굴',2],['gaze','텅 빈 응시',3],['nails','몽달의 손톱',1],
 ['goose','부러진 나무기러기',2],['mongdal_rush','몽달의 한',3],['claws','범의 발톱',2],['call','창귀의 부름',2],
 ['tiger_soul','홀린 넋',3],['tiger_fang','범의 송곳니',4],['water_bucket','젖은 바가지',1],['water_hand','물귀신의 손',2],
 ['well_bucket','우물 두레박',3],['fox_bead','여우구슬',2],['tails','구미호의 꼬리',3],['fox_fire','여우불',1],
 ['fox_mirror','둔갑 거울',4],['club','도깨비방망이',2],['goblin_fire','도깨비불',1],['broom','낡은 빗자루',2],
 ['belt','씨름 샅바',3],['tooth','아귀의 이빨',1],['tongue','아귀의 혀',2],['shadow','어둑한 그림자',3],
 ['voice','흉내 내는 목소리',3],['plague','역병 항아리',2],['whistle','가는 휘파람',3],['mouth','거구귀의 입',4],
 ['fist','두억시니의 주먹',4],['wig','헝클어진 가발',1],['duo_head','두??니??의 XX??',4],['bent_leg','꺾인 다리',1],
 ['mongdal_legs','몽달의 다리',2],['wet_shoes','젖은 꽃신',2],['single_shoe','한쪽 꽃신',1],['stomach','아귀의 위장',3],
 ['duo_curse','??의 짙은 저주',3],
];
const families={
 songaksi:['#0b0d12','#313940','#738080','#b9c2b5','#f1edd5'],
 egg:['#171719','#4c4b47','#8d897c','#d3cbb3','#fff9df'],
 mongdal:['#160f13','#523443','#8d5c72','#d49cb2','#ffe7dc'],
 changgui:['#151417','#4d3e37','#846c50','#c7a86d','#fff0b2'],
 water:['#0d171b','#274a55','#4f8997','#91c1c7','#e5fbf5'],
 fox:['#17101a','#61384f','#a85f73','#ed9b91','#fff0ce'],
 goblin:['#10171a','#2c5150','#5e8980','#b2c8a4','#eef0c9'],
 agwi:['#1a1113','#56333a','#9a6261','#d6aa8f','#fff0c8'],
 shadow:['#090a12','#252339','#504a70','#8d84a8','#e1d9ef'],
 plague:['#15160f','#4b5129','#78834b','#b5bd72','#eff0bd'],
 duo:['#070910','#1c2030','#3f465d','#7d879f','#e4e9f1'],
 neutral:['#101418','#36434a','#72817f','#bbc5b7','#f1f0d5'],
};
const familyOf={
 hair:'songaksi',pin:'songaksi',ribbon:'songaksi',mirror:'songaksi',wig:'songaksi',
 eggshell:'egg',blank_face:'egg',gaze:'egg',nails:'mongdal',goose:'mongdal',mongdal_rush:'mongdal',mongdal_legs:'mongdal',
 claws:'changgui',call:'changgui',tiger_soul:'changgui',tiger_fang:'changgui',water_bucket:'water',water_hand:'water',well_bucket:'water',wet_shoes:'water',
 fox_bead:'fox',tails:'fox',fox_fire:'fox',fox_mirror:'fox',club:'goblin',goblin_fire:'goblin',broom:'goblin',belt:'goblin',
 tooth:'agwi',tongue:'agwi',mouth:'agwi',stomach:'agwi',shadow:'shadow',voice:'changgui',plague:'plague',whistle:'shadow',
 fist:'duo',duo_head:'duo',duo_curse:'duo',bent_leg:'neutral',single_shoe:'neutral'
};
const output=new URL('../../../godot/assets/equipment/icons/',import.meta.url).pathname;
mkdirSync(output,{recursive:true});
const fx=await loadEffect('geuseundae/equipment-icon');
const preview=canvas(7*176,6*192,[10,14,19,255]);
const songaksiPreview=canvas(4*176,192,[10,14,19,255]);
const songaksiUiScale=canvas(360,88,[10,14,19,255]);
const grade=[[184,193,181,255],[93,157,179,255],[172,113,194,255],[218,179,91,255]];
const manifest={};
for(let i=0;i<items.length;i++){
 const [id,name,tier]=items[i];
 const palette=families[familyOf[id]??'neutral'];
 const r=renderFrames(fx,{actor:false,bg:'none',options:{item:id,tier,palette,seed:1103+i}});
 const frame=r.frames[3].clear;
 save(join(output,id+'.png'),encodePNG(r.w,r.h,frame));
 manifest[id]={name,tier,path:`res://assets/equipment/icons/${id}.png`};
 const x=(i%7)*176,y=Math.floor(i/7)*192;
 preview.rect(x+4,y+4,168,168,[20,27,34,255]);
 preview.rect(x+4,y+4,168,4,grade[tier-1]);preview.rect(x+4,y+168,168,4,grade[tier-1]);
 preview.rect(x+4,y+4,4,168,grade[tier-1]);preview.rect(x+168,y+4,4,168,grade[tier-1]);
 preview.paste(upscale(r.frames[3].color,r.w,r.h,4),168,168,x+4,y+4);
 preview.text(id,x+7,y+176,2,[205,211,204]);
 if(i<4){
  const sx=i*176;
  songaksiPreview.rect(sx+4,4,168,168,[20,27,34,255]);
  songaksiPreview.rect(sx+4,4,168,4,grade[tier-1]);songaksiPreview.rect(sx+4,168,168,4,grade[tier-1]);
  songaksiPreview.rect(sx+4,4,4,168,grade[tier-1]);songaksiPreview.rect(sx+168,4,4,168,grade[tier-1]);
  songaksiPreview.paste(upscale(r.frames[3].color,r.w,r.h,4),168,168,sx+4,4);
  songaksiPreview.text(id,sx+7,176,2,[205,211,204]);
  const ux=12+i*86,uy=10;
  songaksiUiScale.rect(ux-1,uy-1,44,44,grade[tier-1]);
  songaksiUiScale.rect(ux,uy,42,42,[20,27,34,255]);
  songaksiUiScale.paste(r.frames[3].color,r.w,r.h,ux,uy);
  songaksiUiScale.text(id,ux,58,2,[205,211,204]);
 }
}
writeFileSync(join(output,'manifest.json'),JSON.stringify(manifest,null,2));
save(new URL('../../../docs/equipment-icons-preview.png',import.meta.url).pathname,preview.png());
save(new URL('../../../docs/songaksi-equipment-icons-preview.png',import.meta.url).pathname,songaksiPreview.png());
save(new URL('../../../docs/songaksi-equipment-ui-scale.png',import.meta.url).pathname,songaksiUiScale.png());
console.log(`${items.length} equipment icons exported`);
