extends Control

var clock := 0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _process(delta: float) -> void:
	clock+=delta
	queue_redraw()

func _draw() -> void:
	var view:=get_viewport_rect().size
	# A barely visible veil ties every mountain room together without washing out
	# actors, telegraphs or platforms.
	draw_rect(Rect2(Vector2.ZERO,view),Color(0.49,0.59,0.63,.045))
	for i in range(3):
		var band_width:=view.x*.78
		var x:=fmod(clock*(7.0+i*2.5)+i*213.0,view.x+band_width)-band_width
		var y:=view.y*(.24+i*.23)+sin(clock*.18+i*1.7)*12.0
		draw_rect(Rect2(x,y,band_width,34.0+i*9.0),Color(0.59,0.67,0.69,.025+i*.012))
