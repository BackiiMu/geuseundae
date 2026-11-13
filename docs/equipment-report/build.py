#!/usr/bin/env python3
"""장비 현황 리포트 생성기. 게임 코드·에셋·설계서를 읽어 index.html 한 장으로 만든다.
실행: python3 docs/equipment-report/build.py"""
import json, os, re
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
G = os.path.join(ROOT, 'godot')
REL = '../../godot/assets/'           # index.html 기준 에셋 상대경로
rd = lambda p: open(os.path.join(ROOT, p), encoding='utf-8').read()

db = rd('godot/scripts/equipment_db.gd')
icon_gd = rd('godot/scripts/item_icon.gd')
vfx_gd = rd('godot/scripts/pixel_vfx.gd')
cd_gd = rd('godot/scripts/combat_director.gd')
design = rd('geuseundae_equipment.md')

def const_dict(src, name):
    m = re.search(r'const ' + name + r'\s*=\s*\{(.*?)\}', src, re.S)
    return dict(re.findall(r'"([^"]+)"\s*:\s*"([^"]*)"', m.group(1))) if m else {}

PROVIDED_ITEMS = const_dict(icon_gd, 'PROVIDED_ITEMS')
GEAR2_ITEMS = const_dict(icon_gd, 'GEAR2_ITEMS')
GEAR3_ITEMS = const_dict(icon_gd, 'GEAR3_ITEMS')
PROVIDED_ATTACKS = const_dict(vfx_gd, 'PROVIDED_ATTACKS')
GEAR2_ATTACKS = const_dict(vfx_gd, 'GEAR2_ATTACKS')
GEAR3_ATTACKS = const_dict(vfx_gd, 'GEAR3_ATTACKS')
SIGNATURE_MELEE = const_dict(vfx_gd, 'SIGNATURE_MELEE')
PROVIDED_DROPS = const_dict(cd_gd, 'PROVIDED_DROPS')
GEAR2_DROPS = const_dict(cd_gd, 'GEAR2_DROPS')
# 아이콘 파일은 있지만 item_icon.gd에 연결되지 않은 gear3 아이콘(파일명으로 대응)
GEAR3_UNLINKED = {"tooth":"agwiTeeth","tongue":"agwiTongue","tiger_soul":"boundSoul","call":"changgwiBell","club":"dokkaebiClub",
  "water_hand":"drownedHand","fox_fire":"foxFire","mouth":"giantMouth","voice":"mimicVoice","mongdal_rush":"mongdalHan","nails":"mongdalNail",
  "shadow":"murkShadow","broom":"oldBroom"}

# ── DB 파싱
wsrc = db[db.index('static func weapons()'):db.index('static func items()')]
weapons = []
for m in re.finditer(r'\["(\w+)","([^"]+)","(\w+)","(\w+)",(\d+),([\d.]+),([\d.]+),(\d+),"(\w*)","(\w+)"\]', wsrc):
    i, n, slot, kind, tier, dmg, itv, rng, skill, st = m.groups()
    weapons.append(dict(id=i, name=n, slot=slot, kind=kind, tier=int(tier), damage=float(dmg), interval=float(itv), range=int(rng), skill=skill, set=st))
cool = const_dict(db.replace('.0', ''), 'x')  # placeholder
cm = re.search(r'skill_cooldown\(skill: String\)[^\n]*\n\treturn \{(.*?)\}\.get', db, re.S)
cooldowns = {k: float(v) for k, v in re.findall(r'"(\w+)":([\d.]+)', cm.group(1))}
dm = re.search(r'static func description\(id: String\) -> String:\n\treturn \{(.*?)\n\t\}\.get', db, re.S)
desc = dict(re.findall(r'"(\w+)":"([^"]*)"', dm.group(1)))
gm = re.search(r'for a in \[(.*?)\]:\n', db, re.S)
general = [dict(id=a, name=n, slot=s, tier=int(t), passive=p, set=('duo' if a.startswith('duo') else 'songaksi' if a == 'wig' else ''))
           for a, n, s, t, p in re.findall(r'\["(\w+)","([^"]+)","(\w+)",(\d+),"(\w+)"\]', gm.group(1))]
pm = re.search(r'passive","\w+"\}', db)
general_effect = {"hair_range":"머리카락 사거리 20% 증가","reach":"근접 사거리·투사체 크기 1.5배","speed":"이동속도 12% 증가","frenzy":"처치 후 3초간 이동·공격속도 15% 증가","wet_dash":"대시 후 둔화 물자국","landing":"착지 시 근처 적 밀치기","heal":"처치 시 HP 3 회복 (0.6초 간격)","dash_power":"대시 공격 피해 1.5배","critical_dagger":"치명타 확률 +100 · 치명타 대미지 +100"}
for g in general: g['effect'] = general_effect[g['passive']]
fm = re.search(r'"id":"fox_tail","name":"([^"]+)","slot":"(\w+)","tier":(\d+).*?"effect":"([^"]+)"', db)
general.append(dict(id='fox_tail', name=fm.group(1), slot=fm.group(2), tier=int(fm.group(3)), passive='fox_tail', set='fox', effect=fm.group(4)))
# 효과 코드가 실제로 있는지: 같은 passive 이름을 쓰는 곳 검색
allcode = ''.join(open(os.path.join(G, 'scripts', f), encoding='utf-8').read() for f in os.listdir(os.path.join(G, 'scripts')) if f.endswith('.gd'))
for g in general:
    g['codeUsed'] = (('has_passive("%s")' % g['passive']) in allcode) or (g['passive'] in ('reach', 'hair_range') and 'has_passive("%s")' % g['passive'] in allcode)

# ── 스프라이트 시트 해석
def sheet(rel_png):
    """rel_png: godot/assets 기준 경로(확장자 포함)"""
    base = rel_png[:-4]
    jp = os.path.join(G, 'assets', base + '.json')
    if not os.path.exists(jp): return None
    pf = json.load(open(jp, encoding='utf-8'))['meta']['pixelfx']
    return dict(png=REL + rel_png, frames=int(pf['frames']), fw=int(pf['frameSize'][0]), fh=int(pf['frameSize'][1]), cols=int(pf['columns']), fps=float(pf['fps']), loop=bool(pf.get('loop', False)), pivot=[float(pf['pivot'][0]), float(pf['pivot'][1])])
vm = json.load(open(os.path.join(G, 'assets/vfx/manifest.json'), encoding='utf-8'))
def vfx(key):
    v = vm[key]
    return dict(png=REL + 'vfx/' + key + '.png', frames=int(v['frames']), fw=int(v['frameSize'][0]), fh=int(v['frameSize'][1]), cols=int(v['columns']), fps=float(v['fps']), loop=False, pivot=[float(v['pivot'][0]), float(v['pivot'][1])])

def effects(w):
    i, t, kind = w['id'], w['tier'], w['kind']
    out = []
    def add(label, sh, note=''):
        if sh: out.append(dict(label=label, note=note, **sh))
    if i == 'jangsan_paw': add('공격', sheet('gear3/fx/jangsan-paw.png'), '전용')
    elif i in GEAR2_ATTACKS: add('공격·스킬', sheet('gear2/fx/%s.png' % GEAR2_ATTACKS[i]), '전용')
    elif i in GEAR3_ATTACKS: add('공격·스킬', sheet('gear3/fx/%s.png' % GEAR3_ATTACKS[i]), '전용')
    elif i == 'fist': add('공격', vfx('fist-4'), '전용(그림자 주먹)')
    elif i == 'tiger_fang': add('스킬 돌진', vfx('tiger-spirit'), '전용(푸른 호랑이)')
    elif i == 'gaze': add('광선', sheet('gear2/fx/hollow-gaze-beam.png'), '전용')
    elif i == 'eggshell': add('발사', sheet('gear2/fx/eggshell-cast.png'), '전용'); add('명중', sheet('gear2/fx/eggshell-hit.png'), '전용')
    elif i in PROVIDED_ATTACKS: add('공격', sheet('provided_vfx/attacks/%s.png' % PROVIDED_ATTACKS[i]), '전용')
    else:
        if kind == 'melee':
            sig = SIGNATURE_MELEE.get(i, 'slash')
            key = {'dash': 'dash-2', 'fist': 'fist-4', 'beam': 'beam-3'}.get(sig, '%s-%d' % (sig, t))
            add('공격', vfx(key), '공용(%s)' % sig)
        else:
            add('공격', vfx('impact-%d' % t), '공용(충격)')
    if i == 'mirror': add('명중', sheet('gear2/fx/jokduri-hit.png'), '전용')
    elif i not in ('eggshell',) and not any(e['label'] == '명중' for e in out): add('명중', vfx('impact-%d' % t), '공용')
    if w['skill']:
        sk = w['skill']
        if i in ('ribbon', 'blank_face', 'mirror'):
            if i == 'blank_face': add('스킬', sheet('gear2/fx/blank-face.png'), '전용')
            elif i == 'mirror': add('스킬', sheet('gear2/fx/jokduri-cast.png'), '전용')
        elif i not in GEAR3_ATTACKS and i not in GEAR2_ATTACKS and i not in ('tiger_fang', 'gaze'):
            add('스킬 시전', vfx('seal-%d' % (4 if sk == 'crush' else t)), '공용(문양)')
    return out

SIGMULT = {'dash': .78, 'fist': .9, 'seal': .8, 'bloom': .72, 'beam': .8, 'slash': 1.0}
def place_for(w, fx):
    """pixel_vfx.gd attack()의 배치 규칙. 발 기준(오른쪽 향함) dx,dy와 배율."""
    i, reach = w['id'], float(w['range'])
    if i == 'jangsan_paw': return dict(dx=-129, dy=63, size=3.0)
    if i in GEAR2_ATTACKS or i in GEAR3_ATTACKS or i in PROVIDED_ATTACKS:
        if i == 'water_hand': return dict(dx=reach * .5, dy=0, size=max(1.0, reach / 64.0))
        return dict(dx=0, dy=0, size=1.0)
    if i == 'eggshell': return dict(dx=0, dy=-28, size=1.0)
    if i == 'fist': return dict(dx=60, dy=0, size=1.35)
    if i in ('tiger_fang', 'gaze'): return dict(dx=reach * .3, dy=-28, size=1.0)
    if w['kind'] == 'melee':
        base = max(.55, min(1.6, reach / 105.0)); sig = SIGNATURE_MELEE.get(i, 'slash')
        return dict(dx=reach * .35, dy=-base * 20, size=base * SIGMULT.get(sig, 1.0))
    return None

def icon(i):
    if i in GEAR2_ITEMS: return dict(kind='gear2', src=REL + 'gear2/icons/%s.png' % GEAR2_ITEMS[i])
    if i in GEAR3_ITEMS: return dict(kind='gear3', src=REL + 'gear3/icons/%s.png' % GEAR3_ITEMS[i])
    if i in PROVIDED_ITEMS:
        sh = sheet('provided_vfx/items/%s_tier0.png' % PROVIDED_ITEMS[i])
        return dict(kind='provided', sheet=sh)
    return dict(kind='draft', src=REL + 'equipment/icons/%s.png' % i)

def drop(i):
    if i in GEAR2_DROPS: return sheet('gear2/drop/%s.png' % GEAR2_DROPS[i])
    if i in PROVIDED_DROPS: return sheet('provided_vfx/items/%s_tier0.png' % PROVIDED_DROPS[i])
    return None

SETS = {'songaksi':'손각시','egg':'달걀귀신','mongdal':'몽달귀신','changgui':'창귀','water':'물귀신','fox':'구미호','goblin':'도깨비','agwi':'아귀','shadow':'어둑시니',
        'tiger':'장산범(목소리)','plague':'여귀','myeongdo':'명도','geogu':'거구귀','duo':'두억시니','jangsan':'장산범(앞발·보상)'}
SLOT = {'main':'주무기','off':'보조무기','two':'양손','head':'머리','legs':'다리','accessory':'악세서리'}
TIER = {1:'일반',2:'희귀',3:'영웅',4:'전설'}

items = []
for w in weapons:
    w = dict(w)
    w['cooldown'] = cooldowns.get(w['skill'], 0.0)
    w['effectText'] = desc.get(w['id'], '')
    w['icon'] = icon(w['id']); w['drop'] = drop(w['id']); w['fx'] = effects(w)
    w['place'] = place_for(w, w['fx']) if w['fx'] and w['fx'][0]['label'] in ('공격', '공격·스킬', '광선', '발사', '스킬 돌진') else None
    if w['icon']['kind'] == 'draft' and w['id'] in GEAR3_UNLINKED:
        w['unlinkedIcon'] = REL + 'gear3/icons/%s.png' % GEAR3_UNLINKED[w['id']]
    w['category'] = 'weapon'
    items.append(w)
for g in general:
    g['icon'] = icon(g['id']); g['drop'] = drop(g['id']); g['effectText'] = g['effect']; g['category'] = 'gear'; g['fx'] = []
    items.append(g)

# ── 설계서와 비교: 무기 표를 파싱
slot_map = {'주무기':'main','보조무기':'off','양손':'two'}; kind_map = {'근접':'melee','원거리':'ranged'}; grade = {'일반':1,'희귀':2,'영웅':3,'전설':4}
dsgn = {}
for line in design.splitlines():
    cells = [c.strip() for c in line.strip().strip('|').split('|')]
    mm = None
    if len(cells) == 3: mm = re.match(r'(주무기|보조무기|양손)\s*·\s*(근접|원거리)\s*·\s*(일반|희귀|영웅|전설)', cells[1]); name = cells[0]; eff = cells[2]
    elif len(cells) == 4: mm = re.match(r'(주무기|보조무기|양손)\s*·\s*(근접|원거리)\s*·\s*(일반|희귀|영웅|전설)', cells[2]); name = cells[1]; eff = cells[3]
    if mm: dsgn[name] = dict(slot=slot_map[mm.group(1)], kind=kind_map[mm.group(2)], tier=grade[mm.group(3)], effect=eff)
dsgn['두억시니의 주먹'] = dict(slot='two', kind='melee', tier=4, effect='조준 방향 바로 앞에 거대 주먹 소환 타격 (§7 표)')
byname = {w['name']: w for w in weapons}
design_rows = []
for name, d in dsgn.items():
    w = byname.get(name)
    if not w: design_rows.append(dict(name=name, status='missing', design=d)); continue
    diffs = []
    if w['slot'] != d['slot']: diffs.append('슬롯 %s→%s' % (SLOT[d['slot']], SLOT[w['slot']]))
    if w['kind'] != d['kind']: diffs.append('분류 %s→%s' % (d['kind'], w['kind']))
    if w['tier'] != d['tier']: diffs.append('등급 %s→%s' % (TIER[d['tier']], TIER[w['tier']]))
    design_rows.append(dict(name=name, status='diff' if diffs else 'ok', diffs=diffs, design=d))
extra = [w['name'] for w in weapons if w['name'] not in dsgn]

# 아이콘 상태 집계
icon_kinds = {}
for it in items: icon_kinds.setdefault(it['icon']['kind'], []).append(it['id'])
generic_fx = [it['id'] for it in items if it['category'] == 'weapon' and it['fx'] and it['fx'][0]['note'].startswith('공용')]

data = dict(items=items, sets=SETS, slots=SLOT, tiers=TIER, designRows=design_rows, extraWeapons=extra,
            iconKinds={k: v for k, v in icon_kinds.items()}, genericFx=generic_fx,
            codeMissing=[g['id'] for g in general if not g['codeUsed']],
            counts=dict(weapons=len(weapons), general=len(general), designWeapons=len(dsgn)))
json.dump(data, open(os.path.join(HERE, 'data.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
tpl = open(os.path.join(HERE, 'template.html'), encoding='utf-8').read()
open(os.path.join(HERE, 'index.html'), 'w', encoding='utf-8').write(tpl.replace('/*__DATA__*/null', json.dumps(data, ensure_ascii=False)))
print('weapons', len(weapons), 'general', len(general), 'design', len(dsgn), 'missing', [r['name'] for r in design_rows if r['status'] == 'missing'])
print('diff', [(r['name'], r['diffs']) for r in design_rows if r['status'] == 'diff'])
print('icon kinds', {k: len(v) for k, v in icon_kinds.items()}, 'draft', icon_kinds.get('draft'))
print('generic fx', generic_fx, 'codeMissing', data['codeMissing'], 'extra', extra)
