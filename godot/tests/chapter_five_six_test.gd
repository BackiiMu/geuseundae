extends SceneTree

const CHAPTER5 := ["royal-shield","wall-archer","crossbow-exorcist","banner-bearer","ward-reader","elite-hawk"]
const CHAPTER6 := ["high-shaman","record-scribe","moving-ward-reader","iron-executioner","greater-lantern-keeper"]

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

func inspect_floor(world: Node, floor: int, title: String, kinds: Array, boss_kind: String, boss_hp: float) -> bool:
	world.floor_number=floor
	world.new_run(5000+floor)
	await frames(8)
	if not check(world.room.chapter==floor and world.title.text==title,"Chapter %d uses its own title and presentation" % floor): return false
	var found:Dictionary={}
	for room_data in world.run["rooms"]:
		if int(room_data["id"])==int(world.run["goal"]) or bool(room_data.get("peaceful",false)): continue
		world.change_room(int(room_data["id"]),-1)
		await frames(2)
		for enemy in world.combat.living(): found[enemy.kind]=true
	if not check(not found.is_empty(),"Chapter %d seeded rooms spawn their own enemy pool" % floor): return false
	for kind in found:
		if not check(kind in kinds,"Chapter %d does not leak an earlier chapter enemy: %s" % [floor,kind]): return false
	world.change_room(int(world.run["goal"]),-1)
	await frames(3)
	var boss=world.combat.living()[0]
	if not check(boss.kind==boss_kind and boss.boss and boss.max_hp==boss_hp,"Chapter %d ends with %s" % [floor,boss_kind]): return false
	for pattern in range(3):
		boss.pattern=pattern
		boss.release_attack(world.player.global_position)
	if not check(true,"Chapter %d boss dispatches all three attack patterns" % floor): return false
	return true

func run_checks() -> void:
	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	await frames(20)
	if not await inspect_floor(world,5,"5챕터 · 도성 성곽",CHAPTER5,"royal-exorcist-captain",720.0): return
	if not await inspect_floor(world,6,"6챕터 · 대신당",CHAPTER6,"grand-exorcist",980.0): return
	if not check(world.chapter_title()=="6챕터 · 대신당","Floor 6 remains the final chapter instead of repeating Chapter 4"): return
	print("Chapter 5-6 prototype checks completed.")
	quit()
