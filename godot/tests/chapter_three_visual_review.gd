extends SceneTree

const OUT_DIR := "res://../docs/reviews/chapter3"

func _initialize() -> void: call_deferred("run_review")
func frames(count: int) -> void:
	for i in range(count): await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=OUT_DIR+"/"+name+".png"
	assert(image.save_png(path)==OK,"Could not save "+path)
	print("CAPTURE: ",ProjectSettings.globalize_path(path))

func run_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size=Vector2i(768,432)
	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	await frames(20)
	world.floor_number=3
	world.new_run(3303)
	world.change_room(int(world.run["goal"]),-1)
	await frames(8)
	world.player.position=Vector2(500,704)
	world.player.camera.position_smoothing_enabled=false
	world.player.camera.force_update_scroll()
	var positions:={"soul-warden":Vector2(700,704)}
	for enemy in world.combat.living():
		enemy.position=positions[enemy.kind]
		enemy.training_dummy=true
	await frames(5)
	await capture("03-soul-warden-boss")
	var boss=world.combat.living()[0]
	world.combat.start_warden_pattern(boss,"stakes")
	await frames(2)
	await capture("04-soul-warden-stakes")
	quit(0)
