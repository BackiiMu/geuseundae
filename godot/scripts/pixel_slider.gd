extends HSlider

func _ready() -> void:
	custom_minimum_size.y = 24
	for state in ["slider","grabber_area","grabber_area_highlight"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	var clear := Image.create(1,1,false,Image.FORMAT_RGBA8)
	clear.fill(Color.TRANSPARENT)
	var clear_texture := ImageTexture.create_from_image(clear)
	add_theme_icon_override("grabber",clear_texture)
	add_theme_icon_override("grabber_highlight",clear_texture)
	value_changed.connect(func(_value:float):queue_redraw())
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var center_y:=size.y*.5
	var track:=Rect2(2,center_y-5,size.x-4,10)
	draw_rect(track,Color("080607"))
	draw_rect(track,Color("3a2a20"),false,2)
	var ratio:=(value-min_value)/maxf(.001,max_value-min_value)
	var fill:=Rect2(track.position+Vector2(2,2),Vector2((track.size.x-4)*ratio,track.size.y-4))
	draw_rect(fill,Color("7a1f1c"))
	if fill.size.x>2: draw_line(fill.position,fill.position+Vector2(fill.size.x,0),Color("a84332"),2)
	var knob_x:=lerpf(track.position.x+3,track.end.x-3,ratio)
	var knob:=Rect2(knob_x-4,center_y-10,8,20)
	draw_rect(knob,Color("4a301d"))
	draw_rect(Rect2(knob.position+Vector2(1,1),knob.size-Vector2(2,2)),Color("9a713d"))
	draw_line(knob.position+Vector2(2,2),knob.position+Vector2(2,knob.size.y-3),Color("d0aa68"),2)
