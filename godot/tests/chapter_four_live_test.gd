extends SceneTree

func _initialize() -> void: call_deferred("run_checks")
func frame() -> void: await physics_frame
func check(ok: bool, text: String) -> bool:
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

func observe(world, kind: String) -> bool:
	await clear_enemies(world.combat)
	world.player.position=Vector2(620,704)
	var enemy=world.combat.spawn_enemy(kind,Vector2(780,704),940)
	enemy.timer=0.0
	for tick in range(480):
		await frame()
		if not is_instance_valid(enemy): return false
		if kind=="chain-constable" and enemy.chain_pull_remaining>0: return true
		if kind=="shield-guard" and enemy.state=="recover": return true
		if kind=="tracking-hound" and enemy.charge_remaining>0: return true
		for zone in world.combat.zones:
			if kind=="brazier-ritualist" and zone["kind"]=="enemy-brazier-fire": return true
			if kind=="sealed-lantern-keeper" and zone["kind"]=="enemy-lantern-burst": return true
	return false

func run_checks() -> void:
	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	for i in range(20): await frame()
	world.floor_number=4
	world.new_run(4404)
	for i in range(8): await frame()
	world.combat.max_health=999.0
	world.combat.health=999.0
	for kind in ["chain-constable","shield-guard","brazier-ritualist","sealed-lantern-keeper","tracking-hound"]:
		if not check(await observe(world,kind),kind+" reaches its unique attack during live combat"): return
	var guard=world.combat.spawn_enemy("shield-guard",Vector2(780,704),941)
	guard.facing=-1.0
	world.player.position=Vector2(700,704)
	var before:float=guard.hp
	guard.take_damage(20.0)
	if not check(is_equal_approx(before-guard.hp,4.0),"shield guard reduces frontal damage by 80 percent"): return
	await clear_enemies(world.combat)
	var boss=world.combat.spawn_enemy("prison-shaman",Vector2(780,704),999)
	if not check(boss.soul_barrier_layers==3 and is_equal_approx(boss.hp,280.0),"prison shaman starts behind three Changgui barrier layers"): return
	boss.take_damage(80.0)
	if not check(boss.soul_barrier_layers==2 and is_equal_approx(boss.hp,280.0),"barrier absorbs damage before the low-HP body"): return
	boss.reflect_window=1.0
	var shots_before:int=world.combat.projectiles.size()
	boss.take_damage(20.0)
	if not check(world.combat.projectiles.size()==shots_before+1,"Dongja reflection returns an attack as a visible projectile"): return
	boss.reflect_window=0.0
	boss.take_damage(160.0)
	if not check(boss.dongja_rampage and boss.visual.role=="dongja-possession","Dongja swallows the shaman after the final barrier breaks"): return
	print("Chapter 4 live enemy behaviour checks completed.")
	quit(0)
