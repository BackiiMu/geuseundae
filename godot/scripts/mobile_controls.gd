extends Node2D

var world: Node2D
var move_finger := -1
var attack_finger := -1
var move_center := Vector2.ZERO
var attack_center := Vector2.ZERO
var move_stick := Vector2.ZERO
var attack_stick := Vector2.ZERO
var buttons: Array = []
var hidden_for_ui := false
const MOVE_ACTIONS = ["move_left", "move_right"]
const ATTACK_ACTIONS = ["attack_left", "attack_right", "attack_up", "attack_down"]
const STICK_RADIUS := 52.0
# Movement-stick vector shared with the player so mobile dashes follow movement.
static var move_vector := Vector2.ZERO

func _ready() -> void:
	var specs = [
		["jump", "점프", Vector2(686,324), 24.0],
		["dash", "대시", Vector2(706,257), 24.0],
		["heart_skill", "심장", Vector2(548,366), 23.0],
		["main_skill", "주무기", Vector2(578,292), 21.0],
		["off_skill", "보조", Vector2(630,251), 21.0],
		["interact", "사용", Vector2(739,187), 22.0],
		["inventory", "가방", Vector2(739,108), 20.0],
		["equipment_lab", "시험", Vector2(688,108), 20.0]
	]
	for spec in specs:
		var button := TouchScreenButton.new()
		button.position = spec[2]
		var shape := CircleShape2D.new()
		shape.radius = spec[3]
		button.shape = shape
		button.action = spec[0]
		button.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
		add_child(button)
		buttons.append({"node":button, "text":spec[1], "radius":spec[3], "action":spec[0]})

func over_button(pos: Vector2) -> bool:
	for item in buttons:
		if item["node"].visible and pos.distance_to(Vector2(item["node"].position)) <= float(item["radius"]) + 8.0:
			return true
	return false

func release_actions(actions: Array) -> void:
	for action in actions:
		Input.action_release(action)

func release_movement() -> void:
	release_actions(MOVE_ACTIONS)
	move_stick = Vector2.ZERO
	move_vector = Vector2.ZERO
	move_finger = -1

func release_attack() -> void:
	release_actions(ATTACK_ACTIONS)
	Input.action_release("attack")
	attack_stick = Vector2.ZERO
	attack_finger = -1

func release_all() -> void:
	release_movement()
	release_attack()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()

func _input(event: InputEvent) -> void:
	if hidden_for_ui:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if over_button(event.position):
				return
			if event.position.x < get_viewport_rect().size.x * 0.5 and move_finger < 0:
				move_finger = event.index
				move_center = event.position
				update_move_stick(event.position)
			elif event.position.x >= get_viewport_rect().size.x * 0.5 and attack_finger < 0:
				attack_finger = event.index
				attack_center = event.position
				update_attack_stick(event.position)
		elif event.index == move_finger:
			release_movement()
		elif event.index == attack_finger:
			release_attack()
	elif event is InputEventScreenDrag:
		if event.index == move_finger:
			update_move_stick(event.position)
		elif event.index == attack_finger:
			update_attack_stick(event.position)

func update_move_stick(pos: Vector2) -> void:
	move_stick = (pos - move_center).limit_length(STICK_RADIUS) / STICK_RADIUS
	move_vector = move_stick
	Input.action_press("move_left", absf(move_stick.x)) if move_stick.x < -0.18 else Input.action_release("move_left")
	Input.action_press("move_right", absf(move_stick.x)) if move_stick.x > 0.18 else Input.action_release("move_right")

func update_attack_stick(pos: Vector2) -> void:
	attack_stick = (pos - attack_center).limit_length(STICK_RADIUS) / STICK_RADIUS
	Input.action_press("attack_left", absf(attack_stick.x)) if attack_stick.x < -0.18 else Input.action_release("attack_left")
	Input.action_press("attack_right", absf(attack_stick.x)) if attack_stick.x > 0.18 else Input.action_release("attack_right")
	Input.action_press("attack_up", absf(attack_stick.y)) if attack_stick.y < -0.18 else Input.action_release("attack_up")
	Input.action_press("attack_down", absf(attack_stick.y)) if attack_stick.y > 0.18 else Input.action_release("attack_down")
	if attack_stick.length() > 0.18:
		Input.action_press("attack")
	else:
		Input.action_release("attack")

func _process(_delta: float) -> void:
	var modal: bool = world.combat.inventory.visible or world.floor_map_open or (is_instance_valid(world.merchant) and world.merchant.opened)
	if modal and not hidden_for_ui:
		release_all()
		for item in buttons:
			Input.action_release(item["action"])
	hidden_for_ui = modal
	for item in buttons:
		var show := not modal
		if item["action"] == "main_skill":
			show = show and world.combat.equipped("main").get("skill", "") != ""
		if item["action"] == "off_skill":
			show = show and (world.combat.equipped("off").get("skill", "") != "" or world.combat.duo_set())
		item["node"].visible = show
	queue_redraw()

func draw_stick(center: Vector2, stick: Vector2, attack_side := false) -> void:
	draw_circle(center, STICK_RADIUS + 6.0, Color(.10,.08,.16,.62) if attack_side else Color(.07,.12,.16,.58))
	draw_arc(center, STICK_RADIUS + 6.0, 0, TAU, 40, Color(.72,.60,.78,.8) if attack_side else Color(.7,.8,.76,.72), 2)
	draw_circle(center + stick * STICK_RADIUS, 23, Color(.7,.55,.76,.72) if attack_side else Color(.7,.8,.73,.62))

func _draw() -> void:
	if hidden_for_ui:
		return
	if move_finger >= 0:
		draw_stick(move_center, move_stick)
	if attack_finger >= 0:
		draw_stick(attack_center, attack_stick, true)
	var font = preload("res://assets/fonts/NotoSansKR-Semibold.ttf")
	for item in buttons:
		if not item["node"].visible:
			continue
		var pos: Vector2 = item["node"].position
		var active := Input.is_action_pressed(item["action"])
		draw_circle(pos, item["radius"], Color(.25,.4,.38,.8) if active else Color(.07,.12,.16,.65))
		draw_arc(pos, item["radius"], 0, TAU, 32, Color(.68,.78,.72,.8), 2)
		draw_string(font, pos + Vector2(-font.get_string_size(item["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x / 2, 5), item["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e2e5d3"))
