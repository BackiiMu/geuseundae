extends SceneTree

const SummonEffect=preload("res://scripts/summon_effect.gd")
const OUT_DIR := "res://../docs/reviews/hearts"

func _initialize() -> void: call_deferred("run_review")
func frames(count: int) -> void:
	for i in range(count): await process_frame
func wait_until_grounded(player,limit := 120) -> void:
	for i in range(limit):
		if player.is_on_floor(): return
		await process_frame
func finish_summon(world) -> void:
	for child in world.get_children():
		if child is SummonEffect:
			child.finished.emit()
			child.queue_free()
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var path:=OUT_DIR+"/"+name+".png"
	var result:=image.save_png(path)
	assert(result==OK,"Could not save "+path)
	print("CAPTURE: ",ProjectSettings.globalize_path(path))

func run_review() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size=Vector2i(768,432)
	var world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(12)
	finish_summon(world)
	await frames(3)
	await capture("01-village-heart-npcs")

	world.accept_heart("mongdal")
	await frames(2)
	finish_summon(world)
	await wait_until_grounded(world.player)
	await frames(3)
	print("VISUAL: mongdal role=",world.player.visual.role," animation=",world.player.visual.animation," frame=",world.player.visual.frame_index," texture=",world.player.visual.texture.resource_path)
	await capture("02-mongdal-heart")

	world.enter_heartless_form(false)
	world.accept_heart("changgui")
	await frames(2)
	finish_summon(world)
	await frames(3)
	world.floor_number=1
	world.new_run(1103)
	await frames(25)
	world.combat.heart_cd=0
	world.combat.use_heart()
	await frames(8)
	print("VISUAL: changgui role=",world.player.visual.role," animation=",world.player.visual.animation," frame=",world.player.visual.frame_index," texture=",world.player.visual.texture.resource_path)
	await capture("03-changgui-soul-bind")
	quit(0)
