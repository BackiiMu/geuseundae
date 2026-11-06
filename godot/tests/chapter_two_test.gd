extends SceneTree

const EXPECTED := ["changgui-remnant","mihokbul","hosikchong-wraith","mountain-tiger"]

func _initialize() -> void: call_deferred("run_checks")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
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
	await frames(20)
	world.floor_number=2
	world.new_run(2202)
	await frames(8)
	if not check(world.room.chapter==2 and world.fog_layer.visible,"Floor 2 uses the fog mountain background and screen veil"): return
	if not check(world.title.text.contains("2챕터 · 안개 낀 산"),"Chapter 2 title and mountain room names are active"): return
	for role in EXPECTED+["jangsan-shadow","jangsanbeom"]:
		if not check(ResourceLoader.exists("res://assets/actors/source/"+role+"-v1.png"),role+" atlas is packaged at the runtime path"): return
	var found:Dictionary={}
	for data in world.run["rooms"]:
		if int(data["id"])==int(world.run["goal"]) or bool(data.get("peaceful",false)): continue
		world.change_room(int(data["id"]),-1)
		await frames(2)
		for enemy in world.combat.living(): found[enemy.kind]=true
	for role in EXPECTED:
		if not check(found.has(role),role+" appears in the seeded Chapter 2 rooms"): return
	if not check(found.has("jangsan-shadow"),"Jangsanbeom Shadow appears as a seeded elite encounter"): return
	world.change_room(int(world.run["goal"]),-1)
	await frames(2)
	var boss=world.combat.living()[0]
	if not check(boss.kind=="jangsanbeom" and boss.jangsan_phase==1 and boss.max_hp==260,"Jangsanbeom starts with a separate 260 HP mimic phase"): return
	if not check(boss.visual.role==world.player.visual.role,"Phase 1 copies the player's current appearance"): return
	boss.take_damage(9999)
	if not check(boss.phase_transitioning and world.combat.boss_transitioning and not boss.dead,"Killing phase 1 freezes combat and starts the fog transformation"): return
	await frames(120)
	if not check(boss.jangsan_phase==2 and boss.max_hp==450 and boss.hp==450 and boss.visual.role=="jangsan-shadow","Phase 2 refills a separate 450 HP bar and uses the larger shadow atlas"): return
	var shadow_width:float=boss.visual.draw_size().x*boss.visual.scale_override
	boss.take_damage(9999)
	await frames(120)
	var beast_width:float=boss.visual.draw_size().x*boss.visual.scale_override
	if not check(boss.jangsan_phase==3 and boss.max_hp==850 and boss.hp==850,"Phase 3 refills a separate 850 HP bar"): return
	if not check(boss.visual.texture.resource_path=="res://assets/actors/source/jangsanbeom-v1.png" and beast_width>=shadow_width*2.9,"The final white-body red-face beast is about three times the shadow's size"): return
	print("Chapter 2 integration checks completed.")
	quit(0)
