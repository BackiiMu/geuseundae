extends Control

var texture:=preload("res://assets/ui/vfx/inventory-select.png")
var info:Dictionary
var elapsed:=0.0
var playing:=false
var origin:=Vector2.ZERO

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	position=Vector2.ZERO
	size=Vector2(768,432)
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	info=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/vfx/inventory-select.json"))["meta"]["pixelfx"]

func play_at(screen_position:Vector2) -> void:
	origin=screen_position
	elapsed=0.0
	playing=true
	queue_redraw()

func _process(delta:float) -> void:
	if not playing: return
	elapsed+=delta
	if elapsed>=float(info["frames"])/float(info["fps"]): playing=false
	queue_redraw()

func _draw() -> void:
	if not playing or info.is_empty(): return
	var frame:=mini(int(info["frames"])-1,int(elapsed*float(info["fps"])))
	var frame_size:=Vector2(info["frameSize"][0],info["frameSize"][1])
	var columns:=int(info["columns"])
	var row:=floori(float(frame)/float(columns))
	var source:=Rect2(Vector2(frame%columns,row)*frame_size,frame_size)
	var pivot:=Vector2(info["pivot"][0],info["pivot"][1])
	# Keep the confirmation inside a single bag socket instead of floating over
	# neighbouring items.
	draw_texture_rect_region(texture,Rect2(origin-pivot*.28,frame_size*.28),source)
