extends SceneTree
func _initialize() -> void: call_deferred("run_checks")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool,text: String) -> bool:
	if not ok:
		push_error(text)
		quit(1)
		return false
	print("PASS: ",text)
	return true
func run_checks() -> void:
	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	await frames(35)
	world.set_process(false)
	var combat=world.combat
	combat.set_physics_process(false)
	for enemy in combat.living(): enemy.take_damage(1000)
	combat.pickups.clear()
	combat.data["cleared"]=false
	world.player.position=Vector2(500,704)
	world.player.set_physics_process(false)
	var a=combat.spawn_enemy("warrior",Vector2(550,704),71)
	var b=combat.spawn_enemy("warrior",Vector2(580,704),72)
	combat.paused=false
	combat.heart_pending=[a,b]
	combat.heart_windup=.01
	combat._physics_process(.02)
	if not check(a.pull_remaining>0 and b.pull_remaining>0 and combat.heart_pending.is_empty(),"Heart pull releases every queued target"): return
	# One-way drop works through the platform without disabling solid-floor jumping.
	world.combat_enabled=false
	world.change_room(world.run["shop_room"],-1)
	var p=world.player
	var platform:Rect2=world.room.platforms[0]
	p.position=Vector2(platform.get_center().x,platform.position.y)
	p.velocity=Vector2.ZERO
	await frames(4)
	Input.action_press("aim_down")
	Input.action_press("jump")
	await frames(5)
	Input.action_release("jump")
	Input.action_release("aim_down")
	if not check(p.position.y>platform.position.y+8,"Down + jump drops through an upper platform"): return
	await frames(45)
	if not check(p.is_on_floor() and p.position.y<710,"Collision restores and catches the solid ground"): return
	Input.action_press("aim_down")
	Input.action_press("jump")
	await frames(4)
	Input.action_release("jump")
	Input.action_release("aim_down")
	if not check(p.position.y<690 and p.drop_timer==0,"Down + jump never disables a solid floor"): return
	quit(0)
