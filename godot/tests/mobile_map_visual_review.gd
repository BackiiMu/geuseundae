extends SceneTree

func _initialize() -> void:
	call_deferred("run_review")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func capture(path: String) -> void:
	var image:=root.get_texture().get_image()
	assert(image.save_png(path)==OK,"Could not save "+path)
	print("CAPTURE: ",path)

func run_review() -> void:
	DirAccess.make_dir_recursive_absolute("res://../docs/reviews/ui")
	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	await frames(12)
	capture("res://../docs/reviews/ui/mobile-controls-applied-v1.png")
	world.open_floor_map()
	await frames(4)
	capture("res://../docs/reviews/ui/floor-map-applied-v1.png")
	quit()
