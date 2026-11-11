extends SceneTree

const EXPECTED := ["exorcist-spearman","exorcist-archer","bell-exorcist","hunting-hawk"]

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
	world.floor_number=3
	world.new_run(3303)
	await frames(8)
	if not check(world.room.chapter==3 and not world.fog_layer.visible,"Floor 3 uses its own garrison presentation without Chapter 2 fog"): return
	if not check(world.title.text=="3챕터 · 퇴마단 주둔지","Chapter 3 shows only its chapter title without per-room names"): return
	for role in EXPECTED:
		if not check(ResourceLoader.exists("res://assets/actors/source/"+role+"-v1.png"),role+" atlas is packaged at the runtime path"): return
	if not check(ResourceLoader.exists("res://assets/environment/chapter3/exorcist-garrison-background-v1.png"),"Garrison background is packaged"): return
	if not check(ResourceLoader.exists("res://assets/actors/chapter3/soul-warden-game-v1.png"),"Soul Warden dedicated game pose is packaged"): return
	for path in ["res://assets/actors/chapter3/soul-warden-core-motion-v1.png","res://assets/actors/chapter3/soul-warden-basic-attacks-v1.png","res://assets/actors/chapter3/soul-warden-forced-extraction-motion-v1.png","res://assets/actors/chapter3/soul-warden-patterns-death-v1.png"]:
		if not check(ResourceLoader.exists(path),"Soul Warden animation sheet is packaged: "+path.get_file()): return

	var found:Dictionary={}
	for data in world.run["rooms"]:
		if int(data["id"])==int(world.run["goal"]) or bool(data.get("peaceful",false)): continue
		world.change_room(int(data["id"]),-1)
		await frames(2)
		for enemy in world.combat.living(): found[enemy.kind]=true
	for role in EXPECTED:
		if not check(found.has(role),role+" appears in seeded Chapter 3 rooms"): return

	world.change_room(int(world.run["goal"]),-1)
	await frames(3)
	var boss=world.combat.living()[0]
	if not check(boss.kind=="soul-warden" and boss.boss and boss.max_hp==760,"Chapter 3 ends with the Soul Warden boss"): return
	if not check(boss.special_cooldown>=10 and boss.special_cooldown<=15,"Boss special patterns begin after a random 10-15 second interval"): return
	boss.velocity=Vector2.ZERO
	boss.visual.update_soul_warden_pose()
	if not check(boss.visual.animation=="idle" and boss.visual.custom_columns==1 and boss.visual.frame_index==0,"Soul Warden idle is one completely static reference pose"): return
	boss.velocity=Vector2(40,0)
	boss.visual.update_soul_warden_pose()
	if not check(boss.visual.animation=="run" and boss.visual.custom_columns==4 and boss.visual.frame_index>=4 and boss.visual.frame_index<=9,"Soul Warden movement uses its dedicated image frames"): return
	boss.velocity=Vector2.ZERO

	world.combat.start_warden_pattern(boss,"capture")
	if not check(world.combat.warden_pattern_time==0.0,"Every boss pattern begins with the image-based captive-ghost extraction timeline"): return
	boss.visual.update_soul_warden_pose()
	if not check(boss.visual.animation=="extract" and boss.visual.custom_columns==4,"Soul Warden special patterns visibly begin with the extraction sheet"): return
	var expected_orbs:int=world.combat.warden_orbs_left
	for orb in range(expected_orbs):
		for hit in range(4): world.combat.hit_warden_orb(world.combat.warden_orb["pos"])
	if not check(not world.combat.warden_pattern_active and boss.stun>=1.99 and boss.vulnerable>=1.99,"Capture clears after 3-5 four-tap orbs and causes a two-second vulnerable groggy"): return
	var vulnerable_hp:float=boss.hp
	boss.take_damage(10)
	boss.take_damage(10)
	if not check(boss.hp==vulnerable_hp-30,"Every hit during groggy receives the 1.5x damage multiplier"): return
	world.combat.health=60
	world.combat.max_health=60
	world.combat.hurt_timer=0
	world.combat.start_warden_pattern(boss,"capture")
	world.combat.tick_warden_pattern(2.1)
	if not check(world.combat.health==45 and world.combat.warden_player_stagger==1.0 and not world.combat.warden_pattern_active,"A missed two-second orb deals 15 damage and starts a one-second player groggy"): return

	world.combat.health=50
	world.combat.max_health=70
	world.player.dash_max_charges=3
	world.player.dash_charges=3
	world.combat.start_warden_pattern(boss,"stakes")
	if not check(world.combat.max_health==55 and world.player.dash_max_charges==2 and world.combat.warden_heart_sealed,"Three stakes reduce max HP, dash capacity and seal the heart"): return
	for zone in world.combat.zones.duplicate():
		if zone.get("kind","")=="warden-stake": world.combat.damage_warden_stakes(zone["pos"],4,50)
	if not check(not world.combat.warden_pattern_active and world.combat.max_health==70 and world.combat.health==65 and boss.stun>=2.99,"Destroying all stakes restores five HP each and causes a three-second groggy"): return

	boss.hp=boss.max_hp*.25
	world.combat.start_warden_pattern(boss,"heart")
	if not check(world.combat.max_health==55 and world.player.visual.modulate==Color("11121a"),"Heart extraction returns the player to the black human form and lowers max HP"): return
	world.combat.tick_warden_pattern(5.1)
	if not check(not world.combat.warden_pattern_active and world.combat.max_health==70 and boss.stun>=1.99 and boss.special_cooldown==20,"A no-hit talisman survival restores the heart, groggies the boss and applies its longer cooldown"): return
	print("Chapter 3 garrison integration checks completed.")
	quit(0)
