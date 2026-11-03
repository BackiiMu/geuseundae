extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func check_ok(ok: bool, message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
		return false
	print("PASS: ", message)
	return true

func run() -> void:
	var world = load("res://scenes/courtyard.tscn").instantiate()
	root.add_child(world)
	await frames(45)
	var p = world.player
	if not check_ok(p.is_on_floor() and absf(p.position.y - 610) < 3, "Spawn settles on courtyard floor"):
		return
	Input.action_press("jump")
	await frames(1)
	# Keep jump held, then release after reaching the upper part of the arc.
	await frames(22)
	if not check_ok(p.position.y < 480, "Jump reaches the intended platform height"):
		return
	Input.action_release("jump")
	await frames(70)
	if not check_ok(p.is_on_floor(), "Jump lands without falling through the floor"):
		return
	Input.action_press("move_right")
	for step in range(24):
		Input.action_press("jump")
		await frames(26)
		Input.action_release("jump")
		await frames(24)
	Input.action_release("move_right")
	await frames(80)
	if not check_ok(p.position.x > 2050 and p.position.x < 2172 and p.is_on_floor(), "Courtyard-to-shrine route is traversable and right boundary holds"):
		print("Final position: ", p.position)
		return
	p.respawn()
	await frames(30)
	if not check_ok(absf(p.position.x - 360) < 2, "Restart returns to courtyard spawn"):
		return
	print("Movement smoke checks completed.")
	quit(0)
