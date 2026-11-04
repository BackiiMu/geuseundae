extends SceneTree
const Player = preload("res://scripts/player.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func step(count: int) -> void:
	for i in range(count): await physics_frame
func run_checks() -> void:
	var world = load("res://scenes/random_run.tscn").instantiate()
	world.combat_enabled=false
	root.add_child(world)
	await step(3)
	world.set_process(false)
	world.player.controls_enabled = false
	var p = Player.new()
	root.add_child(p)
	await step(2)
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
		p.position = Vector2(500,200)
		p.velocity = Vector2.ZERO
		p.dash_time = 0
		p.dash_cooldown = 0
		for action in ["move_left","move_right","aim_up","aim_down","dash"]: Input.action_release(action)
		await step(2)
		if direction.x<0: Input.action_press("move_left")
		if direction.x>0: Input.action_press("move_right")
		if direction.y<0: Input.action_press("aim_up")
		if direction.y>0: Input.action_press("aim_down")
		Input.action_press("dash")
		await step(2)
		if p.velocity.distance_to(direction.normalized()*680)>1:
			push_error("Wrong dash direction or diagonal speed: "+str(direction)+" actual "+str(p.velocity))
			quit(1)
			return
		print("PASS dash ",direction," speed ",p.velocity.length())
	for action in ["move_left","move_right","aim_up","aim_down","dash"]: Input.action_release(action)
	await step(2)
	p.dash_cooldown=0
	p.facing=-1
	Input.action_press("dash")
	await step(2)
	if p.velocity!=Vector2(-680,0):
		push_error("Neutral dash must use facing direction")
		quit(1)
		return
	print("PASS neutral dash uses facing direction")
	Input.action_release("dash")
	await step(2)
	for entry in [["move_left",Vector2.LEFT],["move_right",Vector2.RIGHT],["aim_up",Vector2.UP],["aim_down",Vector2.DOWN]]:
		p.dash_cooldown=0
		p.dash_time=0
		for action in p.tap_windows: p.tap_windows[action]=0.0
		Input.action_press(entry[0])
		await step(1)
		Input.action_release(entry[0])
		await step(3)
		Input.action_press(entry[0])
		await step(2)
		if p.velocity.distance_to(Vector2(entry[1])*680)>1:
			push_error("Double-tap dash failed: "+str(entry[0])+" actual "+str(p.velocity))
			quit(1)
			return
		Input.action_release(entry[0])
		await step(2)
	print("PASS directional double taps trigger four-way dash")
	p.dash_cooldown=0
	p.dash_time=0
	for action in p.tap_windows: p.tap_windows[action]=0.0
	Input.action_press("jump")
	await step(1)
	Input.action_release("jump")
	await step(3)
	Input.action_press("jump")
	await step(2)
	Input.action_release("jump")
	if p.velocity.distance_to(Vector2.UP*680)>1 or p.buffered_jump>0:
		push_error("Double jump-key dash failed or also buffered a jump: "+str(p.velocity))
		quit(1)
		return
	print("PASS double jump key dashes upward without extra jump")
	p.dash_cooldown=0
	p.dash_time=0
	for action in p.tap_windows: p.tap_windows[action]=0.0
	Input.action_press("move_right")
	Input.action_press("jump")
	await step(1)
	Input.action_release("jump")
	await step(3)
	Input.action_press("jump")
	await step(2)
	Input.action_release("jump")
	Input.action_release("move_right")
	if p.velocity.distance_to(Vector2(1,-1).normalized()*680)>1:
		push_error("Moving double jump-key dash must go diagonally upward: "+str(p.velocity))
		quit(1)
		return
	print("PASS held movement plus double jump key dashes diagonally upward")
	quit(0)
