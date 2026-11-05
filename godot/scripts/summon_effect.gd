extends Node2D
signal finished
const PLAYBACK_SPEED := 3.5
const SHADOW_TINT := Color("101116")
var texture := preload("res://assets/actors/tar-child.png")
var elapsed := 0.0
var info: Dictionary
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	self_modulate=SHADOW_TINT
	info=JSON.parse_string(FileAccess.get_file_as_string("res://assets/actors/tar-child.json"))["meta"]["pixelfx"]
func _process(delta: float) -> void:
	elapsed += delta*PLAYBACK_SPEED
	if elapsed >= float(info["frames"])/float(info["fps"]):
		finished.emit()
		queue_free()
	queue_redraw()
func _draw() -> void:
	if info.is_empty(): return
	var frame_size:=Vector2(info["frameSize"][0],info["frameSize"][1])
	var index:=mini(int(info["frames"])-1,int(elapsed*float(info["fps"])))
	var source:=Rect2(Vector2(index%int(info["columns"]),index/int(info["columns"]))*frame_size,frame_size)
	var pivot:=Vector2(info["pivot"][0],info["pivot"][1])
	draw_texture_rect_region(texture,Rect2(-pivot,frame_size),source)
