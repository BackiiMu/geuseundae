extends Control

const Catalog = preload("res://scripts/room_catalog.gd")
var world: Node
var room_points: Dictionary = {}
const MAP_RECT := Rect2(34, 62, 492, 214)

func setup(owner_world: Node) -> void:
	world = owner_world
	rebuild()

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	room_points.clear()
	if not is_instance_valid(world) or world.run.is_empty():
		return
	var title := Label.new()
	title.position = Vector2(24, 16)
	title.text = world.chapter_title() + " · 상세지도"
	title.add_theme_font_size_override("font_size", 19)
	add_child(title)
	var close := Button.new()
	close.position = Vector2(size.x - 88, 12)
	close.size = Vector2(72, 34)
	close.text = "닫기 ×"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(world.close_floor_map)
	add_child(close)
	var min_cell := Vector2(999,999)
	var max_cell := Vector2(-999,-999)
	for data in world.run["rooms"]:
		var cell := Vector2(data["grid"][0],data["grid"][1])
		min_cell = min_cell.min(cell)
		max_cell = max_cell.max(cell)
	var extent := max_cell-min_cell
	for data in world.run["rooms"]:
		var cell := Vector2(data["grid"][0],data["grid"][1])-min_cell
		var normalized := Vector2(.5 if extent.x==0 else cell.x/extent.x,.5 if extent.y==0 else cell.y/extent.y)
		room_points[int(data["id"])] = MAP_RECT.position + normalized*MAP_RECT.size
	for data in world.run["rooms"]:
		var id := int(data["id"])
		var visited := bool(data.get("visited",false))
		var button := Button.new()
		button.position = room_points[id]-Vector2(47,18)
		button.size = Vector2(94,36)
		button.focus_mode = Control.FOCUS_NONE
		if id == world.current_id:
			button.text = "● 현재 위치"
		elif id == world.run["goal"]:
			button.text = "보스방" if visited else "잠긴 문"
		elif bool(data.get("peaceful",false)):
			button.text = "도깨비상점" if visited else "미탐색"
		else:
			button.text = "이동 가능" if visited else "미탐색"
		button.add_theme_font_size_override("font_size",10)
		button.disabled = id == world.current_id or not visited or id == world.run["goal"]
		if not button.disabled:
			var destination := id
			button.pressed.connect(func(): world.begin_well_travel(destination))
		add_child(button)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(world) or world.run.is_empty():
		return
	draw_rect(Rect2(18,52,size.x-36,size.y-88),Color("0b131c"),true)
	draw_rect(Rect2(18,52,size.x-36,size.y-88),Color("665b4c"),false,2)
	for data in world.run["rooms"]:
		var from: Vector2 = room_points.get(int(data["id"]),Vector2.ZERO)
		for next in data["links"]:
			if int(next) > int(data["id"]):
				var to: Vector2 = room_points.get(int(next),Vector2.ZERO)
				var known := bool(data.get("visited",false)) or bool(world.run["rooms"][int(next)].get("visited",false))
				draw_line(from,to,Color("82918a") if known else Color("303d43"),4)
	for data in world.run["rooms"]:
		var point: Vector2 = room_points.get(int(data["id"]),Vector2.ZERO)
		var color := Color("d9e5c5") if int(data["id"])==world.current_id else Color("d2ad72") if bool(data.get("peaceful",false)) else Color("758d88") if bool(data.get("visited",false)) else Color("303d43")
		draw_circle(point,23,color)

