extends Control
# pixelfx weather 시트를 화면 전체에 깔고 분위기 색을 살짝 입힌다. 판정은 weather_system.gd가 맡는다.
const Weather = preload("res://scripts/weather_system.gd")
var weather: RefCounted
var textures := {}
var manifest: Dictionary
var clock := 0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/vfx/weather/manifest.json"))

func _process(delta: float) -> void:
	clock+=delta
	visible=weather!=null and weather.active()
	if visible: queue_redraw()

func _draw() -> void:
	if weather==null or not weather.active() or not Weather.SHEET_FILES.has(weather.id): return
	var info:Dictionary=manifest["sheets"][weather.id]
	if not textures.has(weather.id):
		textures[weather.id]=load("res://assets/vfx/weather/"+str(info["file"])+".png")
	var size:=Vector2(manifest["frameSize"][0],manifest["frameSize"][1])
	var columns:=int(manifest["columns"])
	var frame:=int(clock*float(manifest["fps"]))%int(info["frames"])
	var source:=Rect2(Vector2(frame%columns,floori(float(frame)/columns))*size,size)
	var view:=get_viewport_rect().size
	draw_texture_rect_region(textures[weather.id],Rect2(Vector2.ZERO,view),source)
	draw_rect(Rect2(Vector2.ZERO,view),Weather.TINT[weather.id])
