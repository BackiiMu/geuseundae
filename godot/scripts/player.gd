extends CharacterBody2D
const ActorSprite=preload("res://scripts/actor_sprite.gd")
var visual: Node2D

const SPEED = 280.0
const JUMP = -760.0
const GRAVITY = 1700.0
const DASH_SPEED = 680.0
var coyote := 0.0
var buffered_jump := 0.0
var dash_direction := Vector2.RIGHT
var dash_time := 0.0
var dash_cooldown := 0.0
var facing := 1.0
var spawn := Vector2(360, 590)
var controls_enabled := true
var movement_multiplier := 1.0
var drop_timer := 0.0
var attack_pose := 0.0
var attack_lean := 0.0
var camera: Camera2D
const DOUBLE_TAP_WINDOW := .24
var tap_windows := {"move_left":0.0,"move_right":0.0,"aim_up":0.0,"aim_down":0.0,"jump":0.0}

func _ready() -> void:
	for action in ["aim_up", "aim_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var direction_keys := {"aim_up": [KEY_W], "aim_down": [KEY_S]}
	for action in direction_keys:
		for key in direction_keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(26, 46)
	shape.shape = box
	shape.position.y = -23
	add_child(shape)
	camera = Camera2D.new()
	camera.position.y = -90
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2172
	camera.limit_bottom = 724
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)
	visual=ActorSprite.new()
	visual.actor=self
	visual.combat=get_parent().get("combat")
	visual.role="songaksi"
	add_child(visual)
	queue_redraw()

func respawn() -> void:
	position = spawn
	velocity = Vector2.ZERO
	dash_time = 0.0
	for action in tap_windows: tap_windows[action]=0.0
	camera.reset_smoothing()

func start_dash(direction: Vector2) -> void:
	if dash_cooldown>0: return
	dash_direction = direction.normalized() if direction.length_squared()>0 else Vector2(facing,0)
	dash_time = .12
	dash_cooldown = .65
	buffered_jump = 0
	for action in tap_windows: tap_windows[action]=0.0

func register_double_tap(action: String,direction: Vector2) -> bool:
	if not Input.is_action_just_pressed(action): return false
	if float(tap_windows[action])>0 and dash_cooldown<=0:
		start_dash(direction)
		return true
	tap_windows[action]=DOUBLE_TAP_WINDOW
	return false

func face_horizontal_toward(world_x: float) -> void:
	var difference := world_x - global_position.x
	if absf(difference) > 1.0:
		facing = signf(difference)
		queue_redraw()

func face_mouse_for_attack() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("mobile"):
		return
	if OS.get_cmdline_user_args().has("--touch"):
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		face_horizontal_toward(get_global_mouse_position().x)

func try_drop_through_platform() -> bool:
	if not is_on_floor():
		return false
	for i in range(get_slide_collision_count()):
		var hit := get_slide_collision(i)
		if hit.get_normal().y < -0.7 and hit.get_collider().get_meta("one_way", false):
			drop_timer = 0.2
			set_collision_mask_value(1, false)
			position.y += 6
			velocity.y = 180
			buffered_jump = 0
			coyote = 0
			return true
	return false

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		return
	if get_parent().has_method("combat_death") and is_instance_valid(get_parent().combat) and get_parent().combat.paused:
		return
	attack_pose=maxf(0,attack_pose-delta)
	queue_redraw()
	if Input.is_action_just_pressed("restart"):
		respawn()
	drop_timer=maxf(0,drop_timer-delta)
	set_collision_mask_value(1,drop_timer<=0)
	if Input.is_action_just_pressed("aim_down"):
		try_drop_through_platform()
	coyote = 0.12 if is_on_floor() else maxf(0.0, coyote - delta)
	buffered_jump = maxf(0.0, buffered_jump - delta)
	var axis := Input.get_axis("move_left", "move_right")
	var attack_axis := Input.get_axis("attack_left", "attack_right")
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		face_mouse_for_attack()
	elif attack_axis != 0:
		facing = signf(attack_axis)
		queue_redraw()
	elif axis != 0:
		facing = signf(axis)
		queue_redraw()
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	for action in tap_windows: tap_windows[action]=maxf(0,float(tap_windows[action])-delta)
	var input_direction := Vector2(axis,Input.get_axis("aim_up","aim_down"))
	var double_dash := false
	var mobile_mode := OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--touch")
	if not mobile_mode:
		double_dash = register_double_tap("move_left",Vector2.LEFT) or double_dash
		double_dash = register_double_tap("move_right",Vector2.RIGHT) or double_dash
		double_dash = register_double_tap("aim_up",Vector2.UP) or double_dash
		double_dash = register_double_tap("aim_down",Vector2.DOWN) or double_dash
		# A double jump-key press dashes along the jump arc: straight up at rest,
		# or diagonally upward while a horizontal movement key is held.
		double_dash = register_double_tap("jump",Vector2(axis,-1)) or double_dash
	if Input.is_action_just_pressed("dash") and dash_cooldown<=0:
		start_dash(input_direction)
		double_dash = true
	if Input.is_action_just_pressed("jump") and drop_timer<=0 and not double_dash:
		buffered_jump = .14
	if dash_time > 0:
		dash_time -= delta
		velocity = dash_direction * DASH_SPEED
	else:
		velocity.x = move_toward(velocity.x, axis * SPEED * movement_multiplier, 2200 * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, 1000)
		if buffered_jump > 0 and coyote > 0 and drop_timer<=0:
			velocity.y = JUMP
			buffered_jump = 0
			coyote = 0
		if Input.is_action_just_released("jump") and velocity.y < -280:
			velocity.y = -280
	move_and_slide()
	if position.y > 810:
		respawn()
