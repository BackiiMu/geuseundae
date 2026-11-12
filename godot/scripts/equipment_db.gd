extends RefCounted
static var _catalog: Array = []
# Prototype numerical tuning; item concepts follow geuseundae_equipment.md.
static func weapons() -> Array:
	return [
	["songaksi_hand","손각시의 손","main","melee",1,7,.32,84,"","songaksi"],
	["hair","손각시의 머리카락","main","melee",2,10,.45,128,"","songaksi"],
	["pin","녹슨 비녀","main","ranged",2,12,.6,440,"","songaksi"],
	["ribbon","끊어진 댕기","off","melee",2,5,.70,180,"pull","songaksi"],
	["mirror","피 묻은 족두리","off","ranged",3,6,.80,240,"shotgun","songaksi"],
	["eggshell","깨진 달걀껍데기","main","ranged",1,5,.65,300,"","egg"],
	["blank_face","민얼굴","off","ranged",2,5,.72,200,"fear","egg"],
	["gaze","텅 빈 응시","two","ranged",3,3,.12,360,"mass_fear","egg"],
	["nails","몽달의 손톱","main","melee",1,5,.2,80,"","mongdal"],
	["goose","부러진 나무기러기","main","ranged",2,10,.8,420,"","mongdal"],
	["mongdal_rush","몽달의 한","off","melee",3,7,.82,200,"rush","mongdal"],
	["claws","범의 발톱","main","melee",2,14,.6,140,"","changgui"],
	["call","창귀의 부름","off","ranged",2,5,.72,300,"lure","changgui"],
	["tiger_soul","홀린 넋","off","melee",3,6,.7,100,"","changgui"],
	["tiger_fang","범의 송곳니","two","melee",4,24,.8,120,"tiger","changgui"],
	["water_bucket","젖은 바가지","main","ranged",1,10,.7,340,"","water"],
	["water_hand","물귀신의 손","off","melee",2,4,.8,140,"","water"],
	["well_bucket","우물 두레박","two","melee",3,20,.85,170,"well","water"],
	["fox_bead","여우구슬","main","ranged",2,12,.5,440,"","fox"],
	["fox_fire","여우불","off","ranged",1,4,.62,160,"mines","fox"],
	["fox_mirror","둔갑 거울","off","melee",4,8,.86,120,"decoy","fox"],
	["club","도깨비방망이","main","melee",2,18,.8,100,"","goblin"],
	["goblin_fire","도깨비불","main","ranged",1,9,.45,380,"","goblin"],
	["broom","낡은 빗자루","off","melee",2,5,.65,100,"","goblin"],
	["belt","씨름 샅바","two","melee",3,18,.8,100,"slam","goblin"],
	["tooth","아귀의 이빨","main","ranged",1,4,.15,420,"","agwi"],
	["tongue","아귀의 혀","off","melee",2,6,.68,200,"drain","agwi"],
	["shadow","어둑한 그림자","main","melee",3,14,.6,100,"","shadow"],
	["voice","흉내 내는 목소리","off","ranged",3,6,.78,280,"confuse","tiger"],
	["plague","역병 항아리","main","ranged",2,8,.85,340,"","plague"],
	["whistle","가는 휘파람","main","ranged",3,7,.5,520,"","myeongdo"],
	["mouth","거구귀의 입","two","melee",4,24,1.0,200,"spit","geogu"],
	["fist","두억시니의 주먹","two","melee",4,30,1.0,100,"","duo"],
	["jangsan_paw","장산범의 앞발","main","melee",4,34,.82,150,"","jangsan"]]
static func items() -> Array:
	if not _catalog.is_empty(): return _catalog.duplicate(true)
	var result: Array = []
	for w in weapons():
		result.append({"id":w[0],"name":w[1],"slot":w[2],"kind":w[3],"tier":w[4],"damage":w[5],"interval":w[6],"range":w[7],"skill":w[8],"set":w[9],"price":[6,12,26,50][w[4]-1],"effect":description(w[0]),"stats":str(w[5])+" 피해 / "+str(w[6])+"초","cooldown":skill_cooldown(w[8])})
	for a in [["wig","헝클어진 가발","head",1,"hair_range"],["duo_head","두??니??의 XX??","head",4,"reach"],["bent_leg","꺾인 다리","legs",1,"speed"],["mongdal_legs","몽달의 다리","legs",2,"frenzy"],["wet_shoes","젖은 꽃신","feet",2,"wet_dash"],["single_shoe","한쪽 꽃신","feet",1,"landing"],["stomach","아귀의 위장","accessory",3,"heal"],["duo_curse","??의 짙은 저주","accessory",3,"dash_power"]]:
		result.append({"id":a[0],"name":a[1],"slot":a[2],"tier":a[3],"passive":a[4],"set":"duo" if a[0].begins_with("duo") else "songaksi" if a[0]=="wig" else "", "price":[6,12,26,50][a[3]-1],"effect":{"hair_range":"머리카락 사거리 20% 증가","reach":"근접 사거리·투사체 크기 1.5배","speed":"이동속도 12% 증가","frenzy":"처치 후 3초간 이동·공격속도 15% 증가","wet_dash":"대시 후 둔화 물자국","landing":"착지 시 근처 적 밀치기","heal":"처치 시 HP 3 회복 (0.6초 간격)","dash_power":"대시 공격 피해 1.5배"}[a[4]]})
	result.append({"id":"fox_tail","name":"구미호의 꼬리","slot":"accessory","tier":3,"passive":"fox_tail","set":"fox","price":32,"effect":"악세서리 · 공격 시 여우불 잔광이 적을 태움"})
	_catalog=result.duplicate(true)
	return result
static func get_item(id: String) -> Dictionary:
	if _catalog.is_empty(): items()
	for item in _catalog:
		if item["id"]==id: return item.duplicate(true)
	return {}
static func slot_name(slot: String) -> String:
	return {"heart":"심장","main":"오른손","off":"왼손","two":"양손","head":"머리","legs":"다리","feet":"발","accessory":"악세서리","a0":"악세서리 1","a1":"악세서리 2","a2":"악세서리 3","a3":"악세서리 4"}.get(slot,slot)
static func is_two(item: Dictionary) -> bool: return item.get("slot","")=="two"

static func skill_cooldown(skill: String) -> float:
	return {"pull":8.0,"shotgun":10.0,"fear":12.0,"mass_fear":16.0,"rush":10.0,"lure":10.0,"tiger":18.0,"well":14.0,"mines":10.0,"decoy":14.0,"slam":12.0,"drain":10.0,"confuse":16.0,"spit":12.0,"crush":18.0}.get(skill,0.0)
static func description(id: String) -> String:
	return {
	"songaksi_hand":"빠른 손톱 할퀴기 · 손각시를 빌리면 지급되는 기본 무기",
	"hair":"중거리 채찍 · 세 번째 공격 적중 시 0.4초 속박",
	"pin":"비녀 투척 · 벽에 꽂힌 머리카락 줄은 3초간 접촉 피해",
	"ribbon":"G · 전방 적 하나를 0.5초에 걸쳐 앞으로 끌기 (8초)",
	"mirror":"G · 구슬 산탄 · 다음 피격 피해 50% 증가 (10초)",
	"eggshell":"세 갈래 껍데기 · 가까이서 여러 파편 동시 적중",
	"blank_face":"G · 전방 원뿔 안의 적 2초 공포 (12초)",
	"gaze":"누르는 동안 관통 광선 · 점진 둔화 / F · 광선 방향 공포 (16초)",
	"nails":"빠른 손톱 연타 · 연속 적중 시 최대 공격속도 +52%",
	"goose":"나무기러기 왕복 투척 · 갈 때와 돌아올 때 각각 타격",
	"mongdal_rush":"G · 조준 방향 돌진 · 경로의 적을 한 번씩 할퀴기 (10초)",
	"claws":"넓게 뻗는 범의 세 발톱",
	"call":"G · 전방에 부름 설치 · 3초간 주변 적을 모으기 (10초)",
	"tiger_soul":"보조 평타 · 처치한 넋 최대 3개가 8초간 주무기 공격에 동참",
	"tiger_fang":"짧은 도약 후 물어뜯기 / F · 호랑이 혼령 관통 돌진 (18초)",
	"water_bucket":"포물선 물덩이 · 착지 후 3초 둔화 웅덩이",
	"water_hand":"보조 평타 · 발목을 잡아 2초간 이동속도 감소",
	"well_bucket":"넓은 두레박 휘두르기 / F · 3초간 끌어당기는 우물 (14초)",
	"fox_bead":"공전하는 여우구슬 발사 · 가까운 적을 약하게 유도",
	"fox_fire":"G · 적이 접근하면 터지는 여우불 3개 설치 (10초)",
	"fox_mirror":"G · 짧은 순간이동 · 적의 공격을 받는 폭발 허상 (14초)",
	"club":"묵직한 방망이 · 처치 시 30% 확률로 조각 추가",
	"goblin_fire":"불규칙하게 흔들리는 도깨비불 발사",
	"broom":"보조 평타 · 떠다니는 빗자루가 가까운 적을 자동 타격",
	"belt":"적을 던져 충돌한 적과 함께 피해 / F · 붙잡아 메치기 (12초)",
	"tooth":"이빨 8발 연사 · 소진 후 1.2초 재생",
	"tongue":"G · 전방 적을 낚아채 물기 · 실제 준 피해의 35% 회복 (10초)",
	"shadow":"주변 적 한 명당 공격 범위 +18%, 최대 두 배",
	"voice":"G · 전방 적들이 4초간 서로를 공격 (16초)",
	"plague":"포물선 항아리 · 깨진 자리에 독 구름 지속 피해",
	"whistle":"벽을 통과하며 여러 적을 맞히는 소리 파동",
	"mouth":"넓게 물기 · 처치한 적 최대 6명 삼킴 / F · 삼킨 수만큼 뱉기 (12초)",
	"fist":"0.3초 준비 후 거대 주먹 · 이동 가능 · 슈퍼아머 없음",
	"jangsan_paw":"전설 무기 · 위아래로 길고 옆으로 넓게 할퀴는 굵은 발톱 / 사거리 150"
	}.get(id,"")
