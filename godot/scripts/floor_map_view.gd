extends Control

const Catalog = preload("res://scripts/room_catalog.gd")
const MAP_FONT=preload("res://assets/fonts/Galmuri11-Bold.ttf")
var world: Node
var room_points: Dictionary = {}
const MAP_RECT := Rect2(58, 78, 438, 188)

func setup(owner_world: Node) -> void:
	world = owner_world
	rebuild()

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	room_points.clear()
	if not is_instance_valid(world) or world.run.is_empty():
		return
	var title := Label.new()
	title.position = Vector2(190, 16)
	title.size=Vector2(174,36)
	title.text = str(world.floor_number) + "챕터"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font",MAP_FONT)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color",Color("2b1a18"))
	add_child(title)
	var close := Button.new()
	close.position = Vector2(507, 13)
	close.size = Vector2(34, 34)
	close.text = "×"
	close.tooltip_text="닫기"
	close.add_theme_font_override("font",MAP_FONT)
	close.add_theme_font_size_override("font_size",20)
	close.add_theme_color_override("font_color",Color("f0d09a"))
	var close_style:=StyleBoxFlat.new()
	close_style.bg_color=Color("69282a")
	close_style.border_color=Color("d0a16e")
	close_style.set_border_width_all(3)
	close.add_theme_stylebox_override("normal",close_style)
	var close_hover:=close_style.duplicate()
	close_hover.bg_color=Color("913b38")
	close.add_theme_stylebox_override("hover",close_hover)
	close.add_theme_stylebox_override("pressed",close_hover)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(world.close_floor_map)
	add_child(close)
	var min_cell := Vector2(999,999)
	var max_cell := Vector2(-999,-999)
	for data in world.run["rooms"]:
		var cell := Vector2(data["grid"][0],data["grid"][1])
		min_cell = min_cell.min(cell)
		max_cell = max_cell.max(cell)
	var extent := max_cell-min_cell
	for data in world.run["rooms"]:
		var cell := Vector2(data["grid"][0],data["grid"][1])-min_cell
		var normalized := Vector2(.5 if extent.x==0 else cell.x/extent.x,.5 if extent.y==0 else cell.y/extent.y)
		room_points[int(data["id"])] = MAP_RECT.position + normalized*MAP_RECT.size
	for data in world.run["rooms"]:
		var id := int(data["id"])
		var visited := bool(data.get("visited",false))
		var button := Button.new()
		button.position = room_points[id]-Vector2(50,22)
		button.size = Vector2(100,44)
		button.focus_mode = Control.FOCUS_NONE
		# 방 이름 대신 _draw()가 탐색한 방의 실제 축소 지형을 그린다.
		button.text = ""
		button.add_theme_font_override("font",MAP_FONT)
		button.add_theme_font_size_override("font_size",10)
		button.add_theme_color_override("font_color",Color("ead8bd"))
		button.add_theme_color_override("font_disabled_color",Color("aa9a84"))
		var empty:=StyleBoxEmpty.new()
		button.add_theme_stylebox_override("normal",empty)
		button.add_theme_stylebox_override("hover",empty)
		button.add_theme_stylebox_override("pressed",empty)
		button.add_theme_stylebox_override("disabled",empty)
		button.set_meta("room_id",id)
		button.disabled = id == world.current_id or not visited or id == world.run["goal"]
		if not button.disabled:
			var destination := id
			button.pressed.connect(func(): world.begin_well_travel(destination))
		add_child(button)
	queue_redraw()

func draw_room_thumbnail(point:Vector2,data:Dictionary,fill:Color) -> void:
	var templates:Dictionary=Catalog.templates()
	var definition:Dictionary=templates.get(str(data.get("template","")),{})
	if definition.is_empty(): return
	var inner:=Rect2(point+Vector2(-42,-13),Vector2(84,27))
	var width:float=maxf(1.0,float(definition.get("width",1536)))
	var map_point:=func(x:float,y:float)->Vector2:
		return Vector2(inner.position.x+x/width*inner.size.x,inner.position.y+clampf((y-340.0)/364.0,0.0,1.0)*inner.size.y)
	# 바닥과 실제 틈.
	draw_line(map_point.call(0.0,704.0),map_point.call(width,704.0),Color("c8aa7d"),2)
	for gap in definition.get("gaps",[]):
		var a:Vector2=map_point.call(float(gap[0]),704.0)
		var b:Vector2=map_point.call(float(gap[0]+gap[1]),704.0)
		draw_line(a,b,fill,3)
	# 발판과 통과 불가능한 벽을 실제 방 비율로 축소한다.
	for platform in definition.get("platforms",[]):
		draw_line(map_point.call(float(platform[0]),float(platform[1])),map_point.call(float(platform[0]+platform[2]),float(platform[1])),Color("d2b788"),2)
	for wall in definition.get("walls",[]):
		var top_left:Vector2=map_point.call(float(wall[0]),float(wall[1]))
		var bottom_right:Vector2=map_point.call(float(wall[0]+wall[2]),float(wall[1]+wall[3]))
		draw_rect(Rect2(top_left,bottom_right-top_left),Color("9b7457"),true)
	# 연결 방향은 패찰 가장자리의 작은 문으로 읽힌다.
	var grid:=Vector2i(int(data["grid"][0]),int(data["grid"][1]))
	for next_id in data["links"]:
		var next:Dictionary=world.run["rooms"][int(next_id)]
		var next_grid:=Vector2i(int(next["grid"][0]),int(next["grid"][1]))
		var direction:=next_grid-grid
		if direction.x<0: draw_rect(Rect2(point+Vector2(-50,-3),Vector2(8,6)),Color("d3b17b"),true)
		elif direction.x>0: draw_rect(Rect2(point+Vector2(42,-3),Vector2(8,6)),Color("d3b17b"),true)
		elif direction.y<0: draw_rect(Rect2(point+Vector2(-3,-22),Vector2(6,8)),Color("d3b17b"),true)
		elif direction.y>0: draw_rect(Rect2(point+Vector2(-3,14),Vector2(6,8)),Color("d3b17b"),true)

func _draw() -> void:
	if not is_instance_valid(world) or world.run.is_empty():
		return
	# 어두운 한지 지도판과 낡은 목재/놋쇠 테두리.
	draw_rect(Rect2(8,8,size.x-16,size.y-16),Color("171417"),true)
	draw_rect(Rect2(8,8,size.x-16,size.y-16),Color("6e4938"),false,4)
	draw_rect(Rect2(14,14,size.x-28,size.y-28),Color("bb7a51"),false,1)
	for corner in [Vector2(8,8),Vector2(size.x-22,8),Vector2(8,size.y-22),Vector2(size.x-22,size.y-22)]:
		draw_rect(Rect2(corner,Vector2(14,14)),Color("493126"),true)
		draw_rect(Rect2(corner+Vector2(3,3),Vector2(8,8)),Color("b7895d"),false,2)
	draw_rect(Rect2(20,58,size.x-40,size.y-86),Color("211f22"),true)
	# 제목 두루마리.
	var title_poly:=PackedVector2Array([Vector2(176,18),Vector2(184,10),Vector2(370,10),Vector2(378,18),Vector2(378,50),Vector2(370,58),Vector2(184,58),Vector2(176,50)])
	draw_colored_polygon(title_poly,Color("d6ad79"))
	draw_polyline(PackedVector2Array(Array(title_poly)+[title_poly[0]]),Color("47272a"),3)
	for data in world.run["rooms"]:
		var from: Vector2 = room_points.get(int(data["id"]),Vector2.ZERO)
		for next in data["links"]:
			if int(next) > int(data["id"]):
				var to: Vector2 = room_points.get(int(next),Vector2.ZERO)
				var known := bool(data.get("visited",false)) or bool(world.run["rooms"][int(next)].get("visited",false))
				draw_line(from,to,Color("ba4548") if known else Color("393238"),4)
	for data in world.run["rooms"]:
		var point: Vector2 = room_points.get(int(data["id"]),Vector2.ZERO)
		var current:bool=int(data["id"])==world.current_id
		var visited:bool=bool(data.get("visited",false))
		var peaceful:bool=bool(data.get("peaceful",false))
		var fill:=Color("6b4a3b") if current else Color("705442") if peaceful and visited else Color("5d483b") if visited else Color("17171b")
		var edge:=Color("e8d5a5") if current else Color("b88b66") if visited else Color("62574f")
		var p:=PackedVector2Array([point+Vector2(-50,-16),point+Vector2(-43,-22),point+Vector2(43,-22),point+Vector2(50,-16),point+Vector2(50,16),point+Vector2(43,22),point+Vector2(-43,22),point+Vector2(-50,16)])
		draw_colored_polygon(p,fill)
		draw_polyline(PackedVector2Array(Array(p)+[p[0]]),edge,2)
		if visited:
			draw_room_thumbnail(point,data,fill)
		if current:
			draw_colored_polygon(PackedVector2Array([point+Vector2(-5,-33),point+Vector2(5,-33),point+Vector2(0,-25)]),Color("e34848"))
		if not visited:
			draw_string(MAP_FONT,point+Vector2(-5,6),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c3b49b"))

