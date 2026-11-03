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

func _ready() -> void:
	for action in ["aim_up", "aim_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var direction_keys := {"aim_up": [KEY_W, KEY_UP], "aim_down": [KEY_S, KEY_DOWN]}
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
	camera.reset_smoothing()

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
	if is_on_floor() and Input.is_action_pressed("aim_down") and Input.is_action_just_pressed("jump"):
		for i in range(get_slide_collision_count()):
			var hit=get_slide_collision(i)
			if hit.get_normal().y < -.7 and hit.get_collider().get_meta("one_way",false):
				drop_timer=.2
				set_collision_mask_value(1,false)
				position.y+=6
				velocity.y=180
				buffered_jump=0
				coyote=0
	coyote = 0.12 if is_on_floor() else maxf(0.0, coyote - delta)
	buffered_jump = maxf(0.0, buffered_jump - delta)
	if Input.is_action_just_pressed("jump") and drop_timer<=0:
		buffered_jump = 0.14
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0:
		facing = signf(axis)
		queue_redraw()
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0:
		var direction := Vector2(axis, Input.get_axis("aim_up", "aim_down"))
		dash_direction = direction.normalized() if direction.length_squared() > 0 else Vector2(facing, 0)
		dash_time = 0.12
		dash_cooldown = 0.65
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
