extends StaticBody2D

const VILLAGE_ATLAS := preload("res://assets/environment/haunted-village-atlas.png")
const MOUNTAIN_PROPS := preload("res://assets/environment/chapter2/fog-mountain-props-v1.png")
const GARRISON_PROPS := preload("res://assets/environment/chapter3/exorcist-garrison-props-v1.png")

var wall_size := Vector2(48,160)
var wall_material := "plaster"

func setup(rect: Rect2, wall_material: String) -> void:
	wall_size=rect.size
	self.wall_material=wall_material
	position=rect.get_center()
	collision_layer=1
	collision_mask=2
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=wall_size
	collision.shape=shape
	add_child(collision)
	queue_redraw()

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	var rect:=Rect2(-wall_size*.5,wall_size)
	if wall_material=="plaster":
		draw_plaster_wall(rect)
		return
	if wall_material=="rock":
		draw_texture_rect_region(MOUNTAIN_PROPS,rect.grow_individual(16,10,16,0),Rect2(0,627,627,627),Color("a2abb0"))
		return
	if wall_material=="seal":
		draw_texture_rect_region(GARRISON_PROPS,rect.grow_individual(17,20,17,0),Rect2(627,0,627,627),Color("b5aaa1"))
		return
	var dark:=Color("2b3033")
	var mid:=Color("66706d")
	var edge:=Color("929b91")
	match wall_material:
		"rock":
			dark=Color("202a30"); mid=Color("46545b"); edge=Color("75848a")
		"palisade":
			dark=Color("2a1d1b"); mid=Color("5b3b32"); edge=Color("8b6450")
		"seal":
			dark=Color("28191b"); mid=Color("633032"); edge=Color("a85a4f")
		_:
			dark=Color("303536"); mid=Color("777d75"); edge=Color("a39d8c")
	draw_rect(rect,dark)
	if wall_material=="palisade":
		for x in range(int(rect.position.x)+4,int(rect.end.x),12):
			draw_colored_polygon(PackedVector2Array([Vector2(x,rect.position.y+8),Vector2(x+5,rect.position.y),Vector2(x+10,rect.position.y+8),Vector2(x+10,rect.end.y),Vector2(x,rect.end.y)]),mid)
		draw_rect(Rect2(rect.position.x,rect.position.y+wall_size.y*.46,wall_size.x,8),dark)
	elif wall_material=="seal":
		draw_rect(rect.grow(-4),mid)
		for y in range(int(rect.position.y)+10,int(rect.end.y),20):
			draw_rect(Rect2(rect.position.x-3,y,wall_size.x+6,4),edge)
		draw_line(Vector2(0,rect.position.y),Vector2(0,rect.end.y),Color("d0ae72"),5)
	else:
		draw_rect(rect.grow(-4),mid)
		for y in range(int(rect.position.y)+8,int(rect.end.y),16):
			var offset:=8 if int(y/16)%2 else 0
			for x in range(int(rect.position.x)-offset,int(rect.end.x),18):
				draw_rect(Rect2(x,y,14,9),dark if wall_material=="rock" else Color("555a56"))
		draw_line(rect.position,Vector2(rect.end.x,rect.position.y),edge,3)

func draw_plaster_wall(rect: Rect2) -> void:
	# Use the same approved atlas as the village instead of a flat procedural block.
	# The narrow center crop avoids squeezing a complete wall panel into small cover.
	var wall_source:=Rect2(748,345,74,270)
	var cap_source:=Rect2(954,46,286,71)
	var body:=Rect2(rect.position+Vector2(0,8),rect.size-Vector2(0,8))
	draw_texture_rect_region(VILLAGE_ATLAS,body,wall_source,Color("d6d0c0"))
	# A broken, asymmetric cap makes repeated cover read as ruined architecture.
	draw_texture_rect_region(VILLAGE_ATLAS,Rect2(rect.position+Vector2(-7,-3),Vector2(rect.size.x+14,18)),cap_source,Color("b7aaa0"))
	draw_rect(Rect2(rect.position.x+4,rect.end.y-13,rect.size.x-8,13),Color("30363b"),false,3)
