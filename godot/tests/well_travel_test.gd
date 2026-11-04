extends SceneTree

func _initialize() -> void: call_deferred("run_checks")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func require(ok: bool, message: String) -> bool:
	if ok:
		print("PASS: ", message)
		return true
	push_error(message)
	quit(1)
	return false

func run_checks() -> void:
	var world = load("res://scenes/random_run.tscn").instantiate()
	world.combat_enabled = false
	root.add_child(world)
	await frames(3)
	var source: int = world.current_id
	world.open_floor_map()
	world.close_floor_map()
	if not require(world.current_id == source and not world.traveling, "closing the well map cancels without moving"): return
	var destination: int = world.run["rooms"][source]["links"][0]
	world.run["rooms"][destination]["visited"] = true
	world.begin_well_travel(destination)
	if not require(world.traveling and world.travel_phase == "well_enter", "choosing a room starts the well-enter sequence"): return
	await frames(42)
	if not require(world.current_id == destination and world.travel_phase == "well_exit", "the room changes at the submerged transition point"): return
	await frames(48)
	if not require(not world.traveling and world.player.visual.visible, "the player emerges and controls are restored"): return
	world.begin_portal_travel(source)
	if not require(world.travel_phase == "portal_enter", "a normal room link uses the shadow-portal transition"): return
	await frames(34)
	if not require(world.current_id == source and not world.traveling, "the portal changes rooms after its entry animation"): return
	quit(0)
