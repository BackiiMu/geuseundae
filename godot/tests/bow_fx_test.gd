extends SceneTree
# 누군가의 활: 화살은 pixelfx 화살 시트, 명중하면 화살쏘기 명중 연출, 차징 중에는 활·게이지를 그린다.
func _initialize() -> void: call_deferred("run_checks")
func check(ok: bool,message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		return
	print("PASS: ",message)
func run_checks() -> void:
	var world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	world.set_process(false)
	world.toggle_equipment_lab()
	var c=world.combat
	c.set_physics_process(false)
	world.reset_lab_targets()
	c.equipment["main"]="someone_bow"
	c.bow_charging=true
	c.bow_charge=.6
	c.bow_direction=Vector2.RIGHT
	c.queue_redraw()
	await physics_frame
	check(c.uses_charge_bow(),"Someone's bow is equipped")
	var list:Array=c.living()
	var enemy=list[0]
	enemy.hp=10000
	enemy.max_hp=10000
	enemy.position=world.player.position+Vector2(120,0)
	c.vfx.clear()
	c.projectiles.clear()
	c.fire_projectile(world.player.position+Vector2(0,-28),Vector2.RIGHT,18,true,"piercing_arrow")
	c.projectiles[0]["weapon"]="someone_bow"
	c.projectiles[0]["life"]=1.2
	c.set_physics_process(true)
	for i in range(40): await physics_frame
	c.set_physics_process(false)
	check(c.vfx.bursts.any(func(b):return b.get("key","")=="arrow-shot"),"Arrow hit plays the pixelfx arrow-shot impact")
	c.vfx.queue_redraw()
	await physics_frame
	print("ALL PASS")
	quit(0)
