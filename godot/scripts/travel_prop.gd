extends Node2D

signal finished

var animation := ""
var info: Dictionary = {}
var texture: Texture2D
var age := 0.0
var playing := false
var playback_speed := 1.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 2

func play(name: String, speed := 1.0) -> void:
	animation = name
	var base := "res://assets/provided_vfx/places/" + name
	info = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))["meta"]["pixelfx"]
	texture = load(base + ".png")
	age = 0.0
	playback_speed = speed
	playing = true
	queue_redraw()

func duration() -> float:
	return float(info.get("frames", 1)) / float(info.get("fps", 30))

func _process(delta: float) -> void:
	if not playing or info.is_empty(): return
	age += delta * playback_speed
	if not bool(info.get("loop", false)) and age >= duration():
		age = duration()
		playing = false
		finished.emit()
	queue_redraw()

func _draw() -> void:
	if info.is_empty() or texture == null: return
	var count := int(info["frames"])
	var frame := int(age * float(info["fps"]))
	frame = posmod(frame, count) if bool(info.get("loop", false)) else mini(frame, count - 1)
	var size := Vector2(info["frameSize"][0], info["frameSize"][1])
	var pivot := Vector2(info["pivot"][0], info["pivot"][1])
	var columns := int(info["columns"])
	var row := floori(float(frame)/float(columns))
	var source := Rect2(Vector2(frame % columns, row) * size, size)
	draw_texture_rect_region(texture, Rect2(-pivot, size), source)
