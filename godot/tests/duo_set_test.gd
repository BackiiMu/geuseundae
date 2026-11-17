extends SceneTree
# 두억시니 세트(머리·악세서리·주먹) 완성 시 주먹: 가로 공격 거리 2배, 대미지 80.
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
func setup(with_set: bool) -> Array:
	world.reset_lab_targets()
	world.player.set_physics_process(false)
	world.player.position=Vector2(300,704)
	world.player.facing=1
	c.set_physics_process(false)
	c.paused=false
	c.crit_chance=0.0
	c.equipment={"heart":"songaksi","main":"fist","off":"","head":"duo_head" if with_set else "","legs":"","a0":"duo_curse" if with_set else "","a1":"","a2":"","a3":""}
	c.attack_cd["main"]=0.0
	c.arsenal.pending.clear()
	var list:Array=c.living()
	for e in list:
		e.hp=10000
		e.max_hp=10000
		e.knockback=0
	return list
func punch(list: Array,positions: Array) -> Array:
	for i in range(list.size()): list[i].position=positions[i]
	var before:Array=list.map(func(e):return e.hp)
	c.vfx.clear()
	c.perform_attack("main")
	c.arsenal.tick(.31)
	if c.duo_set(): c.arsenal.tick(.31)   # 세트 완성: 철퇴가 바닥에 닿는 0.6초에 판정
	return before
func run_checks() -> void:
	world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	world.set_process(false)
	world.toggle_equipment_lab()
	c=world.combat
	# 세트 없음: 머리 없이 주먹만 → 사거리 100+20, 대미지 30
	var list:=setup(false)
	var before:=punch(list,[Vector2(400,704),Vector2(550,704),Vector2(900,704)])
	if not check(is_equal_approx(before[0]-list[0].hp,30.0) and is_equal_approx(before[1]-list[1].hp,0.0),"Without the set the fist deals 30 and reaches only 120"): return
	# 세트 완성
	list=setup(true)
	if not check(c.duo_set(),"Head, accessory and fist complete the Duoksini set"): return
	# 머리 패시브 1.5배 사거리(150) 위에 세트 가로 2배: (150+20)*2=340
	before=punch(list,[Vector2(560,704),Vector2(630,704),Vector2(700,704)])
	if not check(is_equal_approx(before[0]-list[0].hp,80.0) and is_equal_approx(before[1]-list[1].hp,80.0),"Set fist deals 80 and reaches 340 forward (260 and 330 away are hit)"): return
	list=setup(true)
	before=punch(list,[Vector2(630,704),Vector2(700,704),Vector2(720,704)])
	if not check(is_equal_approx(before[0]-list[0].hp,80.0) and is_equal_approx(before[1]-list[1].hp,0.0),"Enemy 400 away is outside the doubled reach while 330 away is hit"): return
	# 세로(수직)는 그대로: 앞으로 250 떨어져 있어도 위로 200 떠 있으면 맞지 않는다
	list=setup(true)
	before=punch(list,[Vector2(500,504),Vector2(900,704),Vector2(950,704)])
	if not check(is_equal_approx(before[0]-list[0].hp,0.0),"Doubling is horizontal only: a target 200 above is not hit"): return
	# 세트가 깨지면 원래대로
	list=setup(true)
	c.equipment["a0"]=""
	before=punch(list,[Vector2(560,704),Vector2(900,704),Vector2(950,704)])
	if not check(is_equal_approx(before[0]-list[0].hp,0.0),"Breaking the set removes the bonus (260 away is out of the 170 reach)"): return
	# 세트 완성 시에만 철퇴 이펙트가 재생되고, 판정은 0.6초에 들어간다
	list=setup(true)
	c.vfx.clear()
	list[0].position=Vector2(560,704)
	var hp_before:float=list[0].hp
	c.perform_attack("main")
	c.arsenal.tick(.31)
	if not check(c.vfx.bursts.any(func(b):return b.has("duo_mace")) and is_equal_approx(list[0].hp,hp_before),"Set fist plays the mace effect from the wind-up and has not hit yet at 0.31s"): return
	c.arsenal.tick(.31)
	if not check(is_equal_approx(hp_before-list[0].hp,80.0),"Set fist lands its 80 damage when the mace reaches the floor (0.6s)"): return
	list=setup(false)
	c.vfx.clear()
	c.perform_attack("main")
	c.arsenal.tick(.31)
	if not check(not c.vfx.bursts.any(func(b):return b.has("duo_mace")),"Without the set the mace effect never plays"): return
	print("ALL PASS")
	quit(0)
