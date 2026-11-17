extends SceneTree

const Catalog = preload("res://scripts/room_catalog.gd")
const RoomView = preload("res://scripts/room_view.gd")
const CombatDirector = preload("res://scripts/combat_director.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func require(ok: bool,message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
	return ok

func run_checks() -> void:
	for key in ["collapsed_house","rotten_bridge","ritual_yard"]:
		var definition:Dictionary=Catalog.templates()[key]
		if not require(not definition.get("walls",[]).is_empty(),key+" needs authored walls"): return
		var room:=RoomView.new()
		room.chapter=1 if key=="collapsed_house" else 2 if key=="rotten_bridge" else 3
		root.add_child(room)
		room.build(definition,1)
		await physics_frame
		if not require(room.solid_walls.size()==definition["walls"].size(),key+" wall bodies missing"): return
		var wall:Array=definition["walls"][0]
		var y:float=float(wall[1])+float(wall[3])*.5
		var query:=PhysicsRayQueryParameters2D.create(Vector2(wall[0]-40,y),Vector2(wall[0]+wall[2]+40,y),1)
		if not require(not room.get_world_2d().direct_space_state.intersect_ray(query).is_empty(),key+" wall does not block projectiles"): return
		root.remove_child(room)
		room.queue_free()
		await physics_frame
	var combat:=CombatDirector.new()
	combat.fire_projectile(Vector2.ZERO,Vector2.RIGHT,1,true,"shot")
	combat.fire_projectile(Vector2.ZERO,Vector2.RIGHT,1,true,"piercing_arrow")
	combat.fire_projectile(Vector2.ZERO,Vector2.RIGHT,1,true,"tiger")
	combat.fire_projectile(Vector2.ZERO,Vector2.RIGHT,1,true,"whistle")
	if not require(not bool(combat.projectiles[0]["wall_piercing"]),"normal shot must stop at walls"): return
	if not require(not bool(combat.projectiles[1]["wall_piercing"]),"enemy-piercing arrow must still stop at walls"): return
	if not require(bool(combat.projectiles[2]["wall_piercing"]),"tiger spirit wall exception missing"): return
	if not require(bool(combat.projectiles[3]["wall_piercing"]),"whistle wall exception missing"): return
	print("PASS: authored walls block movement/projectiles and explicit wall-piercing stays separate")
	quit(0)
