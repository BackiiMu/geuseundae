extends SceneTree

const OUTPUT := "res://../docs/reviews/ui"
const SummonEffect = preload("res://scripts/summon_effect.gd")

func _initialize() -> void:
	call_deferred("review")

func frames(count: int) -> void:
	for i in range(count):
		await process_frame

func capture(name: String) -> void:
	var image := root.get_texture().get_image()
	var path := OUTPUT + "/" + name + ".png"
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save " + path)
		quit(1)
	print("CAPTURE: ", path)

func clear_scene() -> void:
	for child in root.get_children():
		child.queue_free()
	await frames(3)

func review() -> void:
	root.size = Vector2i(768, 432)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var title: Node = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	await frames(5)
	await capture("01-title-screen")
	await clear_scene()
	var world: Node = load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(8)
	for child in world.get_children():
		if child is SummonEffect:
			child.elapsed = 3.7
			child.queue_redraw()
	await frames(2)
	await capture("02-shadow-summon")
	for child in world.get_children():
		if child is SummonEffect:
			child.finished.emit()
			child.queue_free()
	await frames(3)
	await capture("03-village-hud")
	world.combat.toggle_inventory()
	await frames(5)
	await capture("04-inventory-json-layout")
	world.combat.toggle_inventory()
	world.combat.game_hud.toggle_settings()
	await frames(3)
	await capture("05-settings")
	print("UI visual review completed.")
	quit(0)
