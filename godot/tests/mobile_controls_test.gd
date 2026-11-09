extends SceneTree

const Controls = preload("res://scripts/mobile_controls.gd")
const Player = preload("res://scripts/player.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func require(ok: bool, message: String) -> bool:
	if ok:
		print("PASS: ", message)
		return true
	push_error(message)
	quit(1)
	return false

func run_checks() -> void:
	var actions = ["move_left", "move_right", "aim_up", "aim_down", "attack", "attack_left", "attack_right", "attack_up", "attack_down", "jump", "dash", "heart_skill", "main_skill", "off_skill", "interact", "inventory", "equipment_lab"]
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var controls = Controls.new()
	root.add_child(controls)
	if not require(controls.buttons.any(func(item): return item["action"]=="jump") and controls.buttons.any(func(item): return item["action"]=="dash"), "Mobile exposes separate jump and dash buttons through the shared input actions"):
		return
	controls.set_process(false)
	controls.move_finger = 1
	controls.move_center = Vector2(100,300)
	controls.update_move_stick(Vector2(150,300))
	if not require(Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"), "Left dynamic stick drives movement only"):
		return
	controls.update_move_stick(Vector2(150,290))
	if not require(Input.is_action_pressed("move_right") and not Input.is_action_pressed("jump") and not Input.is_action_pressed("aim_up"), "Upward movement-stick input stays movement-only; the separate jump button owns jumping"):
		return
	var player:=Player.new()
	Controls.move_vector=Vector2(.73,-.31)
	if not require(player.mobile_dash_direction().is_equal_approx(Controls.move_vector.normalized()), "Mobile dash preserves the movement stick's free analog angle"):
		return
	Controls.move_vector=Vector2.ZERO
	player.facing=-1
	if not require(player.mobile_dash_direction()==Vector2.LEFT, "Neutral mobile dash still falls back to facing"):
		return
	player.free()
	controls.attack_finger = 2
	controls.attack_center = Vector2(650,300)
	controls.update_attack_stick(Vector2(600,275))
	if not require(Input.is_action_pressed("attack_left") and Input.is_action_pressed("attack_up") and Input.is_action_pressed("attack"), "Right dynamic stick aims diagonally and holds auto-fire"):
		return
	var analog_attack:=Vector2(Input.get_axis("attack_left","attack_right"),Input.get_axis("attack_up","attack_down"))
	if not require(analog_attack.normalized().is_equal_approx(controls.attack_stick.normalized()), "Mobile attack keeps the right stick's free analog angle"):
		return
	controls.release_attack()
	if not require(not Input.is_action_pressed("attack") and not Input.is_action_pressed("attack_left") and Input.is_action_pressed("move_right"), "Releasing attack finger stops fire without stopping movement"):
		return
	controls.release_movement()
	if not require(not Input.is_action_pressed("move_right") and controls.move_finger < 0 and controls.attack_finger < 0, "Releasing both fingers clears both temporary sticks"):
		return
	quit(0)
