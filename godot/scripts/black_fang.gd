extends RefCounted
# 검은 이빨(임시 테스트 무기): 가장 가까운 적을 자동 조준해 히트스캔으로 즉시 판정하고,
# 현재 날씨(검은비늘)에 맞는 공격 연출을 적 위치에 재생한다. 날씨가 없으면 맑음 공격이다.
# 수치와 연출은 black-fang-preview.html 시안 기준(가안)이다.
const ID := "black_fang"
const AIM_RANGE := 520.0
const FOG_RADIUS := 130.0
const WISP_RADIUS := 140.0
const STAR_RADIUS := 90.0
const STAR_SPLASH := 8.0
const BOSS_STUN := 0.25
const VIEW_SCALE := 0.8   # 시안의 효과 크기 기본값
# 날씨별 [공격 이름, 피해]
const ATTACKS := {
	"clear":["돌 솟구침",6.0],"rain":["벼락",10.0],"storm":["회오리바람",10.0],"fog":["안개 깔림",8.0],"snow":["고드름 낙하",8.0],
	"blizzard":["눈 폭풍우",8.0],"rays":["불기둥",9.0],"fireflies":["도깨비불 구체",9.0],"stars":["유성 낙하",12.0]
}
var c: Node2D
var strikes: Array = []
var textures := {}
var manifest: Dictionary = {}
var clock := 0.0
var last_weather := ""
var last_target: Node = null

func reset() -> void:
	strikes.clear()

func current_weather() -> String:
	return c.weather.id if c.weather.active() else "clear"

func data() -> Dictionary:
	if manifest.is_empty():
		manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/vfx/black-fang/manifest.json"))["strikes"]
	return manifest

# 공격 한 번. 대상이 없으면 false(쿨타임을 쓰지 않는다).
func fire(origin: Vector2) -> bool:
	var target=c.nearest_enemy(origin,AIM_RANGE)
	if target==null: return false
	var weather:String=current_weather()
	var base:float=float(ATTACKS[weather][1])
	last_weather=weather
	last_target=target
	c.damage_enemy(target,base)
	match weather:
		"rain":
			if not target.dead: target.apply_shock(2.0)
		"storm":
			if not target.dead: lift(target)
		"fog":
			for e in c.living():
				if e==target or e.position.distance_to(target.position)<FOG_RADIUS:
					if e!=target: c.damage_enemy(e,base)
					if not e.dead: root(e,.5)
		"snow":
			if not target.dead: target.slow=maxf(target.slow,2.0)
		"blizzard":
			if not target.dead:
				if target.boss: target.slow=maxf(target.slow,3.0)
				else: target.apply_freeze(.5,3.0)
		"rays":
			if not target.dead: target.apply_burn(3.0,1.0,.5)
		"fireflies":
			for e in c.living():
				if e==target or e.position.distance_to(target.position)<WISP_RADIUS:
					if e!=target: c.damage_enemy(e,base)
					if not e.dead: e.apply_burn(3.0,1.0,.5)
		"stars":
			for e in c.living():
				if e!=target and e.position.distance_to(target.position)<STAR_RADIUS: c.damage_enemy(e,STAR_SPLASH)
	var info:Dictionary=data()[weather]
	var pos:Vector2=target.position+(Vector2(0,-30) if info["anchor"]=="body" else Vector2.ZERO)
	strikes.append({"weather":weather,"pos":pos,"t":0.0})
	return true

func root(enemy: Node, seconds: float) -> void:
	enemy.stun=maxf(enemy.stun,BOSS_STUN if enemy.boss else seconds)

func lift(enemy: Node) -> void:
	if enemy.boss:
		enemy.stun=maxf(enemy.stun,BOSS_STUN)
		return
	enemy.stun=maxf(enemy.stun,.8)
	enemy.velocity.y=-300.0

func tick(delta: float) -> void:
	clock+=delta
	for i in range(strikes.size()-1,-1,-1):
		var s:Dictionary=strikes[i]
		s["t"]=float(s["t"])+delta
		if not frame_of(s).has("index"): strikes.remove_at(i)

# 지금 재생할 프레임 번호와 투명도. 끝났으면 빈 사전.
func frame_of(s: Dictionary) -> Dictionary:
	var info:Dictionary=data()[s["weather"]]
	var t:float=s["t"]
	var fps:float=float(info["fps"])
	var start:int=int(info["start"])
	var last:int=int(info["end"])
	var alpha:=1.0
	var index:int
	if info.get("loop",false):
		var life:float=float(info["dur"])
		if t>life: return {}
		index=start+int(t*fps)%(last-start+1)
		alpha=minf(1.0,minf(t/.18,(life-t)/.3))
	else:
		index=start+int(t*fps*float(info["rate"]))
		if index>last: return {}
	return {"index":index,"alpha":maxf(0.0,alpha)}

func draw() -> void:
	for s in strikes:
		var f:Dictionary=frame_of(s)
		if not f.has("index"): continue
		var weather:String=s["weather"]
		var info:Dictionary=data()[weather]
		if not textures.has(weather): textures[weather]=load("res://assets/vfx/black-fang/"+weather+".png")
		var size:=Vector2(info["fw"],info["fh"])
		var cols:int=int(info["cols"])
		var index:int=f["index"]
		var source:=Rect2(Vector2(index%cols,floori(float(index)/cols))*size,size)
		var scale:float=float(info["sc"])*VIEW_SCALE
		var pivot:=Vector2(info["pivot"][0],info["pivot"][1])
		var dest:=Rect2(Vector2(s["pos"])-pivot*scale,size*scale)
		c.draw_texture_rect_region(textures[weather],dest,source,Color(1,1,1,float(f["alpha"])))
