extends Node2D
var world: Node2D
var finger := -1
var stick := Vector2.ZERO
var center := Vector2(78,332)
var buttons: Array = []
var hidden_for_ui := false
const MOVEMENT=["move_left","move_right","aim_up","aim_down"]
func _ready() -> void:
	var specs=[
		["attack","공격",Vector2(704,337),32.0],
		["jump","점프",Vector2(625,366),25.0],
		["dash","대시",Vector2(706,257),24.0],
		["heart_skill","심장",Vector2(548,366),23.0],
		["main_skill","주무기",Vector2(578,292),21.0],
		["off_skill","보조",Vector2(630,251),21.0],
		["interact","사용",Vector2(739,187),22.0],
		["inventory","가방",Vector2(739,108),20.0],
		["equipment_lab","시험",Vector2(688,108),20.0]]
	for spec in specs:
		var button:=TouchScreenButton.new()
		button.position=spec[2]
		var shape:=CircleShape2D.new()
		shape.radius=spec[3]
		button.shape=shape
		button.action=spec[0]
		button.visibility_mode=TouchScreenButton.VISIBILITY_ALWAYS
		add_child(button)
		buttons.append({"node":button,"text":spec[1],"radius":spec[3],"action":spec[0]})
func release_movement() -> void:
	for action in MOVEMENT: Input.action_release(action)
	stick=Vector2.ZERO
	finger=-1
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT: release_movement()
func _input(event: InputEvent) -> void:
	if hidden_for_ui: return
	if event is InputEventScreenTouch:
		if event.pressed and finger<0 and event.position.distance_to(center)<65:
			finger=event.index
			update_stick(event.position)
		elif not event.pressed and event.index==finger: release_movement()
	elif event is InputEventScreenDrag and event.index==finger: update_stick(event.position)
func update_stick(pos: Vector2) -> void:
	stick=(pos-center).limit_length(48)/48
	Input.action_press("move_left",absf(stick.x)) if stick.x<-.25 else Input.action_release("move_left")
	Input.action_press("move_right",absf(stick.x)) if stick.x>.25 else Input.action_release("move_right")
	Input.action_press("aim_up",absf(stick.y)) if stick.y<-.35 else Input.action_release("aim_up")
	Input.action_press("aim_down",absf(stick.y)) if stick.y>.35 else Input.action_release("aim_down")
func _process(_delta: float) -> void:
	var modal:bool=world.combat.inventory.visible or (is_instance_valid(world.merchant) and world.merchant.opened)
	if modal and not hidden_for_ui:
		release_movement()
		for item in buttons: Input.action_release(item["action"])
	hidden_for_ui=modal
	for item in buttons:
		var show:=not modal
		if item["action"]=="main_skill": show=show and world.combat.equipped("main").get("skill","")!=""
		if item["action"]=="off_skill": show=show and (world.combat.equipped("off").get("skill","")!="" or world.combat.duo_set())
		item["node"].visible=show
	queue_redraw()
func _draw() -> void:
	if hidden_for_ui: return
	draw_circle(center,58,Color(.07,.12,.16,.55))
	draw_arc(center,58,0,TAU,40,Color(.7,.8,.76,.65),2)
	draw_circle(center+stick*40,23,Color(.7,.8,.73,.5))
	var font=preload("res://assets/fonts/NotoSansKR-Semibold.ttf")
	for item in buttons:
		if not item["node"].visible: continue
		var pos:Vector2=item["node"].position
		var active:=Input.is_action_pressed(item["action"])
		draw_circle(pos,item["radius"],Color(.25,.4,.38,.8) if active else Color(.07,.12,.16,.65))
		draw_arc(pos,item["radius"],0,TAU,32,Color(.68,.78,.72,.8),2)
		draw_string(font,pos+Vector2(-font.get_string_size(item["text"],HORIZONTAL_ALIGNMENT_LEFT,-1,13).x/2,5),item["text"],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e2e5d3"))
