extends Node2D

const ART = preload("res://assets/environment/haunted-village-atlas.png")
const EAVE_SOURCE := Rect2(954,46,286,71)
const COLUMN_SOURCE := Rect2(748,345,74,270)

var roofs:Array[Rect2]=[]

func configure(values:Array[Rect2]) -> void:
	roofs=values.duplicate()
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func _draw() -> void:
	for rect in roofs:
		# The narrow lip crosses the actor's feet, while columns intermittently
		# pass in front of actors below. This separates foreground from backdrop
		# without hiding combat readability.
		draw_texture_rect_region(ART,Rect2(rect.position+Vector2(-12,10),Vector2(rect.size.x+24,16)),EAVE_SOURCE,Color("777079"))
		var left:=Rect2(rect.position+Vector2(10,18),Vector2(18,704-rect.position.y-18))
		var right:=Rect2(Vector2(rect.end.x-28,rect.position.y+18),left.size)
		if left.size.y>20:
			draw_texture_rect_region(ART,left,COLUMN_SOURCE,Color("77716e"))
			draw_texture_rect_region(ART,right,COLUMN_SOURCE,Color("77716e"))
