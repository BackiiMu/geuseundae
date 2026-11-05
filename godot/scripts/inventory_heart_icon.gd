extends Control

func _ready() -> void:
	custom_minimum_size=Vector2(42,42)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var dark:=Color("7c2832")
	var red:=Color("c5525b")
	var light:=Color("f1aaa0")
	# Deliberately chunky pixels so it remains readable in the 46 px slot.
	draw_rect(Rect2(9,10,10,8),red)
	draw_rect(Rect2(23,10,10,8),red)
	draw_rect(Rect2(6,15,30,10),red)
	draw_rect(Rect2(10,25,22,6),red)
	draw_rect(Rect2(15,31,12,4),dark)
	draw_rect(Rect2(12,12,5,4),light)
	draw_line(Vector2(21,8),Vector2(24,2),dark,3)
	draw_line(Vector2(24,3),Vector2(29,6),dark,2)
