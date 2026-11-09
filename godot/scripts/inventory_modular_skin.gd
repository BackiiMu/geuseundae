extends Control

const INK:=Color("080b0d")
const PANEL:=Color("111416")
const PANEL_2:=Color("171719")
const LACQUER:=Color("241516")
const RED:=Color("6f211d")
const RED_DARK:=Color("351414")
const BRASS:=Color("9a713d")
const BRASS_LIGHT:=Color("d0aa68")
const PAPER:=Color("b99867")
const PAPER_DARK:=Color("674c34")
const PANEL_TEXTURE:=preload("res://assets/ui/modular/panel-normal-v1.png")
const PLAQUE_TEXTURE:=preload("res://assets/ui/modular/plaque-v1.png")
const GHOST_TEXTURE:=preload("res://assets/ui/modular/borrowed-ghost-v1.png")
const InventoryLayout:=preload("res://scripts/inventory_layout.gd")
var panel_style:StyleBoxTexture
var inner_panel_style:StyleBoxTexture

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel_style=StyleBoxTexture.new()
	panel_style.texture=PANEL_TEXTURE
	panel_style.texture_margin_left=31
	panel_style.texture_margin_right=31
	panel_style.texture_margin_top=28
	panel_style.texture_margin_bottom=28
	inner_panel_style=panel_style.duplicate()
	inner_panel_style.modulate_color=Color(.56,.53,.50,1)
	queue_redraw()

func pixel_panel(rect:Rect2,fill:Color=PANEL,ornate:=true) -> void:
	if ornate:
		draw_style_box(panel_style,rect)
		return
	# The same cabinet material, darkened for hierarchy: textured and recessed,
	# but quieter than the full-strength outer rim.
	draw_rect(Rect2(rect.position+Vector2(3,3),rect.size),Color(0,0,0,.55))
	draw_style_box(inner_panel_style,rect)

func brass_corner(point:Vector2,flip_x:=false,flip_y:=false) -> void:
	var sx:float=-1.0 if flip_x else 1.0
	var sy:float=-1.0 if flip_y else 1.0
	var poly:=PackedVector2Array([
		point,point+Vector2(17*sx,0),point+Vector2(17*sx,5*sy),
		point+Vector2(7*sx,5*sy),point+Vector2(7*sx,17*sy),point+Vector2(0,17*sy)])
	draw_colored_polygon(poly,BRASS)
	draw_polyline(poly,BRASS_LIGHT,1)
	draw_circle(point+Vector2(4*sx,4*sy),1.5,INK)

func paper_plaque(rect:Rect2) -> void:
	draw_texture_rect(PLAQUE_TEXTURE,rect,false)

func blossom(point:Vector2) -> void:
	var petal:=Color("8e332d")
	for offset in [Vector2(-3,0),Vector2(3,0),Vector2(0,-3),Vector2(0,3)]:
		draw_rect(Rect2(point+offset-Vector2.ONE,Vector2(3,3)),petal)
	draw_rect(Rect2(point-Vector2.ONE,Vector2(3,3)),BRASS_LIGHT)

func plum_branch(from:Vector2,to:Vector2) -> void:
	draw_line(from,to,Color("644331"),2)
	var direction:=(to-from).normalized()
	for distance in range(10,int(from.distance_to(to)),17):
		var point:=from+direction*distance
		var side:=Vector2(-direction.y,direction.x)*(6 if distance%2==0 else -6)
		draw_line(point,point+side,Color("644331"),1)
		if distance%34==0: blossom(point+side)

func drawer_handle(center:Vector2) -> void:
	draw_circle(center,7,Color("332016"))
	draw_circle(center,5,BRASS)
	draw_circle(center,2,INK)
	draw_arc(center+Vector2(0,4),8,PI*.1,PI*.9,12,BRASS_LIGHT,1)

func hanging_tassel(origin:Vector2) -> void:
	draw_circle(origin,4,BRASS_LIGHT)
	draw_circle(origin+Vector2(0,8),4,Color("ddd0bd"))
	draw_line(origin+Vector2(0,12),origin+Vector2(0,39),Color("7d201e"),3)
	for x in range(-5,6,3): draw_line(origin+Vector2(x,28),origin+Vector2(x*1.4,49),Color("9b2c25"),2)

func layout_rect(id:String) -> Rect2:
	return InventoryLayout.rect(id,size)

func draw_body_diagram() -> void:
	var doll:=layout_rect("doll")
	var center:=doll.position+Vector2(120,73)
	draw_circle(center-Vector2(0,15),57,Color("24201e"))
	draw_arc(center-Vector2(0,15),57,0,TAU,48,Color("65352e"),1)
	draw_arc(center-Vector2(0,15),48,0,TAU,40,Color("3e3028"),1)
	for i in range(12):
		var mark:=(Vector2.RIGHT.rotated(i*TAU/12.0))*52
		draw_rect(Rect2(center-Vector2(0,15)+mark-Vector2.ONE,Vector2(2,2)),Color("9a794d"))
	# The borrowed body is a real transparent pixel asset rather than a geometric
	# mannequin: faceless hair, torn hanbok and a lower body dissolving into ink.
	draw_texture_rect(GHOST_TEXTURE,Rect2(doll.position+Vector2(83,-1),Vector2(74,148)),false,Color(.72,.72,.78,.82))
	var endpoints:=[doll.position+Vector2(31,23),doll.position+Vector2(31,66),doll.position+Vector2(31,109),doll.position+Vector2(31,152),doll.position+Vector2(173,23),doll.position+Vector2(173,66),doll.position+Vector2(173,109)]
	var joints:=[center+Vector2(-5,-36),center+Vector2(-14,-4),center+Vector2(-9,33),center+Vector2(-8,66),center+Vector2(8,-13),center+Vector2(15,2),center+Vector2(8,24)]
	for i in range(endpoints.size()):
		draw_line(endpoints[i],joints[i],Color("b39466"),1)
		draw_circle(joints[i],2,Color("d1b179"))

func _draw() -> void:
	# Everything is drawn on integer coordinates so nearest-neighbour scaling
	# stays crisp at 1x, 2x and 3x. No layout socket is baked into a bitmap.
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.015,0.02,.78))
	var outer:=layout_rect("frame")
	draw_rect(outer.grow(5),Color(0,0,0,.72))
	pixel_panel(outer,Color("0d1012"),true)
	# Independently resizable modules.
	pixel_panel(layout_rect("doll_panel"),Color("1a1b1c"),false)
	pixel_panel(layout_rect("rail_panel"),Color("101214"),false)
	pixel_panel(layout_rect("bag_panel"),Color("101214"),false)
	pixel_panel(layout_rect("detail_panel"),Color("111315"),false)
	var detail:=layout_rect("detail_panel")
	draw_line(detail.position+Vector2(detail.size.x*.67,13),detail.position+Vector2(detail.size.x*.67,detail.size.y-11),Color("5b4633"),1)
	paper_plaque(layout_rect("title_plaque"))
	paper_plaque(layout_rect("bag_plaque"))
	draw_body_diagram()
	var title_plaque:=layout_rect("title_plaque")
	plum_branch(title_plaque.end+Vector2(5,-24),title_plaque.end+Vector2(136,-5))
	hanging_tassel(layout_rect("doll_panel").position+Vector2(3,8))
	# Small pixel hardware and restrained folk decoration.
	for point in [outer.position+Vector2(9,9),Vector2(outer.end.x-10,outer.position.y+9),Vector2(outer.position.x+9,outer.end.y-10),outer.end-Vector2(10,10)]:
		draw_circle(point,2,BRASS_LIGHT)
	for x in range(int(outer.position.x+28),int(outer.end.x-16),23):
		draw_rect(Rect2(x,outer.position.y+5+(x%3),11,1),Color("76231f"))
		draw_rect(Rect2(x,outer.end.y-9-(x%2),7,1),Color("57201d"))
