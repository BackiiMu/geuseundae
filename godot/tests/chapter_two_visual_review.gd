extends SceneTree

const OUT_DIR := "res://../docs/reviews/chapter2"

func _initialize() -> void: call_deferred("run_review")
func frames(count: int) -> void:
	for i in range(count): await process_frame
func wait_real(milliseconds: int) -> void:
	var until:=Time.get_ticks_msec()+milliseconds
	while Time.get_ticks_msec()<until:
		await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=OUT_DIR+"/"+name+".png"
	assert(image.save_png(path)==OK,"Could not save "+path)
	print("CAPTURE: ",ProjectSettings.globalize_path(path))
func stage(world,room_id: int) -> void:
	world.change_room(room_id,-1)
	await frames(8)
	world.player.position=Vector2(360,704)
	world.player.camera.position_smoothing_enabled=false
	world.player.camera.force_update_scroll()
	var x:=500.0
	for enemy in world.combat.living():
		enemy.position=Vector2(x,704)
		enemy.training_dummy=true
		x+=125
	await frames(4)

func run_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size=Vector2i(768,432)
	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	await frames(20)
	world.floor_number=2
	world.new_run(2202)
	await stage(world,0)
	await capture("01-fog-mountain-enemies")
	var elite_id:=-1
	for data in world.run["rooms"]:
		if int(data["id"])>0 and int(data["id"])%4==0 and int(data["id"])!=int(world.run["goal"]) and not bool(data.get("peaceful",false)):
			elite_id=int(data["id"])
			break
	if elite_id>=0:
		await stage(world,elite_id)
		await capture("02-jangsan-shadow-elite")
	await stage(world,int(world.run["goal"]))
	var boss=world.combat.living()[0]
	await capture("03-jangsanbeom-phase1-mimic")
	boss.take_damage(9999)
	await wait_real(900)
	await capture("04-jangsanbeom-transform-fog")
	await wait_real(1200)
	await capture("05-jangsanbeom-phase2-shadow")
	boss.take_damage(9999)
	await wait_real(2100)
	await capture("06-jangsanbeom-phase3-beast")
	quit(0)
