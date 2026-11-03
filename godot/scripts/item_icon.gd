extends Control
var item: Dictionary
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size=Vector2(42,42)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var c: Color=[Color("b8c1b5"),Color("7da8c7"),Color("b397cf"),Color("d5bb75")][clampi(int(item.get("tier",1))-1,0,3)]
	draw_rect(Rect2(0,0,42,42),Color("18232d"))
	draw_rect(Rect2(1,1,40,40),c,false,1)
	var slot: String=item.get("slot","main")
	var id: String=item.get("id","")
	if id in ["hair","wig","ribbon"]:
		for i in range(5):
			draw_polyline(PackedVector2Array([Vector2(10+i*3,10),Vector2(13+i*2,20),Vector2(9+i*4,33)]),c,2)
	elif slot=="head":
		draw_rect(Rect2(10,12,22,20),c)
		draw_rect(Rect2(13,18,5,4),Color("18232d"))
		draw_rect(Rect2(25,18,5,4),Color("18232d"))
	elif slot in ["legs","feet"]:
		draw_polyline(PackedVector2Array([Vector2(14,9),Vector2(17,23),Vector2(11,33),Vector2(23,33)]),c,4)
		draw_polyline(PackedVector2Array([Vector2(26,9),Vector2(24,23),Vector2(28,33),Vector2(35,33)]),c,3)
	elif slot=="accessory":
		draw_circle(Vector2(21,21),11,c)
		draw_circle(Vector2(21,21),6,Color("34464e"))
	elif id=="fist":
		draw_rect(Rect2(11,13,23,19),c)
		for i in range(4): draw_line(Vector2(13+i*5,12),Vector2(13+i*5,20),Color("34464e"),2)
	elif item.get("kind","")=="ranged":
		draw_line(Vector2(10,32),Vector2(31,11),c,4)
		draw_polygon(PackedVector2Array([Vector2(30,9),Vector2(33,17),Vector2(25,12)]),PackedColorArray([c]))
	else:
		draw_line(Vector2(10,33),Vector2(31,10),c,4)
		draw_line(Vector2(9,23),Vector2(20,33),Color("cdb17a"),3)
