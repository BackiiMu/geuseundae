extends Control

var slot_count := 4
var slot_size := 36.0
var gap := 6.0
const PANEL_TEXTURE:=preload("res://assets/ui/modular/panel-normal-v1.png")
var panel_style:StyleBoxTexture

func configure(count:int) -> void:
	slot_count=maxi(0,count)
	if slot_count>0:
		slot_size=clampf((252.0-gap*float(slot_count-1))/float(slot_count),24.0,36.0)
	queue_redraw()

func slots_width() -> float:
	if slot_count<=0: return 0.0
	return slot_size*slot_count+gap*(slot_count-1)

func slots_origin() -> Vector2:
	return Vector2((size.x-slots_width())*.5,22)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel_style=StyleBoxTexture.new()
	panel_style.texture=PANEL_TEXTURE
	panel_style.texture_margin_left=25
	panel_style.texture_margin_right=25
	panel_style.texture_margin_top=22
	panel_style.texture_margin_bottom=22
	panel_style.modulate_color=Color(.56,.53,.50,1)
	queue_redraw()

func _draw() -> void:
	# Covers the four sockets baked into the full-frame painting and replaces
	# them with a lacquer rail whose sockets follow the live equipment model.
	var rail:=Rect2(0,7,size.x,size.y-7)
	draw_rect(Rect2(rail.position+Vector2(2,2),rail.size),Color(0,0,0,.55))
	draw_style_box(panel_style,rail)
	var plaque:=Rect2((size.x-84)*.5,2,84,17)
	draw_rect(plaque,Color("a9895e"))
	draw_rect(plaque,Color("553a29"),false,1)
	var origin:=slots_origin()
	for i in range(slot_count):
		var rect:=Rect2(origin+Vector2(i*(slot_size+gap),0),Vector2(slot_size,slot_size))
		draw_rect(rect,Color("080c0e"))
		draw_rect(rect,Color("856345"),false,2)
		draw_line(rect.position+Vector2(3,3),rect.position+Vector2(rect.size.x-3,3),Color("c09a63"),1)
