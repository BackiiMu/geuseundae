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
	var elite:Dictionary={}
	for enemy in world.combat.living(): elite[enemy.kind]=enemy
	for role in EXPECTED:
		if not check(elite.has(role),role+" joins the final command-tent formation"): return

	var target:Vector2=world.player.global_position+Vector2(110,-20)
	var spear=elite["exorcist-spearman"]
	spear.release_attack(target)
	if not check(spear.slam_pending and spear.velocity.y<0,"Spearman uses a jumping ground slam instead of a forward swing"): return
	var archer=elite["exorcist-archer"]
	var before:int=world.combat.zones.size()
	archer.release_attack(target)
	if not check(world.combat.zones.size()==before+3,"Archer schedules three vertical arrow impacts"): return
	var bell=elite["bell-exorcist"]
	before=world.combat.zones.size()
	bell.release_attack(target)
	if not check(world.combat.zones.size()==before+1 and world.combat.zones[-1]["kind"]=="enemy-seal","Bell exorcist creates a persistent floor seal"): return
	var hawk=elite["hunting-hawk"]
	hawk.release_attack(target)
	if not check(hawk.state=="dive" and hawk.hawk_dive_remaining>0 and hawk.max_hp==32,"Hunting hawk is a weak diagonal dive attacker"): return
	print("Chapter 3 garrison integration checks completed.")
	quit(0)
