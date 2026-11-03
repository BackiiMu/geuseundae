extends Node2D

var definition: Dictionary
var decor_seed := 0
var floor_y := 704
var rects: Array[Rect2] = []
var platforms: Array[Rect2] = []
var door_positions: Array[Vector2] = []
var debug_visible := false

func build(data: Dictionary, seed_value: int) -> void:
	definition = data
	decor_seed = seed_value
	var width: int = definition["width"]
	var cursor := 0
	for gap in definition["gaps"]:
		add_body(Rect2(cursor, floor_y, gap[0] - cursor, 160), false)
		cursor = gap[0] + gap[1]
	add_body(Rect2(cursor, floor_y, width - cursor, 160), false)
	for platform in definition["platforms"]:
		add_body(Rect2(platform[0], platform[1], platform[2], 16), true)
	add_body(Rect2(-32, -400, 32, 1500), false)
	add_body(Rect2(width, -400, 32, 1500), false)
	queue_redraw()

func add_body(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 2
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 6
	body.add_child(collision)
	add_child(body)
	if one_way:
		platforms.append(rect)
	else:
		rects.append(rect)

func roof(x: float, y: float, width: float) -> void:
	draw_polygon(PackedVector2Array([Vector2(x-24,y+32),Vector2(x+24,y+12),Vector2(x+width/2,y-6),Vector2(x+width-24,y+12),Vector2(x+width+24,y+32)]),PackedColorArray([Color("253b48")]))
	for i in range(int(width / 24) + 1):
		draw_rect(Rect2(x+i*24,y+15,20,13), Color("3e5260"))
		draw_line(Vector2(x+i*24,y+16),Vector2(x+i*24+19,y+16),Color("61737a"),2)
	draw_rect(Rect2(x-24,y+32,width+48,8),Color("151f2c"))

func lantern(x: float, y: float) -> void:
	draw_line(Vector2(x,y-20),Vector2(x,y),Color("4f3b35"),2)
	draw_rect(Rect2(x-9,y,18,26),Color("84623d"))
	draw_rect(Rect2(x-6,y+3,12,19),Color("dfb76d"))
	draw_rect(Rect2(x-2,y+3,3,19),Color("f5d68b"))

func building(x: float, y: float, width: float, height: float) -> void:
	draw_rect(Rect2(x,y+35,width,height-35),Color("202a35"))
	for i in range(int(width/96)):
		var px := x+i*96
		draw_rect(Rect2(px+16,y+72,62,height-104),Color("151f2a"))
		for bar in range(5):
			draw_rect(Rect2(px+20+bar*11,y+76,3,height-112),Color("46504e"))
		draw_rect(Rect2(px,y+35,10,height-35),Color("655045"))
	draw_rect(Rect2(x,y+height-12,width,12),Color("715e4b"))
	roof(x,y,width)
	lantern(x+width*.5,y+62)

func pine(x: float, y: float) -> void:
	draw_rect(Rect2(x,y-230,18,230),Color("34353b"))
	for i in range(4):
		var yy := y-230+i*44
		var xx := x-90+(i%2)*35
		draw_rect(Rect2(xx,yy,150-i*15,22),Color("2e4c49"))
		draw_rect(Rect2(xx+18,yy-10,110-i*10,14),Color("3d6259"))

func _draw() -> void:
	if definition.is_empty():
		return
	var width: int = definition["width"]
	var theme: String = definition["theme"]
	draw_rect(Rect2(0,0,width,864),Color("111d2b"))
	# Hard-edged silhouettes remain subordinate to traversable foreground tiles.
	for i in range(14):
		var x := i*160.0
		var height := 80+posmod(decor_seed+i*37,130)
		draw_polygon(PackedVector2Array([Vector2(x-100,450),Vector2(x+35,280-height),Vector2(x+210,450)]),PackedColorArray([Color("1a303d")]))
	for x in range(0,width,64):
		draw_rect(Rect2(x,552,62,152),Color("27343e"))
		draw_rect(Rect2(x+2,551,58,6),Color("43535a"))
		draw_line(Vector2(x,623),Vector2(x+60,623),Color("374650"),2)
	match theme:
		"gate":
			building(536,256,384,448)
			draw_rect(Rect2(650,344,160,348),Color("111d2b"))
			pine(1190,704)
		"courtyard":
			building(566,240,576,464)
			pine(1420,704)
		"well":
			pine(320,704)
			building(1010,320,288,384)
			draw_rect(Rect2(640,624,160,80),Color("526064"))
			draw_rect(Rect2(651,632,138,13),Color("16212c"))
			draw_rect(Rect2(636,532,9,94),Color("6a5546"))
			draw_rect(Rect2(794,532,9,94),Color("6a5546"))
			draw_rect(Rect2(636,528,167,9),Color("8a7055"))
		"hall", "gallery":
			building(100,208,width-200,496)
			for x in range(128,width-100,192):
				draw_rect(Rect2(x,246,12,458),Color("6b5144"))
		"forest":
			for x in range(220,width,260):
				pine(x,704)
			for x in range(180,width,320):
				draw_line(Vector2(x,360),Vector2(x+300,386),Color("7b6a54"),2)
				draw_rect(Rect2(x+140,373,16,43),Color("975958"))
		"store":
			building(180,208,width-360,496)
			for i in range(7):
				draw_rect(Rect2(340+i*120,640-(i%2)*40,64,64),Color("5a4b42"))
				draw_rect(Rect2(344+i*120,644-(i%2)*40,56,56),Color("3c3837"),false,3)
		"shrine", "sanctum":
			building(width/2.0-240,192,480,512)
			for x in [width/2.0-292,width/2.0+292]:
				draw_rect(Rect2(x,624,24,80),Color("526064"))
				lantern(x+12,598)
	# The very tiles we draw are the physical collision rectangles.
	for rect in rects:
		if rect.position.x < 0 or rect.position.x >= width:
			continue
		draw_rect(rect,Color("1c2330"))
		for x in range(int(rect.position.x),int(rect.end.x),32):
			draw_rect(Rect2(x,rect.position.y,mini(30,int(rect.end.x)-x),24),Color("46515a"))
			draw_rect(Rect2(x,rect.position.y,mini(30,int(rect.end.x)-x),4),Color("8da390"))
			for row in range(1,4):
				draw_rect(Rect2(x+(row%2)*5,rect.position.y+row*32,24,24),Color("293340"))
	for rect in platforms:
		draw_rect(rect,Color("5b514b"))
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,4)),Color("a2ac94"))
		for x in range(int(rect.position.x)+8,int(rect.end.x),32):
			draw_rect(Rect2(x,rect.position.y+4,3,10),Color("322f36"))
	for pos in door_positions:
		draw_rect(Rect2(pos.x-25,pos.y-82,50,82),Color("0c1520"))
		draw_rect(Rect2(pos.x-30,pos.y-88,60,7),Color("879687"))
		draw_rect(Rect2(pos.x-30,pos.y-82,5,82),Color("697a75"))
		draw_rect(Rect2(pos.x+25,pos.y-82,5,82),Color("697a75"))
		lantern(pos.x+43,pos.y-76)
	if debug_visible:
		for rect in rects + platforms:
			draw_rect(rect,Color(0.5,1,0.8,.2))
