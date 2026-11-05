extends Node2D
var texture:=preload("res://assets/actors/source/songaksi-v1.png")
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()
func _draw() -> void:
	var frame_size:=Vector2(texture.get_width()/8.0,texture.get_height()/4.0)
	draw_circle(Vector2(0,-3),28,Color(0.18,0.12,0.22,.42))
	draw_texture_rect_region(texture,Rect2(-24,-62,48,64),Rect2(Vector2.ZERO,frame_size))
