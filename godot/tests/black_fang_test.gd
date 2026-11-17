extends SceneTree
# 검은 이빨(임시 테스트 무기): 자동 조준 히트스캔, 날씨별 피해·추가 효과, 상점 제외를 검사한다.
const DB=preload("res://scripts/equipment_db.gd")
const Stock=preload("res://scripts/merchant_stock.gd")
var world
var c
func _initialize() -> void: call_deferred("run_checks")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool,message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
		return false
	print("PASS: ",message)
	return true
func fresh() -> Array:
	world.reset_lab_targets()
	world.player.set_physics_process(false)
	world.player.position=Vector2(300,704)
	world.player.facing=1
	c.set_physics_process(false)
	c.paused=false
	c.equipment_lab=false
	c.crit_chance=0.0
	c.data["cleared"]=false
	c.equipment={"heart":"songaksi","main":"black_fang","off":"","head":"","legs":"","a0":"black_scale","a1":"","a2":"","a3":""}
	c.attack_cd["main"]=0.0
	c.arsenal.fang.reset()
	var list:Array=c.living()
	for i in range(list.size()):
		var e=list[i]
		e.hp=10000
		e.max_hp=10000
		e.slow=0
		e.burn=0
		e.shock=0
		e.frozen=0
		e.stun=0
		e.position=Vector2(500+i*70,704)
	return list
func hit_with(weather: String) -> Array:
	var list:Array=fresh()
	c.weather.set_weather(weather)
	var before:Array=list.map(func(e):return e.hp)
	c.perform_attack("main")
	return [list,before]
func run_checks() -> void:
	world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	world.set_process(false)
	world.toggle_equipment_lab()
	c=world.combat
	var item:Dictionary=DB.get_item("black_fang")
	if not check(item["slot"]=="main" and item["kind"]=="ranged" and item["test"] and float(item["range"])==520.0,"Black fang is a ranged test weapon with 520 aim range"): return
	for i in range(200):
		for stock_item in Stock.roll(i,3+i%10,false):
			if not check(stock_item["id"]!="black_fang","Test weapon never appears in shop stock"): return
	# 대상 없음: 쿨타임을 쓰지 않는다
	var list:=fresh()
	for e in list: e.position=Vector2(2000,704)
	c.perform_attack("main")
	if not check(c.attack_cd["main"]<=.11 and c.arsenal.fang.strikes.is_empty(),"No target in range means no shot and a short retry delay"): return
	# 가장 가까운 적을 즉시 맞힌다 (맑음 6)
	var r:=hit_with("clear")
	list=r[0]
	var nearest=list[0]
	if not check(is_equal_approx(r[1][0]-nearest.hp,6.0) and is_equal_approx(c.attack_cd["main"],.7) and c.arsenal.fang.strikes.size()==1,"Clear weather: instant 6 damage on the nearest enemy with a rock strike"): return
	for i in range(1,list.size()): if not check(is_equal_approx(list[i].hp,r[1][i]),"Only the nearest enemy is hit"): return
	# 날씨가 꺼져 있으면(검은비늘 없음) 맑음 공격
	c.equipment["a0"]=""
	c.weather.set_weather("storm")
	var plain=fresh()
	c.equipment["a0"]=""
	c.weather.set_weather("storm")
	c.perform_attack("main")
	if not check(c.arsenal.fang.strikes[0]["weather"]=="clear","Without the black scale the weapon uses the clear attack"): return
	# 장맛비: 벼락 10 + 감전
	r=hit_with("rain")
	if not check(is_equal_approx(r[1][0]-r[0][0].hp,10.0) and r[0][0].shock>0,"Rain: lightning 10 and shock"): return
	# 뇌우: 회오리 10 + 띄움
	r=hit_with("storm")
	if not check(is_equal_approx(r[1][0]-r[0][0].hp,10.0) and r[0][0].stun>=.79 and r[0][0].velocity.y<0,"Storm: tornado 10 and lift"): return
	# 안개: 반경 130 안 전체 8 + 속박
	r=hit_with("fog")
	var in_range:=0
	for i in range(r[0].size()):
		var e=r[0][i]
		var inside:bool=e.position.distance_to(r[0][0].position)<130.0 or i==0
		if inside:
			in_range+=1
			if not check(is_equal_approx(r[1][i]-e.hp,8.0) and e.stun>0,"Fog: enemy inside 130 takes 8 and is rooted"): return
		elif not check(is_equal_approx(r[1][i]-e.hp,0.0),"Fog: enemy outside 130 is untouched"): return
	# 눈: 8 + 둔화
	r=hit_with("snow")
	if not check(is_equal_approx(r[1][0]-r[0][0].hp,8.0) and r[0][0].slow>=2.0,"Snow: icicle 8 and slow"): return
	# 눈보라: 8 + 빙결
	r=hit_with("blizzard")
	if not check(is_equal_approx(r[1][0]-r[0][0].hp,8.0) and r[0][0].frozen>0,"Blizzard: snow storm 8 and freeze"): return
	# 햇살: 불기둥 9*0.8(햇살 대미지 감소) + 화상
	r=hit_with("rays")
	if not check(is_equal_approx(r[1][0]-r[0][0].hp,9.0*.8) and r[0][0].burn>0,"Rays: fire pillar 9 reduced by the sun penalty, plus burn"): return
	# 도깨비불: 반경 140 전체 9*1.5 + 화상
	r=hit_with("fireflies")
	for i in range(r[0].size()):
		var e=r[0][i]
		var inside:bool=e.position.distance_to(r[0][0].position)<140.0 or i==0
		if inside:
			if not check(is_equal_approx(r[1][i]-e.hp,9.0*1.5) and e.burn>0,"Wisp: enemy inside 140 takes 9 (x1.5 weather) and burns"): return
		elif not check(is_equal_approx(r[1][i]-e.hp,0.0),"Wisp: enemy outside 140 is untouched"): return
	# 유성우: 대상 12, 90 이내 다른 적 8
	r=hit_with("stars")
	if not check(is_equal_approx(r[1][0]-r[0][0].hp,12.0),"Stars: meteor 12 on the target"): return
	for i in range(1,r[0].size()):
		var e=r[0][i]
		var near:bool=e.position.distance_to(r[0][0].position)<90.0
		if not check(is_equal_approx(r[1][i]-e.hp,8.0 if near else 0.0),"Stars: splash 8 inside 90 only"): return
	# 연출은 시간이 지나면 끝난다
	r=hit_with("storm")
	for i in range(60): c.arsenal.tick(.05)
	if not check(c.arsenal.fang.strikes.is_empty(),"Strike visuals end on their own"): return
	print("ALL PASS")
	quit(0)
