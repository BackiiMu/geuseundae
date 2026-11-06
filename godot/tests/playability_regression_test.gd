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
	# Down alone drops through a one-way platform without disabling solid floors.
	world.combat_enabled=false
	world.change_room(world.run["shop_room"],-1)
	var p=world.player
	var platform:Rect2=world.room.platforms[0]
	p.position=Vector2(platform.get_center().x,platform.position.y)
	p.velocity=Vector2.ZERO
	await frames(4)
	Input.action_press("aim_down")
	await frames(5)
	Input.action_release("aim_down")
	if not check(p.position.y>platform.position.y+8,"Down drops through an upper platform"): return
	await frames(45)
	if not check(p.is_on_floor() and p.position.y<710,"Collision restores and catches the solid ground"): return
	Input.action_press("aim_down")
	await frames(4)
	Input.action_release("aim_down")
	if not check(p.is_on_floor() and p.position.y>690 and p.drop_timer==0,"Down never disables a solid floor"): return
	p.face_horizontal_toward(p.global_position.x-100)
	if not check(p.facing<0,"Player can face left toward the mouse attack position"): return
	p.face_horizontal_toward(p.global_position.x+100)
	if not check(p.facing>0,"Player can face right toward the mouse attack position"): return
	Input.action_press("attack_left")
	if not check(combat.attack_input_held() and combat.aim().is_equal_approx(Vector2.LEFT),"Left arrow attacks left without a mouse"): return
	Input.action_press("move_right")
	p.facing=1
	p._physics_process(.016)
	Input.action_release("move_right")
	if not check(p.facing<0,"Attack direction takes priority over movement when turning the character"): return
	Input.action_release("attack_left")
	Input.action_press("attack")
	Input.action_press("move_right")
	p._physics_process(.016)
	Input.action_release("move_right")
	Input.action_release("attack")
	if not check(p.facing<0,"Vertical attack aim preserves the last attack-facing direction"): return
	Input.action_press("attack_up")
	if not check(combat.attack_input_held() and combat.aim().is_equal_approx(Vector2.UP),"Up arrow attacks upward without a mouse"): return
	Input.action_release("attack_up")
	Input.action_press("attack_right")
	Input.action_press("attack_down")
	if not check(combat.aim().is_equal_approx(Vector2(1,1).normalized()),"Two arrow keys support diagonal attacks"): return
	Input.action_release("attack_right")
	Input.action_release("attack_down")
	# The first jump-button press requests a jump. Until landing, every later
	# press uses the exact same aimed dash path as the dedicated dash button.
	p.set_physics_process(false)
	p.dash_cooldown=0.0
	p.dash_time=0.0
	p.jumped_since_floor=false
	var first_jump_dash=p.handle_jump_press(Vector2.RIGHT)
	if not check(not first_jump_dash and p.dash_time==0.0,"First jump-button press remains a normal jump"): return
	p.jumped_since_floor=true
	var second_jump_dash=p.handle_jump_press(Vector2(-1,-1))
	if not check(second_jump_dash and p.dash_time>0.0 and p.dash_direction.is_equal_approx(Vector2(-1,-1).normalized()),"Airborne jump-button press dashes in the attack direction"): return
	quit(0)
