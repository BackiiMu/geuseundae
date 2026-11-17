extends Node2D

const RoomWall = preload("res://scripts/room_wall.gd")

var definition: Dictionary
var decor_seed := 0
var floor_y := 704
var rects: Array[Rect2] = []
var platforms: Array[Rect2] = []
var solid_walls: Array[Rect2] = []
var door_positions: Array[Vector2] = []
var boss_door_positions: Array[Vector2] = []
var debug_visible := false
var chapter := 1
var fog_clock := 0.0

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if chapter>=2:
		fog_clock+=delta
		queue_redraw()

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
	for wall in definition.get("walls",[]):
		add_wall(Rect2(wall[0],wall[1],wall[2],wall[3]))
	add_body(Rect2(-32, -400, 32, 1500), false)
	add_body(Rect2(width, -400, 32, 1500), false)
	queue_redraw()

func add_wall(rect: Rect2) -> void:
	var wall:=RoomWall.new()
	var material := "plaster" if chapter==1 else "rock" if chapter==2 else "seal"
	wall.setup(rect,material)
	add_child(wall)
	solid_walls.append(rect)

func add_body(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.set_meta("one_way",one_way)
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

# Shared atlas, authored against the approved courtyard reference.
const ART = preload("res://assets/environment/haunted-village-atlas.png")
var regions: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/atlas-regions.json"))
const DISTANCE = preload("res://assets/haunted-courtyard.png")
const MOUNTAIN_DISTANCE = preload("res://assets/environment/chapter2/fog-mountain-background-v1.png")
const GARRISON_DISTANCE = preload("res://assets/environment/chapter3/exorcist-garrison-background-v1.png")
const MOUNTAIN_PROPS = preload("res://assets/environment/chapter2/fog-mountain-props-v1.png")
const GARRISON_PROPS = preload("res://assets/environment/chapter3/exorcist-garrison-props-v1.png")

var record_only := false
var render_commands: Array = []

func paint_region(texture: Texture2D, rect: Rect2, source: Rect2, tint := Color.WHITE) -> void:
	if record_only:
		render_commands.append({"texture":texture.resource_path,"dest":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"source":[source.position.x,source.position.y,source.size.x,source.size.y],"tint":[tint.r,tint.g,tint.b,tint.a]})
	else:
		draw_texture_rect_region(texture,rect,source,tint)

func paint_fill(rect: Rect2, color: Color) -> void:
	if record_only:
		render_commands.append({"fill":color.to_html(),"dest":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]})
	else:
		draw_rect(rect,color)

func stamp(index: int, rect: Rect2, tint := Color.WHITE) -> void:
	var r: Array = regions[index]
	var source := Rect2(r[0],r[1],r[2],r[3])
	paint_region(ART,rect,source,tint)

func tile_band(index: int, rect: Rect2, tile_size := Vector2(96,96), tint := Color.WHITE) -> void:
	var r: Array = regions[index]
	var cell := Vector2(r[2],r[3])
	var base := Vector2(r[0],r[1])
	var y := rect.position.y
	while y < rect.end.y:
		var x := rect.position.x
		while x < rect.end.x:
			var size := Vector2(minf(tile_size.x,rect.end.x-x),minf(tile_size.y,rect.end.y-y))
			paint_region(ART,Rect2(Vector2(x,y),size),Rect2(base,cell*size/tile_size),tint)
			x += tile_size.x
		y += tile_size.y

func house(x: float, roof_y: float, width: float, floor_level: float) -> void:
	var eaves := roof_y+138
	tile_band(4,Rect2(x,eaves,width,floor_level-eaves),Vector2(192,256),Color("b0b8be"))
	stamp(5,Rect2(x-48,roof_y,width+96,160))
	for column in range(int(width/192)+1):
		stamp(6,Rect2(x+column*192-16,eaves-8,32,floor_level-eaves+8))
	stamp(15,Rect2(x+width*.5-18,eaves+36,36,64))

func collapsed_house_art() -> void:
	# A bespoke composition for the representative room. Every piece comes from
	# the shared village atlas, so collision can change without baking a new room.
	stamp(8,Rect2(32,232,384,472),Color("879e99"))
	house(384,176,576,704)
	stamp(9,Rect2(1112,300,352,404),Color("aeb5b2"))
	stamp(5,Rect2(736,246,352,158),Color("a8ada9"))
	stamp(12,Rect2(432,590,112,114),Color("939796"))
	stamp(13,Rect2(560,596,116,108),Color("8f8b88"))
	stamp(14,Rect2(1052,510,224,100),Color("858987"))
	stamp(15,Rect2(1336,582,48,92),Color("b4a79a"))

func prop(texture: Texture2D, quadrant: Vector2i, rect: Rect2, tint := Color.WHITE) -> void:
	paint_region(texture,rect,Rect2(Vector2(quadrant)*627.0,Vector2(627,627)),tint)

func rotten_bridge_art() -> void:
	# Cliff, bridge, rocks and pine remain separate sprites for later rearrangement.
	prop(MOUNTAIN_PROPS,Vector2i(0,0),Rect2(-36,188,430,516),Color("88979f"))
	# Anchor the bridge between the cliff foot and a rock outcrop instead of
	# leaving it suspended in empty sky.
	prop(MOUNTAIN_PROPS,Vector2i(1,0),Rect2(346,540,400,260),Color("97999a"))
	prop(MOUNTAIN_PROPS,Vector2i(0,1),Rect2(690,528,270,176),Color("849197"))
	prop(MOUNTAIN_PROPS,Vector2i(0,1),Rect2(1130,526,320,178),Color("849197"))
	prop(MOUNTAIN_PROPS,Vector2i(1,1),Rect2(1430,168,330,536),Color("7d8989"))

func ritual_yard_art() -> void:
	# The ritual structures are not baked into the garrison background.
	prop(GARRISON_PROPS,Vector2i(0,0),Rect2(34,268,374,436),Color("9a8a80"))
	prop(GARRISON_PROPS,Vector2i(0,1),Rect2(436,514,330,190),Color("9c8e84"))
	prop(GARRISON_PROPS,Vector2i(1,0),Rect2(840,438,180,266),Color("aea095"))
	prop(GARRISON_PROPS,Vector2i(1,1),Rect2(1110,244,390,460),Color("a49287"))

func _draw() -> void:
	if definition.is_empty():
		return
	var width: int = definition["width"]
	var theme: String = definition["theme"]
	paint_fill(Rect2(0,0,width,864),Color("101925"))
	if chapter==3:
		paint_region(GARRISON_DISTANCE,Rect2(0,0,width,724),Rect2(0,0,GARRISON_DISTANCE.get_width(),GARRISON_DISTANCE.get_height()),Color("b7bdc2"))
		paint_fill(Rect2(0,570,width,134),Color(0.035,0.045,0.065,.2))
	elif chapter==2:
		paint_region(MOUNTAIN_DISTANCE,Rect2(0,0,width,724),Rect2(0,0,MOUNTAIN_DISTANCE.get_width(),MOUNTAIN_DISTANCE.get_height()),Color("bbc4c9"))
		paint_fill(Rect2(0,520,width,184),Color(0.04,0.07,0.11,.24))
		for i in range(3):
			var drift:=fmod(fog_clock*(8.0+i*3.0)+i*211.0,float(width)+420.0)-210.0
			paint_fill(Rect2(drift,168+i*132,520,48),Color(0.55,0.65,0.69,.035+i*.012))
	else:
		# Reuse the approved image's distant sky only; no painted collision floor.
		paint_region(DISTANCE,Rect2(0,0,width,440),Rect2(0,0,DISTANCE.get_width(),250),Color("a9b7c2"))
		tile_band(2,Rect2(0,504,width,200),Vector2(192,192),Color("87929d"))
	var art_theme := theme if chapter==1 else "mountain"
	if chapter==1 and definition.get("name","")=="무너진 안채":
		collapsed_house_art()
		art_theme="custom"
	elif chapter==2 and definition.get("name","")=="썩은 나무다리":
		rotten_bridge_art()
		art_theme="custom"
	elif chapter==3 and definition.get("name","")=="금줄 제단":
		ritual_yard_art()
		art_theme="custom"
	match art_theme:
		"gate":
			stamp(9,Rect2(360,288,448,416))
			stamp(8,Rect2(1056,256,448,448),Color("acbcb9"))
			stamp(13,Rect2(856,608,112,96))
		"courtyard":
			house(560,208,576,704)
			stamp(8,Rect2(1280,224,448,480))
			stamp(13,Rect2(256,608,128,96))
		"well":
			stamp(8,Rect2(160,224,448,480))
			house(1024,272,320,704)
			stamp(10,Rect2(608,496,256,208))
		"hall":
			house(128,160,width-256,704)
			stamp(13,Rect2(576,592,128,112))
		"gallery":
			house(128,176,width-256,704)
			for x in range(320,width-160,320):
				stamp(14,Rect2(x,390,160,96))
		"forest":
			for x in range(64,width,320):
				stamp(8,Rect2(x,208,448,496),Color("8baba3"))
			for x in range(224,width,384):
				stamp(14,Rect2(x,384,224,112))
			stamp(11,Rect2(1280,512,192,192))
		"store":
			house(160,192,width-320,704)
			for x in range(320,width-224,176):
				stamp(12,Rect2(x,576,128,128))
			stamp(13,Rect2(1008,592,128,112))
		"shrine":
			stamp(8,Rect2(64,208,448,496),Color("91aaa6"))
			stamp(11,Rect2(width/2.0-224,256,448,448))
			stamp(14,Rect2(width/2.0-96,384,192,112))
		"sanctum":
			house(width/2.0-288,144,576,704)
			for x in [width/2.0-352,width/2.0+224]:
				stamp(11,Rect2(x,544,128,160))
			stamp(14,Rect2(width/2.0-128,352,256,128))
		"mountain":
			pass
		"custom":
			pass
	# Visual floor tops and physical top surfaces share these exact rectangles.
	for rect in rects:
		if rect.position.x < 0 or rect.position.x >= width:
			continue
		tile_band(1,rect,Vector2(96,96),Color("6f737b") if chapter==3 else Color("778692") if chapter==2 else Color("b0bac6"))
		tile_band(0,Rect2(rect.position,Vector2(rect.size.x,64)),Vector2(128,64),Color("8b8279") if chapter==3 else Color("8b9b9b") if chapter==2 else Color.WHITE)
	for rect in platforms:
		# Tight atlas bounds put the visible plank directly on the collision top.
		var bridge_surface: bool=chapter==2 and str(definition.get("name",""))=="썩은 나무다리" and is_equal_approx(rect.position.x,224.0) and is_equal_approx(rect.position.y,704.0)
		if not bridge_surface:
			tile_band(3,rect,Vector2(96,16))
	for pos in boss_door_positions:
		paint_fill(Rect2(pos.x-28,pos.y-102,56,102),Color("0c1520"))
		stamp(7,Rect2(pos.x-38,pos.y-116,76,116))
		stamp(15,Rect2(pos.x+38,pos.y-102,28,52))
	if debug_visible:
		for rect in rects + platforms + solid_walls:
			draw_rect(rect,Color(0.5,1,0.8,.2))
