extends Control
var item: Dictionary
var show_frame := true
static var icon_cache := {}
static var sheet_cache := {}
static var sheet_info := {}
static var sheet_body_rect := {}
const PROVIDED_ITEMS = {"hair":"hair","pin":"hairpin","water_bucket":"gourd","fox_bead":"foxbead","claws":"claw","goblin_fire":"ghostfire","plague":"jar","fist":"fist"}
const GEAR2_ITEMS = {"songaksi_hand":"songakHand","ribbon":"ribbon","mirror":"jokduri","eggshell":"eggshell","blank_face":"blankface","gaze":"hollowgaze","wig":"wig","duo_head":"mask","bent_leg":"brokenLeg","mongdal_legs":"leg","wet_shoes":"shoe","single_shoe":"oneShoe","stomach":"stomach","duo_curse":"curse"}
const GEAR3_ITEMS = {"nails":"mongdalNail","goose":"woodGoose","mongdal_rush":"mongdalHan","call":"changgwiBell","tiger_soul":"boundSoul","tiger_fang":"tigerFang","water_hand":"drownedHand","well_bucket":"wellBucket","fox_fire":"foxFire","fox_mirror":"shapeMirror","club":"dokkaebiClub","broom":"oldBroom","belt":"ssireumSash","tooth":"agwiTeeth","tongue":"agwiTongue","shadow":"murkShadow","voice":"mimicVoice","whistle":"thinWhistle","mouth":"giantMouth","jangsan_paw":"jangsanPaw","fox_tail":"foxTail"}
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	custom_minimum_size=Vector2(42,42)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var c:=Color("aeb8ae")
	if show_frame:
		draw_rect(Rect2(0,0,42,42),Color("18232d"))
		draw_rect(Rect2(1,1,40,40),Color("59655e"),false,1)
	var slot: String=item.get("slot","main")
	var id: String=item.get("id","")
	if GEAR2_ITEMS.has(id):
		draw_gear2_item(id)
		return
	if GEAR3_ITEMS.has(id):
		draw_gear3_item(id)
		return
	if PROVIDED_ITEMS.has(id):
		draw_provided_item(id)
		return
	var icon_path := "res://assets/equipment/icons/"+id+".png"
	if FileAccess.file_exists(icon_path):
		if not icon_cache.has(id):
			icon_cache[id] = load(icon_path)
		draw_texture(icon_cache[id],Vector2.ZERO)
		return
	if id in ["hair","wig","ribbon"]:
		for i in range(5):
			draw_polyline(PackedVector2Array([Vector2(10+i*3,10),Vector2(13+i*2,20),Vector2(9+i*4,33)]),c,2)
	elif slot=="head":
		draw_rect(Rect2(10,12,22,20),c)
		draw_rect(Rect2(13,18,5,4),Color("18232d"))
		draw_rect(Rect2(25,18,5,4),Color("18232d"))
	elif slot=="legs":
		draw_polyline(PackedVector2Array([Vector2(14,9),Vector2(17,23),Vector2(11,33),Vector2(23,33)]),c,4)
		draw_polyline(PackedVector2Array([Vector2(26,9),Vector2(24,23),Vector2(28,33),Vector2(35,33)]),c,3)
	elif id=="sharp_dagger":
		draw_line(Vector2(10,33),Vector2(31,10),Color("d9dee0"),5)
		draw_polygon(PackedVector2Array([Vector2(31,10),Vector2(29,19),Vector2(22,12)]),PackedColorArray([Color("eef2ed")]))
		draw_line(Vector2(8,29),Vector2(15,36),Color("9b6b49"),4)
		draw_line(Vector2(7,27),Vector2(16,36),Color("c8a66a"),2)
	elif id=="someone_bow":
		draw_arc(Vector2(14,21),15,-PI*.48,PI*.48,12,Color("9a7149"),3)
		draw_line(Vector2(14,6),Vector2(14,36),Color("d5c7a0"),1)
		draw_line(Vector2(14,21),Vector2(35,21),Color("b7aa8a"),2)
		draw_polygon(PackedVector2Array([Vector2(35,21),Vector2(29,17),Vector2(29,25)]),PackedColorArray([Color("d7d3c4")]))
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

func draw_gear2_item(id: String) -> void:
	var key: String = "gear2_" + str(GEAR2_ITEMS[id])
	if not icon_cache.has(key):
		var path := "res://assets/gear2/icons/" + str(GEAR2_ITEMS[id]) + ".png"
		icon_cache[key] = load(path)
	var texture: Texture2D = icon_cache[key]
	var scale := minf(38.0 / texture.get_width(), 38.0 / texture.get_height())
	var size := Vector2(texture.get_width(), texture.get_height()) * scale
	draw_texture_rect(texture, Rect2((Vector2(42,42)-size)*.5, size), false)

func draw_gear3_item(id: String) -> void:
	var key := "gear3_"+str(GEAR3_ITEMS[id])
	if not icon_cache.has(key):
		icon_cache[key] = load("res://assets/gear3/icons/"+str(GEAR3_ITEMS[id])+".png")
	var texture: Texture2D = icon_cache[key]
	var scale := minf(38.0/texture.get_width(),38.0/texture.get_height())
	var size := Vector2(texture.get_width(),texture.get_height())*scale
	draw_texture_rect(texture,Rect2((Vector2(42,42)-size)*.5,size),false)

func draw_provided_item(id: String) -> void:
	# Inventory art is grade-neutral; rarity is already shown by the slot border.
	var key: String = str(PROVIDED_ITEMS[id]) + "_tier0"
	if not sheet_cache.has(key):
		var relative := "res://assets/provided_vfx/items/" + key
		sheet_cache[key] = load(relative + ".png")
		var image: Image = sheet_cache[key].get_image()
		sheet_info[key] = JSON.parse_string(FileAccess.get_file_as_string(relative + ".json"))["meta"]["pixelfx"]
		sheet_body_rect[key] = find_item_body(image, Vector2i(sheet_info[key]["frameSize"][0], sheet_info[key]["frameSize"][1]))
	var info: Dictionary = sheet_info[key]
	var frame_size := Vector2(info["frameSize"][0], info["frameSize"][1])
	var source: Rect2 = sheet_body_rect[key]
	var scale := minf(38.0 / source.size.x, 38.0 / source.size.y)
	var size := source.size * scale
	var destination := Rect2((Vector2(42, 42) - size) * .5, size)
	draw_texture_rect_region(sheet_cache[key], destination, source)

func find_item_body(image: Image, frame_size: Vector2i) -> Rect2:
	var min_point := Vector2i(frame_size.x, frame_size.y)
	var max_point := Vector2i.ZERO
	var found := false
	# Ignore the lower floor-shadow band and very faint aura pixels.
	for y in range(mini(frame_size.y, 54)):
		for x in range(frame_size.x):
			if image.get_pixel(x, y).a >= .45:
				min_point = min_point.min(Vector2i(x, y))
				max_point = max_point.max(Vector2i(x, y))
				found = true
	if not found: return Rect2(11, 4, 42, 42)
	min_point = (min_point - Vector2i(2, 2)).max(Vector2i.ZERO)
	max_point = (max_point + Vector2i(3, 3)).min(frame_size)
	return Rect2(min_point, max_point - min_point)
