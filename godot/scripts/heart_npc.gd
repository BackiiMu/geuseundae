extends Node2D

var heart_id := "mongdal"
var display_name := "몽달귀신"
var art_path := ""
var unlocked := true
var texture: Texture2D

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	if not art_path.is_empty() and ResourceLoader.exists(art_path): texture=load(art_path)
	queue_redraw()

func _draw() -> void:
	var tint:=Color.WHITE if unlocked else Color(0.18,0.2,0.24,.7)
	draw_circle(Vector2(0,-3),30,Color(0.12,0.09,0.16,.48))
	if texture!=null:
		draw_texture_rect_region(texture,Rect2(-23,-64,46,64),Rect2(Vector2.ZERO,texture.get_size()),tint)
	if not unlocked:
		draw_rect(Rect2(-8,-42,16,20),Color(0.08,0.07,0.1,.9))
		draw_arc(Vector2(0,-42),7,PI,TAU,12,Color("8d7f91"),2)
