extends SceneTree
# 범가죽(체력+20·피해 20% 감소), 범 눈알(공속 30%), 범의 발톱 보유 시 송곳니 기본공격=혼령 돌진.
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
func run_checks() -> void:
	world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	world.set_process(false)
	world.toggle_equipment_lab()
	c=world.combat
	world.reset_lab_targets()
	c.set_physics_process(false)
	c.paused=false
	c.crit_chance=0.0
	c.equipment={"heart":"songaksi","main":"","off":"","head":"","legs":"","a0":"","a1":"","a2":"","a3":""}
	c.sync_tiger_hide()
	var base:float=c.max_health
	c.equipment["a0"]="tiger_hide"
	c.sync_tiger_hide()
	if not check(c.max_health==base+20.0,"범가죽 장착 시 최대 체력 +20"): return
	c.equipment["a0"]=""
	c.sync_tiger_hide()
	if not check(c.max_health==base,"범가죽 해제 시 최대 체력 복구"): return
	c.equipment["a0"]="tiger_hide"
	c.sync_tiger_hide()
	if not check(is_equal_approx(c.incoming_damage(10.0),8.0),"범가죽 장착 시 받는 피해 20% 감소"): return
	c.equipment["a0"]=""
	if not check(is_equal_approx(c.incoming_damage(10.0),10.0),"범가죽 없으면 피해 그대로"): return
	c.equipment={"heart":"songaksi","main":"","off":"","head":"","legs":"","a0":"tiger_eye","a1":"","a2":"","a3":""}
	check(c.has_passive("tiger_eye"),"범 눈알 패시브 인식")
	# 송곳니 기본공격 전환
	world.player.position=Vector2(300,704)
	world.player.facing=1
	c.equipment={"heart":"songaksi","main":"tiger_fang","off":"","head":"","legs":"","a0":"","a1":"","a2":"","a3":""}
	world.wallet["bag"]=[]
	c.projectiles.clear()
	c.attack_cd["main"]=0.0
	c.perform_attack("main")
	var tigers:int=c.projectiles.filter(func(p):return p["kind"]=="tiger").size()
	if not check(tigers==0,"발톱 없이는 송곳니가 기본 물어뜯기"): return
	c.equipment["a0"]="tiger_eye"
	world.wallet["bag"].append({"id":"claws"})
	c.projectiles.clear()
	c.attack_cd["main"]=0.0
	c.perform_attack("main")
	tigers=c.projectiles.filter(func(p):return p["kind"]=="tiger").size()
	if not check(tigers==1,"발톱을 가방에 보유하면 송곳니 기본공격이 혼령 돌진"): return
	check(is_equal_approx(float(c.attack_cd["main"]),.8/1.3),"범 눈알로 공격 간격 0.8→약 0.615초")
	quit(0)
