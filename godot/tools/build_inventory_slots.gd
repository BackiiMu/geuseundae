extends SceneTree

func _initialize() -> void:
	for entry in [
		["res://assets/ui/modular/panel-normal-v1.png","res://assets/ui/modular/slot-normal-v1.png"],
		["res://assets/ui/modular/panel-selected-v1.png","res://assets/ui/modular/slot-selected-v1.png"]]:
		var source:=Image.load_from_file(ProjectSettings.globalize_path(entry[0]))
		source.resize(42,42,Image.INTERPOLATE_NEAREST)
		source.save_png(ProjectSettings.globalize_path(entry[1]))
	quit()
