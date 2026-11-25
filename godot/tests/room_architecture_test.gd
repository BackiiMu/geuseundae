extends SceneTree

const Catalog=preload("res://scripts/room_catalog.gd")
const RoomView=preload("res://scripts/room_view.gd")

func check(ok:bool,label:String) -> bool:
	if not ok: push_error("FAIL: "+label); quit(1); return false
	print("PASS: "+label); return true

func _initialize() -> void:
	for template in ["courtyard","hall","servants_quarters"]:
		for variant in range(3):
			var definition:=Catalog.resolve(template,variant)
			var room:=RoomView.new()
			root.add_child(room)
			room.build(definition,41)
			var authored_count:=int(definition["authored_platform_count"])
			if not check(str(definition["architecture"])=="walkable_roofs",template+" uses modular walkable roofs"): return
			if not check(room.architecture_platforms().size()==authored_count,template+" roof art count matches authored collision count"): return
			for i in range(authored_count):
				var source:Array=definition["platforms"][i]
				var collision:Rect2=room.architecture_platforms()[i]
				if not check(collision.position==Vector2(source[0],source[1]) and collision.size.x==source[2],template+" roof surface shares exact collision coordinates"): return
			var foregrounds:=room.get_children().filter(func(node): return node.get_script()!=null and node.get_script().resource_path.ends_with("room_architecture_foreground.gd"))
			if not check(foregrounds.size()==1 and foregrounds[0].z_index>20,template+" has one actor-overlapping foreground layer"): return
			if not check(room.platforms.size()==definition["platforms"].size(),template+" keeps seeded scaffold platforms physical"): return
			room.queue_free()
			await process_frame
	var ordinary:=RoomView.new()
	root.add_child(ordinary)
	ordinary.build(Catalog.resolve("well",0),41)
	if not check(ordinary.architecture_platforms().is_empty(),"non-roof rooms keep their existing art path"): return
	print("Walkable roof architecture checks completed.")
	quit()
