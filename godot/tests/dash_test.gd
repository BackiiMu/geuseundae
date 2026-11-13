extends SceneTree
const Player = preload("res://scripts/player.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func step(count: int) -> void:
	for i in range(count): await physics_frame
func run_checks() -> void:
	Player.dash_to_move_direction=false
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
		p.dash_charges = p.dash_max_charges
		for action in ["move_left","move_right","aim_up","aim_down","attack_left","attack_right","attack_up","attack_down","dash"]: Input.action_release(action)
		await step(2)
		if direction.x<0: Input.action_press("attack_left")
		if direction.x>0: Input.action_press("attack_right")
		if direction.y<0: Input.action_press("attack_up")
		if direction.y>0: Input.action_press("attack_down")
		Input.action_press("dash")
		await step(2)
		if p.velocity.distance_to(direction.normalized()*680)>1:
			push_error("Wrong dash direction or diagonal speed: "+str(direction)+" actual "+str(p.velocity))
			quit(1)
			return
		print("PASS dash ",direction," speed ",p.velocity.length())
	for action in ["move_left","move_right","aim_up","aim_down","attack_left","attack_right","attack_up","attack_down","dash"]: Input.action_release(action)
	await step(2)
	p.dash_cooldown=0
	p.dash_charges=p.dash_max_charges
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
		p.dash_charges=p.dash_max_charges
		for action in p.tap_windows: p.tap_windows[action]=0.0
		Input.action_press("attack_right")
		Input.action_press("attack_up")
		Input.action_press(entry[0])
		await step(1)
		Input.action_release(entry[0])
		await step(3)
		Input.action_press(entry[0])
		await step(2)
		if p.velocity.distance_to(Vector2(1,-1).normalized()*680)>1:
			push_error("Double-tap dash did not follow attack aim: "+str(entry[0])+" actual "+str(p.velocity))
			quit(1)
			return
		Input.action_release(entry[0])
		Input.action_release("attack_right")
		Input.action_release("attack_up")
		await step(2)
	print("PASS directional double taps trigger a dash toward the 8-way attack aim")
	p.dash_cooldown=0
	p.dash_time=0
	p.dash_charges=p.dash_max_charges
	p.jumped_since_floor=false
	p.handle_jump_press(Vector2.RIGHT)
	if p.buffered_jump<=0 or p.dash_time>0:
		push_error("First jump-button press must buffer a jump, not dash")
		quit(1)
		return
	print("PASS first jump-button press requests a jump")
	p.dash_cooldown=0
	p.dash_time=0
	p.dash_charges=p.dash_max_charges
	p.buffered_jump=0
	p.jumped_since_floor=true
	p.handle_jump_press(Vector2(1,-1))
	await step(1)
	if p.dash_direction.distance_to(Vector2(1,-1).normalized())>.01 or p.buffered_jump>0:
		push_error("Airborne jump-button press must use the same aimed dash: "+str(p.dash_direction))
		quit(1)
		return
	print("PASS airborne jump-button press performs the same 8-way aimed dash")
	Input.action_press("attack_right")
	Input.action_press("attack_up")
	Player.dash_to_move_direction=true
	if not p.dash_input_direction(-1.0,false).is_equal_approx(Vector2.LEFT):
		push_error("Move-direction option must ignore attack aim and dash toward held movement")
		quit(1)
		return
	if not p.dash_input_direction(0.0,false).is_equal_approx(Vector2(p.facing,0)):
		push_error("Move-direction option must fall back to facing while movement is neutral")
		quit(1)
		return
	print("PASS move-direction setting overrides aim and uses facing while neutral")
	Player.dash_to_move_direction=false
	Input.action_release("attack_right")
	Input.action_release("attack_up")
	quit(0)
