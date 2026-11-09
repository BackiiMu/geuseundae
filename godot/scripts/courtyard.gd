extends Node2D

const Player = preload("res://scripts/player.gd")
var player: CharacterBody2D
var debug_visible := false
var solid_rects: Array[Rect2] = []
var one_way_rects: Array[Rect2] = []
var status: Label
var elapsed := 0.0

func bind_action(action: String, codes: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for code in codes:
		var event := InputEventKey.new()
		event.physical_keycode = code
		InputMap.action_add_event(action, event)

func _ready() -> void:
	bind_action("move_left", [KEY_A])
	bind_action("move_right", [KEY_D])
	bind_action("jump", [KEY_W, KEY_SPACE])
	bind_action("dash", [KEY_SHIFT])
	bind_action("restart", [KEY_R])
	bind_action("collision_view", [KEY_F1])
	var background := Sprite2D.new()
	background.texture = preload("res://assets/haunted-courtyard.png")
	background.centered = false
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(background)
	# Ground follows the visible paving and the rise into the rear garden.
	add_solid(Rect2(0, 588, 142, 140))
	add_solid(Rect2(142, 610, 650, 118))
	add_solid(Rect2(792, 586, 30, 142))
	add_solid(Rect2(822, 560, 87, 168))
	add_solid(Rect2(909, 620, 641, 108))
	for step in range(5):
		add_solid(Rect2(1540 + step * 28, 594 - step * 23, 28, 134 + step * 23))
	add_solid(Rect2(1680, 497, 246, 231))
	add_solid(Rect2(1926, 438, 246, 290))
	# Thin pass-through platforms align with the balcony, wall and garden ledges.
	add_solid(Rect2(828, 464, 128, 10), true)
	add_solid(Rect2(956, 464, 543, 10), true)
	add_solid(Rect2(1499, 441, 92, 10), true)
	add_solid(Rect2(1573, 383, 340, 10), true)
	# Entry and exit stops keep the camera test within its illustrated map.
	add_solid(Rect2(-30, -300, 30, 1100))
	add_solid(Rect2(2172, -300, 30, 1100))
	player = Player.new()
	player.name = "ScaleMarker"
	player.position = Vector2(360, 590)
	add_child(player)
	build_hud()

func add_solid(rect: Rect2, one_way := false) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size / 2
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = one_way
	shape.one_way_collision_margin = 6
	body.add_child(shape)
	add_child(body)
	if one_way:
		one_way_rects.append(rect)
	else:
		solid_rects.append(rect)

func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.04, 0.06, 0.09, 0.86)
	panel.position = Vector2(12, 12)
	panel.size = Vector2(744, 62)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	var text := Label.new()
	text.position = Vector2(24, 16)
	text.text = "흉가 탐색"
	text.add_theme_font_size_override("font_size", 14)
	layer.add_child(text)
	status = Label.new()
	status.position = Vector2(18, 402)
	status.add_theme_font_size_override("font_size", 13)
	layer.add_child(status)

func _process(delta: float) -> void:
	elapsed += delta
	if Input.is_action_just_pressed("collision_view"):
		debug_visible = not debug_visible
		queue_redraw()
	if status:
		var region := "대문 · 앞마당" if player.position.x < 920 else "본채 · 위층" if player.position.x < 1540 else "뒤뜰 · 신당"
		status.text = region + "   |   임시 크기 표식 · 몹 없음"

func _draw() -> void:
	if not debug_visible:
		return
	for rect in solid_rects:
		draw_rect(rect, Color(0.3, 0.9, 0.7, 0.2))
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("a9e1bc"), 2)
	for rect in one_way_rects:
		draw_rect(rect, Color(0.95, 0.7, 0.3, 0.5))
