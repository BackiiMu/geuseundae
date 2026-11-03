extends SceneTree
const Catalog = preload("res://scripts/room_catalog.gd")
const RoomView = preload("res://scripts/room_view.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var result: Array = []
	for key in Catalog.templates():
		var definition: Dictionary = Catalog.templates()[key]
		var room = RoomView.new()
		root.add_child(room)
		room.build(definition,1103)
		room.door_positions.append(Vector2(96,704))
		room.door_positions.append(Vector2(definition["width"]-96,704))
		room.record_only = true
		room._draw()
		result.append({"id":key,"name":definition["name"],"width":definition["width"],"height":864,"commands":room.render_commands})
		root.remove_child(room)
		room.free()
	var file := FileAccess.open("res://../assets/maps/room-art-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	print("Exported exact draw commands for nine room themes.")
	quit(0)
