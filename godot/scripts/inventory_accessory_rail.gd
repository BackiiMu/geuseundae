extends Control

var slot_count := 4
var slot_size := 36.0
var gap := 6.0
var columns := 4
const PANEL_TEXTURE:=preload("res://assets/ui/modular/panel-normal-v1.png")
const RESTRAINED_ATLAS:=preload("res://assets/ui/modular/inventory-restrained-atlas-v1.png")
var panel_style:StyleBoxTexture

func configure(count:int,available_width:=252.0,column_count:=4) -> void:
	slot_count=maxi(0,count)
	columns=maxi(1,mini(column_count,maxi(1,slot_count)))
	if slot_count>0:
		slot_size=clampf((available_width-gap*float(columns-1))/float(columns),24.0,36.0)
	queue_redraw()

func slots_width() -> float:
	if slot_count<=0: return 0.0
	return slot_size*mini(slot_count,columns)+gap*maxi(0,mini(slot_count,columns)-1)

func slots_origin() -> Vector2:
	var rows:=ceili(float(slot_count)/float(columns)) if slot_count>0 else 1
	var grid_height:=rows*slot_size+maxi(0,rows-1)*gap
	# GridContainer contributes a one-pixel internal inset; compensate so the
	# visible first and last sockets remain optically centered in the rail.
	return Vector2((size.x-slots_width())*.5+1.0,maxf(24.0,24.0+(size.y-28.0-grid_height)*.5))

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
	draw_texture_rect_region(RESTRAINED_ATLAS,rail,Rect2(905,108,575,447))
	var plaque:=Rect2((size.x-84)*.5,2,84,17)
	draw_texture_rect_region(RESTRAINED_ATLAS,plaque,Rect2(1110,667,358,80))
	var origin:=slots_origin()
	for i in range(slot_count):
		var rect:=Rect2(origin+Vector2((i%columns)*(slot_size+gap),floori(float(i)/columns)*(slot_size+gap)),Vector2(slot_size,slot_size))
		draw_texture_rect_region(RESTRAINED_ATLAS,rect,Rect2(912,627,153,153))
