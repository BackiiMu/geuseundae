extends SceneTree

const OUT_DIR := "res://../docs/reviews/rooms"
const Catalog = preload("res://scripts/room_catalog.gd")

func _initialize() -> void:
	call_deferred("run_review")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=OUT_DIR+"/"+name+".png"
	assert(image.save_png(path)==OK,"Could not save "+path)
	print("CAPTURE: ",ProjectSettings.globalize_path(path))

func stage(world,chapter: int,template: String,shot_prefix: String) -> void:
	world.floor_number=chapter
	world.run={"version":3,"seed":1,"start":0,"goal":0,"rooms":[{"id":0,"template":template,"links":[],"grid":[0,0],"decor_seed":1,"visited":false}]}
	world.change_room(0,-1)
	await frames(16)
	world.player.camera.position_smoothing_enabled=false
	for shot in [[384.0,"left"],[896.0,"center"],[1408.0,"right"]]:
		world.player.position=Vector2(shot[0],704)
		world.player.camera.force_update_scroll()
		await frames(4)
		await capture(shot_prefix+"-"+shot[1])

func run_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size=Vector2i(768,432)
	var world=load("res://scenes/random_run.tscn").instantiate()
	world.combat_enabled=false
	root.add_child(world)
	await frames(24)
	await stage(world,1,"collapsed_house","01-collapsed-house")
	await stage(world,2,"rotten_bridge","02-rotten-bridge")
	await stage(world,3,"ritual_yard","03-ritual-yard")
	quit(0)
