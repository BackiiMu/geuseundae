extends Node2D

const MOVE_RING=preload("res://assets/ui/mobile/move-ring-v1.png")
const MOVE_KNOB=preload("res://assets/ui/mobile/move-knob-v1.png")
const ATTACK_RING=preload("res://assets/ui/mobile/attack-ring-v1.png")
const ATTACK_HAND=preload("res://assets/ui/mobile/attack-hand-v1.png")
const BUTTON_TEXTURES={
	"jump":preload("res://assets/ui/mobile/jump-button-v1.png"),
	"dash":preload("res://assets/ui/mobile/dash-button-v1.png"),
	"heart":preload("res://assets/ui/mobile/heart-button-v1.png"),
	"main":preload("res://assets/ui/mobile/main-skill-button-v1.png"),
	"off":preload("res://assets/ui/mobile/off-skill-button-v1.png")
}

var world: Node2D
var move_finger := -1
var attack_finger := -1
var move_center := Vector2(94,338)
var attack_center := Vector2(638,338)
var move_stick := Vector2.ZERO
var attack_stick := Vector2.ZERO
var buttons: Array = []
var hidden_for_ui := false
const MOVE_ACTIONS = ["move_left", "move_right", "drop_down"]
const ATTACK_ACTIONS = ["attack_left", "attack_right", "attack_up", "attack_down"]
const STICK_RADIUS := 52.0
const MOVE_CENTER := Vector2(94,338)
const ATTACK_CENTER := Vector2(638,338)
const JUMP_CENTER := Vector2(638,258)
const DASH_CENTER := Vector2(712,338)
const SKILL_Y := 382.0
# Movement-stick vector shared with the player so mobile dashes follow movement.
static var move_vector := Vector2.ZERO

func _ready() -> void:
	var specs = [
		["jump", "jump", JUMP_CENTER, 25.0],
		["dash", "dash", DASH_CENTER, 24.0],
		["heart_skill", "heart", Vector2.ZERO, 22.0],
		["main_skill", "main", Vector2.ZERO, 22.0],
		["off_skill", "off", Vector2.ZERO, 22.0]
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

func release_interact() -> void:
	Input.action_release("interact")

func contextual_interaction_available() -> bool:
	return is_instance_valid(world) and is_instance_valid(world.hint) and not str(world.hint.text).is_empty()

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
			if event.position.distance_to(MOVE_CENTER)<=STICK_RADIUS+18 and move_finger < 0:
				move_finger = event.index
				move_center = MOVE_CENTER
				update_move_stick(event.position)
			elif event.position.distance_to(ATTACK_CENTER)<=STICK_RADIUS+20 and attack_finger < 0:
				if contextual_interaction_available():
					Input.action_press("interact")
					call_deferred("release_interact")
					return
				attack_finger = event.index
				attack_center = ATTACK_CENTER
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
	# 아래로 충분히 기울였을 때만 발판 통과를 요청한다. 작은 대각선 입력은
	# 걷기로 남기고, 오른쪽 공격 스틱의 아래 조준과도 섞이지 않는다.
	Input.action_press("drop_down", move_stick.y) if move_stick.y > 0.55 else Input.action_release("drop_down")

func update_attack_stick(pos: Vector2) -> void:
	attack_stick = (pos - attack_center).limit_length(STICK_RADIUS) / STICK_RADIUS
	Input.action_press("attack_left", absf(attack_stick.x)) if attack_stick.x < -0.18 else Input.action_release("attack_left")
	Input.action_press("attack_right", absf(attack_stick.x)) if attack_stick.x > 0.18 else Input.action_release("attack_right")
	Input.action_press("attack_up", absf(attack_stick.y)) if attack_stick.y < -0.18 else Input.action_release("attack_up")
	Input.action_press("attack_down", absf(attack_stick.y)) if attack_stick.y > 0.18 else Input.action_release("attack_down")
	# 고정 공격키는 중앙을 누르기만 해도 바라보는 방향으로 연속 공격한다.
	Input.action_press("attack")

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
	var visible_skills:Array=buttons.filter(func(item): return item["node"].visible and item["action"] in ["heart_skill","main_skill","off_skill"])
	var gap:=54.0
	for i in range(visible_skills.size()):
		visible_skills[i]["node"].position=Vector2(384.0+(float(i)-float(visible_skills.size()-1)*.5)*gap,SKILL_Y)
	queue_redraw()

func draw_centered(texture: Texture2D, center: Vector2, tint := Color.WHITE) -> void:
	draw_texture(texture,(center-Vector2(texture.get_size())*.5).round(),tint)

func draw_stick(center: Vector2, stick: Vector2, attack_side := false) -> void:
	if attack_side:
		draw_centered(ATTACK_RING,center,Color(1,1,1,.84))
		draw_centered(ATTACK_HAND,center+stick*STICK_RADIUS,Color(1,1,1,1.0 if attack_finger>=0 else .88))
	else:
		draw_centered(MOVE_RING,center,Color(1,1,1,.78))
		draw_centered(MOVE_KNOB,center+stick*STICK_RADIUS,Color(1,1,1,1.0 if move_finger>=0 else .82))

func _draw() -> void:
	if hidden_for_ui:
		return
	draw_stick(MOVE_CENTER,move_stick if move_finger>=0 else Vector2.ZERO)
	draw_stick(ATTACK_CENTER,attack_stick if attack_finger>=0 else Vector2.ZERO,true)
	for item in buttons:
		if not item["node"].visible:
			continue
		var pos: Vector2 = item["node"].position
		var active := Input.is_action_pressed(item["action"])
		var icon:=str(item["text"])
		var texture:Texture2D=BUTTON_TEXTURES.get(icon)
		if texture:
			draw_centered(texture,pos,Color(.78,.72,.7,1) if active else Color.WHITE)
