extends RefCounted
# 검은비늘(악세사리) 날씨. 방에 들어설 때마다 무작위로 정해지고, 적이 남아 있는 전투 방에서만 효과가 난다.
# 감전·빙결 같은 상태이상 본체는 따로 구현한다. 여기서는 감전 배율(shock_mult)과 apply_shock 호출 지점만 둔다.
const ITEM_PASSIVE := "black_scale"
const IDS := ["clear","rain","storm","fog","snow","blizzard","rays","fireflies","stars"]
const INFO := {
	"clear":{"name":"맑음","text":"아무 일도 없는 평범한 방"},
	"rain":{"name":"장맛비","text":"적 전체 슬로우 · 감전 대미지 1.5배"},
	"storm":{"name":"뇌우","text":"3초마다 낙뢰(적 20·나 5) · 감전 대미지 1.5배"},
	"fog":{"name":"안개","text":"적 투사체 사거리 절반"},
	"snow":{"name":"눈","text":"적 3초마다 2 피해 · 슬로우 지속 2배"},
	"blizzard":{"name":"눈보라","text":"적 3초마다 2 피해 · 8초마다 10 피해+빙결 후 둔화"},
	"rays":{"name":"햇살","text":"내 공격 대미지 20% 감소 · 적 화상 대미지 증가"},
	"fireflies":{"name":"도깨비불","text":"도깨비불에 닿은 적 화상 · 화상 대미지 증가 · 내 대미지 1.5배"},
	"stars":{"name":"유성우","text":"8초마다 유성 낙하(30 피해, 나는 체력 1 미만 안 됨)"}
}
const SHEET_FILES := {"rain":"rain","storm":"storm","fog":"fog","snow":"snow","blizzard":"blizzard","rays":"god-rays","fireflies":"fireflies","stars":"shooting-stars"}
const TINT := {"rain":Color(.12,.2,.35,.28),"storm":Color(.08,.1,.2,.38),"fog":Color(.47,.55,.59,.14),"snow":Color(.47,.59,.75,.14),"blizzard":Color(.59,.69,.82,.22),"rays":Color(1,.88,.59,.10),"fireflies":Color(.04,.08,.16,.34),"stars":Color(.03,.04,.12,.40)}
# 가안 수치
const BOLT_INTERVAL := 3.0
const BOLT_WARN := 1.0
const BOLT_RADIUS := 44.0
const BOLT_ENEMY_DAMAGE := 20.0
const BOLT_PLAYER_DAMAGE := 5.0
const METEOR_INTERVAL := 8.0
const METEOR_WARN := 1.0
const METEOR_RADIUS := 56.0
const METEOR_DAMAGE := 30.0
const SNOW_INTERVAL := 3.0
const SNOW_DAMAGE := 2.0
const GUST_INTERVAL := 8.0
const GUST_DAMAGE := 10.0
const GUST_FREEZE := 0.8
const GUST_SLOW := 3.0
const SUN_PLAYER_SCALE := 0.8
const WISP_PLAYER_SCALE := 1.5
const BURN_BONUS := 1.5
const SHOCK_BONUS := 1.5
const WISP_LIFE := 2.6
const WISP_TOUCH := 30.0
const GROUND_Y := 704.0

var c: Node2D
var id := "clear"
var last_id := ""
var clock := 0.0
var rng := RandomNumberGenerator.new()
var strikes: Array = []
var wisps: Array = []
var bolt_timer := BOLT_INTERVAL
var meteor_timer := METEOR_INTERVAL
var snow_timer := SNOW_INTERVAL
var gust_timer := GUST_INTERVAL
var wisp_timer := 1.5
var gust_visual := 0.0

func _init() -> void:
	rng.randomize()

func weather_name(weather_id := "") -> String:
	return str(INFO[id if weather_id.is_empty() else weather_id]["name"])

func equipped() -> bool:
	return is_instance_valid(c) and c.has_passive(ITEM_PASSIVE)

# 효과가 실제로 걸리는 상태: 검은비늘 장착 + 날씨가 맑음이 아님 + 적이 남은 전투 방.
func active() -> bool:
	if id=="clear" or not equipped(): return false
	if c.data.get("cleared",false): return false
	return c.world.is_combat_room() and not c.living().is_empty()

func is_(weather_id: String) -> bool:
	return active() and id==weather_id

func reset() -> void:
	strikes.clear()
	wisps.clear()
	bolt_timer=BOLT_INTERVAL
	meteor_timer=METEOR_INTERVAL
	snow_timer=SNOW_INTERVAL
	gust_timer=GUST_INTERVAL
	wisp_timer=1.5
	gust_visual=0.0
	clock=0.0

func set_weather(weather_id: String) -> void:
	reset()
	id=weather_id if INFO.has(weather_id) else "clear"

# 방에 들어설 때 호출. 전투 방이 아니거나 이미 클리어한 방이면 맑음.
func roll_for_room() -> void:
	reset()
	if not equipped() or not c.world.is_combat_room() or c.data.get("cleared",false):
		id="clear"
		return
	var pool:Array=IDS.filter(func(w):return w!=last_id)
	id=str(pool[rng.randi_range(0,pool.size()-1)])
	last_id=id
	c.message("검은비늘 · "+weather_name()+" — "+str(INFO[id]["text"]))

# ---- 효과 배율 (다른 스크립트가 읽는다) ----
func player_damage_scale() -> float:
	if is_("rays"): return SUN_PLAYER_SCALE
	if is_("fireflies"): return WISP_PLAYER_SCALE
	return 1.0
func burn_scale() -> float:
	return BURN_BONUS if (is_("rays") or is_("fireflies")) else 1.0
func shock_scale() -> float:
	return SHOCK_BONUS if (is_("rain") or is_("storm")) else 1.0
func projectile_life_decay() -> float:
	return 2.0 if is_("fog") else 1.0
func slow_decay() -> float:
	return .5 if (is_("snow") or is_("blizzard")) else 1.0

# ---- 진행 ----
func visible_x() -> float:
	var view:Rect2=c.visible_rect()
	return rng.randf_range(view.position.x+60,view.end.x-60)

func hurt_player_capped(amount: float) -> void:
	# 체력 1 아래로는 내려가지 않는다. 대시 중에는 맞지 않고, 이미 1 이하면 피해가 없다.
	if c.equipment_lab or not c.enabled or c.world.player.dash_time>0 or c.health<=1.0: return
	c.health=maxf(1.0,c.health-amount)

func tick(delta: float) -> void:
	gust_visual=maxf(0.0,gust_visual-delta)
	if not active():
		strikes.clear()
		wisps.clear()
		return
	clock+=delta
	var living:Array=c.living()
	if id=="rain":
		for enemy in living: enemy.slow=maxf(enemy.slow,.25)
	elif id=="storm":
		bolt_timer-=delta
		if bolt_timer<=0:
			bolt_timer+=BOLT_INTERVAL
			strikes.append({"kind":"bolt","pos":c.safe_ground(visible_x()),"t":BOLT_WARN,"flash":0.0})
	elif id in ["snow","blizzard"]:
		snow_timer-=delta
		if snow_timer<=0:
			snow_timer+=SNOW_INTERVAL
			for enemy in living: enemy.take_damage(SNOW_DAMAGE,true,Color("bfe3ff"))
		if id=="blizzard":
			gust_timer-=delta
			if gust_timer<=0:
				gust_timer+=GUST_INTERVAL
				gust_visual=.8
				c.message("눈보라가 몰아칩니다")
				for enemy in living:
					enemy.take_damage(GUST_DAMAGE,true,Color("bfe3ff"))
					if enemy.dead: continue
					if enemy.boss: enemy.slow=maxf(enemy.slow,GUST_SLOW)
					else: enemy.apply_freeze(GUST_FREEZE,GUST_SLOW)
	elif id=="stars":
		meteor_timer-=delta
		if meteor_timer<=0:
			meteor_timer+=METEOR_INTERVAL
			strikes.append({"kind":"meteor","pos":c.safe_ground(visible_x()),"t":METEOR_WARN,"flash":0.0})
	elif id=="fireflies":
		wisp_timer-=delta
		if wisp_timer<=0:
			wisp_timer=rng.randf_range(3.5,6.0)
			var view:Rect2=c.visible_rect()
			wisps.append({"x":rng.randf_range(view.position.x+120,view.end.x-120),"y":GROUND_Y-40.0-rng.randf_range(0.0,30.0),"age":0.0,"seed":rng.randf()*6.0,"vx":rng.randf_range(-10.0,10.0)})
		for wisp in wisps:
			wisp["age"]+=delta
			var center:=wisp_position(wisp)
			var k:=wisp_scale(wisp)
			if k>=.8:
				for enemy in living:
					if (enemy.position+Vector2(0,-25*enemy.size_factor)).distance_to(center)<WISP_TOUCH+14.0*enemy.size_factor:
						enemy.apply_burn(3.0,1.0,.5)
		for i in range(wisps.size()-1,-1,-1):
			if float(wisps[i]["age"])>=WISP_LIFE: wisps.remove_at(i)
	for i in range(strikes.size()-1,-1,-1):
		var s:Dictionary=strikes[i]
		if float(s["flash"])>0:
			s["flash"]=float(s["flash"])-delta
			if float(s["flash"])<=0: strikes.remove_at(i)
			continue
		s["t"]=float(s["t"])-delta
		if float(s["t"])<=0:
			s["flash"]=.22
			land(s)

func land(s: Dictionary) -> void:
	var meteor:bool=s["kind"]=="meteor"
	var radius:=METEOR_RADIUS if meteor else BOLT_RADIUS
	var center:Vector2=Vector2(s["pos"])+Vector2(0,-30)
	for enemy in c.living():
		if (enemy.position+Vector2(0,-25*enemy.size_factor)).distance_to(center)<radius+16.0*enemy.size_factor:
			enemy.take_damage(METEOR_DAMAGE if meteor else BOLT_ENEMY_DAMAGE,false,Color("9fd0ff") if not meteor else Color("ffc77a"))
			if not meteor and not enemy.dead: enemy.apply_shock(2.0)
	if (c.world.player.position+Vector2(0,-23)).distance_to(center)<radius+12.0:
		hurt_player_capped(METEOR_DAMAGE if meteor else BOLT_PLAYER_DAMAGE)

func wisp_scale(wisp: Dictionary) -> float:
	var age:float=wisp["age"]
	if age<.5: return age/.5
	if age>WISP_LIFE-.6: return maxf(0.0,(WISP_LIFE-age)/.6)
	return 1.0
func wisp_position(wisp: Dictionary) -> Vector2:
	var age:float=wisp["age"]
	return Vector2(float(wisp["x"])+sin(clock*1.3+float(wisp["seed"]))*22.0+age*float(wisp["vx"]),float(wisp["y"])+sin(clock*2.1+float(wisp["seed"])*2.0)*10.0)

# ---- 그리기 (combat_director._draw 안에서 호출) ----
func draw() -> void:
	if not active(): return
	for s in strikes:
		var pos:Vector2=s["pos"]
		var meteor:bool=s["kind"]=="meteor"
		var radius:=METEOR_RADIUS if meteor else BOLT_RADIUS
		var warm:=Color("ffb35a") if meteor else Color("9fd0ff")
		if float(s["flash"])>0:
			var k:=float(s["flash"])/.22
			if meteor: c.draw_circle(pos+Vector2(0,-14),radius*(1.15-.4*k),Color(1,.78,.4,.55*k))
			else:
				var top:=pos+Vector2(0,-420)
				var pts:=PackedVector2Array([top])
				for i in range(1,8): pts.append(top.lerp(pos,float(i)/8.0)+Vector2(sin(i*2.3+pos.x)*14.0,0))
				pts.append(pos)
				c.draw_polyline(pts,Color(.85,.93,1,.95*k),3.0)
				c.draw_polyline(pts,Color(.55,.75,1,.5*k),7.0)
			c.draw_arc(pos+Vector2(0,-4),radius*(1.2-.4*k),0,TAU,28,Color(warm.r,warm.g,warm.b,.8*k),2.0)
		else:
			var left:float=s["t"]
			var blink:=.55+.35*sin(clock*18.0)
			c.draw_set_transform(pos+Vector2(0,-2),0,Vector2(1,.35))
			c.draw_arc(Vector2.ZERO,radius,0,TAU,28,Color(warm.r,warm.g,warm.b,blink),2.0)
			c.draw_arc(Vector2.ZERO,radius*(1.0-left),0,TAU,28,Color(warm.r,warm.g,warm.b,.35),2.0)
			c.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
			if meteor and left<.45:
				var q:=1.0-left/.45
				var from:=pos+Vector2(170,-440)
				var head:=from.lerp(pos+Vector2(0,-14),q)
				c.draw_line(head+Vector2(46,-92)*(1.0-q*.2),head,Color(1,.7,.35,.85),3.0)
				c.draw_circle(head,5,Color(1,.92,.7,.95))
	for wisp in wisps:
		var k:=wisp_scale(wisp)
		if k<=0.02: continue
		var center:=wisp_position(wisp)
		var radius:=6.0*k
		c.draw_circle(center,34.0*k,Color(.55,1,.82,.07))
		c.draw_circle(center,20.0*k,Color(.55,1,.82,.12))
		for row in range(-8,9):
			for col in range(-8,9):
				var d:=Vector2(col,row*.95).length()
				if d>radius: continue
				var f:=d/maxf(radius,.1)
				var color:Color=Color("14606a") if f>.8 else Color("22a89a") if f>.55 else Color("6fe0c0") if f>.25 else Color("d8fff0")
				c.draw_rect(Rect2(round(center.x/2.0+col)*2.0,round(center.y/2.0+row)*2.0,2,2),color)
	if gust_visual>0:
		var view:Rect2=c.visible_rect()
		var a:=gust_visual/.8
		for i in range(14):
			var y:=view.position.y+30.0+i*29.0
			var x:=view.position.x+fposmod(clock*900.0+i*131.0,view.size.x+160.0)-160.0
			c.draw_line(Vector2(x,y),Vector2(x+120.0+(i%3)*30.0,y+10.0),Color(.85,.93,1,.5*a),2.0)
