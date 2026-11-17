extends SceneTree
# 검은비늘 날씨: 아이템 정의, 방 입장 굴리기, 날씨별 효과 수치를 검사한다.
const DB=preload("res://scripts/equipment_db.gd")
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
func run_for(seconds: float) -> void:
	var left:=seconds
	while left>0:
		var step:=minf(.05,left)
		c.weather.tick(step)
		left-=step
func fresh() -> Node:
	world.reset_lab_targets()
	world.player.set_physics_process(false)
	world.player.position=Vector2(300,704)
	c.set_physics_process(false)
	c.paused=false
	c.equipment_lab=false
	c.crit_chance=0.0
	c.data["cleared"]=false
	c.equipment["a0"]="black_scale"
	var target=c.living()[0]
	target.hp=10000
	target.max_hp=10000
	target.slow=0
	target.burn=0
	target.shock=0
	target.frozen=0
	target.position=Vector2(900,704)
	return target
func run_checks() -> void:
	world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	world.set_process(false)
	world.toggle_equipment_lab()
	c=world.combat
	var item:Dictionary=DB.get_item("black_scale")
	if not check(item["slot"]=="accessory" and item["tier"]==4 and item["passive"]=="black_scale" and not str(item["effect"]).is_empty(),"Black scale is a top-tier accessory with a passive"): return
	var w=c.weather
	w.set_weather("rain")
	c.equipment["a0"]=""
	var target=fresh()
	c.equipment["a0"]=""
	if not check(not w.active(),"No weather effect without the item equipped"): return
	c.equipment["a0"]="black_scale"
	if not check(w.active(),"Weather is active in an uncleared combat room with the item"): return
	c.data["cleared"]=true
	if not check(not w.active(),"Cleared room has no weather effect"): return
	c.data["cleared"]=false

	# 장맛비
	target=fresh()
	w.set_weather("rain")
	w.tick(.1)
	if not check(target.slow>0 and is_equal_approx(w.shock_scale(),1.5),"Rain slows every enemy and boosts shock damage 1.5x"): return

	# 뇌우
	target=fresh()
	w.set_weather("storm")
	run_for(3.01)
	if not check(w.strikes.size()==1 and is_equal_approx(w.shock_scale(),1.5),"Storm queues a lightning strike every 3 seconds with a warning"): return
	var strike:Dictionary=w.strikes[0]
	target.position=Vector2(strike["pos"])
	world.player.position=Vector2(strike["pos"])
	c.health=40
	var before:float=target.hp
	run_for(1.05)
	if not check(is_equal_approx(before-target.hp,20.0) and target.shock>0,"Lightning deals 20 to an enemy and applies the shock hook"): return
	if not check(is_equal_approx(c.health,35.0),"Lightning deals 5 to the player"): return
	w.set_weather("storm")
	w.strikes.append({"kind":"bolt","pos":world.player.position,"t":.01,"flash":0.0})
	c.health=3.0
	w.tick(.02)
	if not check(is_equal_approx(c.health,1.0),"Lightning never drops the player below 1 HP"): return
	w.strikes.append({"kind":"bolt","pos":world.player.position,"t":.01,"flash":0.0})
	w.tick(.02)
	if not check(is_equal_approx(c.health,1.0),"Lightning does nothing at 1 HP"): return

	# 안개
	target=fresh()
	w.set_weather("fog")
	c.fire_projectile(Vector2(560,680),Vector2.RIGHT,5,false,"shot")
	c.fire_projectile(Vector2(560,680),Vector2.RIGHT,5,true,"shot")
	c.tick_projectiles(.5)
	var enemy_life:=-1.0
	var friendly_life:=-1.0
	for p in c.projectiles:
		if p["friendly"]: friendly_life=p["life"]
		else: enemy_life=p["life"]
	if not check(is_equal_approx(enemy_life,1.0) and is_equal_approx(friendly_life,.7),"Fog halves enemy projectile range and leaves player projectiles alone"): return
	c.projectiles.clear()

	# 눈
	target=fresh()
	w.set_weather("snow")
	before=target.hp
	run_for(3.01)
	if not check(is_equal_approx(before-target.hp,2.0) and is_equal_approx(w.slow_decay(),.5),"Snow deals 2 to enemies every 3 seconds and stretches slow"): return

	# 눈보라
	target=fresh()
	w.set_weather("blizzard")
	w.snow_timer=99.0
	w.gust_timer=.01
	before=target.hp
	w.tick(.02)
	if not check(is_equal_approx(before-target.hp,10.0) and target.frozen>0 and target.stun>0,"Blizzard gust deals 10 and briefly freezes enemies"): return
	target.frozen=.01
	target.frozen_then_slow=3.0
	target.slow=0
	target._physics_process(.02)
	if not check(target.slow>=2.9,"Freeze is followed by slow when it ends"): return

	# 햇살
	target=fresh()
	w.set_weather("rays")
	var rolled:Dictionary=c.roll_player_damage(10.0)
	if not check(is_equal_approx(rolled["damage"],8.0) and is_equal_approx(w.burn_scale(),1.5),"Sun cuts player damage by 20% and raises burn damage"): return
	target.apply_burn(3.0,1.0,.5)
	before=target.hp
	target.tick_burn(.51)
	if not check(is_equal_approx(before-target.hp,1.5),"Burn deals 1.5 under the sun"): return

	# 도깨비불
	target=fresh()
	w.set_weather("fireflies")
	rolled=c.roll_player_damage(10.0)
	if not check(is_equal_approx(rolled["damage"],15.0),"Wisp weather raises player damage 1.5x"): return
	w.wisp_timer=.01
	w.tick(.02)
	if not check(w.wisps.size()==1,"A big wisp appears every few seconds"): return
	w.wisps[0]["age"]=1.0
	target.position=Vector2(w.wisp_position(w.wisps[0]).x,704)
	w.wisps[0]["y"]=660.0
	w.tick(.01)
	if not check(target.burn>0,"Touching a big wisp burns the enemy"): return
	w.wisps[0]["age"]=w.WISP_LIFE
	w.tick(.01)
	if not check(w.wisps.is_empty(),"Big wisp disappears after its lifetime"): return

	# 유성우
	target=fresh()
	w.set_weather("stars")
	run_for(8.01)
	if not check(w.strikes.size()==1,"Meteor shower queues a meteor every 8 seconds with a warning"): return
	strike=w.strikes[0]
	target.position=Vector2(strike["pos"])
	world.player.position=Vector2(strike["pos"])
	c.health=20.0
	before=target.hp
	run_for(1.05)
	if not check(is_equal_approx(before-target.hp,30.0) and is_equal_approx(c.health,1.0),"Meteor deals 30 to enemies and cannot drop the player below 1 HP"): return

	# 굴리기: 같은 날씨는 연달아 나오지 않고, 평화 방은 맑음.
	target=fresh()
	var seen:Array=[]
	var previous:=""
	var repeated:=false
	for i in range(60):
		w.roll_for_room()
		if w.id==previous: repeated=true
		previous=w.id
		if not seen.has(w.id): seen.append(w.id)
	if not check(not repeated and seen.size()==w.IDS.size(),"Weather re-rolls on every room, never repeats back to back, and reaches all nine kinds"): return
	c.data["cleared"]=true
	w.roll_for_room()
	if not check(w.id=="clear","Cleared or peaceful rooms are clear"): return
	print("ALL PASS")
	quit(0)
