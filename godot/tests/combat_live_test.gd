extends SceneTree
func _initialize() -> void: call_deferred("run_checks")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func fail(text: String) -> void:
	push_error(text)
	quit(1)
func run_checks() -> void:
	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	await frames(35)
	world.set_process(false)
	var combat=world.combat
	# Isolate one actual AI enemy and use real attack input with live physics ticks.
	for foe in combat.living(): foe.take_damage(1000)
	combat.pickups.clear()
	combat.data["cleared"]=false
	world.player.position=Vector2(500,704)
	world.player.facing=1
	combat.health=60
	var enemy=combat.spawn_enemy("warrior",Vector2(565,704),91)
	Input.action_press("attack")
	await frames(120)
	Input.action_release("attack")
	if not enemy.dead:
		fail("Live melee input did not kill a nearby enemy")
		return
	print("PASS: real attack input kills an AI enemy during live physics")
	# Test the living enemy's attack timings by standing in melee range without attacking.
	combat.data["cleared"]=false
	combat.health=60
	combat.hurt_timer=0
	world.player.position=Vector2(700,704)
	var foe=combat.spawn_enemy("warrior",Vector2(735,704),92)
	await frames(180)
	if combat.health>=60:
		fail("Enemy AI never damaged player")
		return
	print("PASS: enemy telegraph and strike damage a stationary player")
	# Projectiles and temporary boss run for enough ticks to cover all AI patterns.
	world.change_room(world.run["goal"],-1)
	var boss=combat.living()[0]
	world.player.position=Vector2(400,704)
	world.player.set_physics_process(false)
	combat.health=60
	combat.hurt_timer=100
	await frames(800)
	if boss.phase_counter<3:
		fail("Boss AI did not cycle its patterns")
		return
	print("PASS: boss AI cycles patterns and projectile physics without runtime errors")
	quit(0)
