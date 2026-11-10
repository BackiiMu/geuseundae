extends SceneTree

func _initialize() -> void: call_deferred("run_checks")
func frame() -> void: await physics_frame
func check(ok: bool,text: String) -> bool:
	if not ok:
		push_error(text)
		quit(1)
		return false
	print("PASS: ",text)
	return true

func clear_enemies(combat) -> void:
	for enemy in combat.enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	combat.enemies.clear()
	combat.zones.clear()
	await frame()

func observe(world,kind: String) -> bool:
	await clear_enemies(world.combat)
	var spawn:Vector2=world.player.position+Vector2(125,-145 if kind=="hunting-hawk" else 0)
	var enemy=world.combat.spawn_enemy(kind,spawn,900)
	enemy.timer=0
	for tick in range(420):
		await frame()
		if kind=="exorcist-spearman" and enemy.slam_pending: return true
		if kind=="hunting-hawk" and enemy.state=="dive": return true
		for zone in world.combat.zones:
			if kind=="exorcist-archer" and zone["kind"]=="enemy-arrow-rain": return true
			if kind=="bell-exorcist" and zone["kind"]=="enemy-seal": return true
	return false

func run_checks() -> void:
	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	for i in range(20): await frame()
	world.floor_number=3
	world.new_run(3303)
	for i in range(8): await frame()
	world.combat.max_health=999
	world.combat.health=999
	world.player.position=Vector2(620,704)
	for kind in ["exorcist-spearman","exorcist-archer","bell-exorcist","hunting-hawk"]:
		if not check(await observe(world,kind),kind+" autonomously reaches its unique attack during live combat"): return
	print("Chapter 3 live enemy behaviour checks completed.")
	quit(0)
