extends Control

signal inventory_requested

const HP_FRAME = preload("res://assets/ui/hud/hp-frame-v1.png")
const BAG_CLOSED = preload("res://assets/ui/hud/bag-icon-v1.png")
const BAG_HALF = preload("res://assets/ui/hud/bag-open-half-v1.png")
const BAG_OPEN = preload("res://assets/ui/hud/bag-open-v1.png")
const SETTINGS_ICON = preload("res://assets/ui/hud/settings-icon-v1.png")
const PANEL_TEXTURE = preload("res://assets/ui/modular/panel-normal-v1.png")
const BUTTON_NORMAL = preload("res://assets/ui/modular/button-normal-v1.png")
const BUTTON_HOVER = preload("res://assets/ui/modular/button-hover-v1.png")
const BUTTON_PRESSED = preload("res://assets/ui/modular/button-pressed-v1.png")
const PLAQUE = preload("res://assets/ui/modular/plaque-v1.png")
const PixelSlider = preload("res://scripts/pixel_slider.gd")
const Player = preload("res://scripts/player.gd")

class DashGauge extends Control:
	var charges := 1
	var maximum := 1
	func set_value(value: int, limit: int) -> void:
		charges = maxi(0, value)
		maximum = maxi(1, limit)
		custom_minimum_size = Vector2(18 + maximum * 24 + 34, 32)
		queue_redraw()
	func _draw() -> void:
		var width := 18.0 + maximum * 24.0 + 34.0
		draw_rect(Rect2(0, 2, width, 28), Color("090708"))
		draw_rect(Rect2(0, 2, width, 28), Color("39171a"), false, 2)
		for i in range(maximum):
			var center := Vector2(16 + i * 24, 16)
			var active := i < charges
			draw_circle(center, 9, Color("191008"))
			draw_circle(center, 7, Color("caa35f") if active else Color("3b3024"))
			draw_circle(center, 5, Color("8f6736") if active else Color("201a17"))
			draw_rect(Rect2(center - Vector2(2, 2), Vector2(4, 4)), Color("100a07"))
		draw_string(get_theme_default_font(), Vector2(width - 31, 21), str(charges) + "/" + str(maximum), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b99867"))

var hp_fill: ColorRect
var hp_trail: ColorRect
var hp_text: Label
var dash_gauge: DashGauge
var bag_button: TextureButton
var bag_badge: Label
var settings_button: TextureButton
var settings_shade: ColorRect
var settings_panel: PanelContainer
var settings_open := false
var displayed_health := 0.0
var displayed_max_health := 1.0
var bag_is_open := false
var bag_frame := 0
var bag_anim_timer := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_health_bar()
	build_dash_gauge()
	build_icon_buttons()
	build_settings_panel()

func texture_rect(texture: Texture2D, position: Vector2, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.position = position
	rect.size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func build_health_bar() -> void:
	var root := Control.new()
	root.position = Vector2(14, 10)
	root.size = Vector2(260, 72)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var channel := ColorRect.new()
	channel.position = Vector2(29, 28)
	channel.size = Vector2(223, 15)
	channel.color = Color("0b0708")
	channel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(channel)
	hp_trail = ColorRect.new()
	hp_trail.position = channel.position
	hp_trail.size = channel.size
	hp_trail.color = Color("c9a089")
	hp_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_trail)
	hp_fill = ColorRect.new()
	hp_fill.position = channel.position
	hp_fill.size = channel.size
	hp_fill.color = Color("82201d")
	hp_fill.clip_contents = true
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_fill)
	# Match hud-ui-preview.html exactly: five hard pixel bands rather than a
	# smooth gradient, so the blood-red fill stays readable at 1x scale.
	for band in [[0,2,"c23a2d"],[2,4,"a52a22"],[4,10,"82201d"],[10,13,"5e1517"],[13,15,"3f0c0e"]]:
		var stripe:=ColorRect.new()
		stripe.anchor_right=1.0
		stripe.offset_top=band[0]
		stripe.offset_bottom=band[1]
		stripe.color=Color(band[2])
		stripe.mouse_filter=Control.MOUSE_FILTER_IGNORE
		hp_fill.add_child(stripe)
	root.add_child(texture_rect(HP_FRAME, Vector2.ZERO, Vector2(260, 72)))
	hp_text = Label.new()
	hp_text.position = Vector2(29, 26)
	hp_text.size = Vector2(223, 20)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_text.add_theme_font_size_override("font_size", 11)
	hp_text.add_theme_color_override("font_color", Color("f0e4d0"))
	hp_text.add_theme_color_override("font_shadow_color", Color.BLACK)
	hp_text.add_theme_constant_override("shadow_offset_x", 1)
	hp_text.add_theme_constant_override("shadow_offset_y", 1)
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hp_text)

func build_dash_gauge() -> void:
	dash_gauge = DashGauge.new()
	dash_gauge.position = Vector2(20, 84)
	dash_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dash_gauge)

func build_icon_buttons() -> void:
	bag_button = TextureButton.new()
	bag_button.position = Vector2(650, 12)
	bag_button.size = Vector2(48, 48)
	bag_button.texture_normal = BAG_CLOSED
	bag_button.texture_hover = BAG_CLOSED
	bag_button.ignore_texture_size = true
	bag_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	bag_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bag_button.tooltip_text = "가방"
	bag_button.pressed.connect(func(): inventory_requested.emit())
	add_child(bag_button)
	bag_badge = Label.new()
	bag_badge.position = Vector2(681, 46)
	bag_badge.custom_minimum_size = Vector2(22, 16)
	bag_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bag_badge.add_theme_font_size_override("font_size", 10)
	bag_badge.add_theme_color_override("font_color", Color("e0c68a"))
	bag_badge.add_theme_stylebox_override("normal", flat_box(Color("0b0708"), Color("6f211d"), 1, 2))
	bag_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bag_badge)
	settings_button = TextureButton.new()
	settings_button.position = Vector2(712, 14)
	settings_button.size = Vector2(44, 44)
	settings_button.texture_normal = SETTINGS_ICON
	settings_button.texture_hover = SETTINGS_ICON
	settings_button.ignore_texture_size = true
	settings_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	settings_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	settings_button.tooltip_text = "설정"
	settings_button.pressed.connect(toggle_settings)
	add_child(settings_button)

func textured_box(texture: Texture2D, margin: int) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	box.texture_margin_left = margin
	box.texture_margin_right = margin
	box.texture_margin_top = margin
	box.texture_margin_bottom = margin
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = margin
	box.content_margin_bottom = margin
	return box

func flat_box(background: Color, border: Color, width: int, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_content_margin_all(margin)
	return box

func styled_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(116, 38)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", textured_box(BUTTON_NORMAL, 14))
	button.add_theme_stylebox_override("hover", textured_box(BUTTON_HOVER, 14))
	button.add_theme_stylebox_override("pressed", textured_box(BUTTON_PRESSED, 14))
	button.add_theme_font_size_override("font_size", 13)
	return button

func setting_toggle(label_text: String, active: bool, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var toggle := styled_button("켜짐" if active else "꺼짐")
	toggle.custom_minimum_size = Vector2(72, 30)
	toggle.toggle_mode = true
	toggle.button_pressed = active
	toggle.toggled.connect(func(on: bool):
		toggle.text = "켜짐" if on else "꺼짐"
		callback.call(on))
	row.add_child(toggle)
	return row

func build_settings_panel() -> void:
	settings_shade = ColorRect.new()
	settings_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_shade.color = Color(0, 0, 0, .68)
	settings_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(settings_shade)
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(204, 54)
	settings_panel.size = Vector2(360, 324)
	settings_panel.add_theme_stylebox_override("panel", textured_box(PANEL_TEXTURE, 28))
	settings_shade.add_child(settings_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	settings_panel.add_child(content)
	var plaque := TextureRect.new()
	plaque.texture = PLAQUE
	plaque.custom_minimum_size = Vector2(150, 44)
	plaque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plaque.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var title := Label.new()
	title.text = "설정"
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color("4a2a1a"))
	plaque.add_child(title)
	var plaque_center := CenterContainer.new()
	plaque_center.add_child(plaque)
	content.add_child(plaque_center)
	var volume_row := HBoxContainer.new()
	var volume_label := Label.new()
	volume_label.text = "전체 음량"
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_row.add_child(volume_label)
	var volume := PixelSlider.new()
	volume.custom_minimum_size = Vector2(170, 24)
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 5
	var master := AudioServer.get_bus_index("Master")
	volume.value = db_to_linear(AudioServer.get_bus_volume_db(master)) * 100.0
	volume.value_changed.connect(func(value: float): AudioServer.set_bus_volume_db(master, linear_to_db(maxf(value / 100.0, .001))))
	volume_row.add_child(volume)
	content.add_child(volume_row)
	content.add_child(setting_toggle("전체 화면",DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,func(on: bool): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)))
	content.add_child(setting_toggle("이동 방향으로 대시",Player.dash_to_move_direction,func(on: bool): Player.dash_to_move_direction=on))
	var close_center := CenterContainer.new()
	var close := styled_button("닫기")
	close.pressed.connect(toggle_settings)
	close_center.add_child(close)
	content.add_child(close_center)
	settings_shade.hide()

func toggle_settings() -> void:
	settings_open = not settings_open
	settings_shade.visible = settings_open
	settings_button.modulate = Color("fff0c4") if settings_open else Color.WHITE

func set_inventory_open(open: bool) -> void:
	if bag_is_open == open:
		return
	bag_is_open = open
	bag_frame = 0 if open else 2
	bag_anim_timer = 0.0

func set_stats(health: float, maximum_health: float, bag_count: int, dash_charges: int, dash_maximum: int) -> void:
	var old_ratio := displayed_health / displayed_max_health if displayed_max_health > 0 else 1.0
	displayed_health = health
	displayed_max_health = maxf(1.0, maximum_health)
	var ratio := clampf(displayed_health / displayed_max_health, 0.0, 1.0)
	hp_fill.size.x = 223.0 * ratio
	if ratio >= old_ratio:
		hp_trail.size.x = hp_fill.size.x
	else:
		var tween := create_tween()
		tween.tween_interval(.25)
		tween.tween_property(hp_trail, "size:x", hp_fill.size.x, .45)
	hp_text.text = str(int(ceil(displayed_health))) + " / " + str(int(ceil(displayed_max_health)))
	bag_badge.text = str(bag_count)
	dash_gauge.set_value(dash_charges, dash_maximum)

func _process(delta: float) -> void:
	var ratio := displayed_health / displayed_max_health if displayed_max_health > 0 else 1.0
	hp_fill.modulate = Color.WHITE.lerp(Color("ff9284"), (sin(Time.get_ticks_msec() * .018) + 1.0) * .25) if ratio <= .25 and ratio > 0 else Color.WHITE
	if bag_anim_timer >= 0:
		bag_anim_timer += delta
		if bag_anim_timer >= .09:
			bag_anim_timer = 0.0
			bag_frame += 1 if bag_is_open else -1
			bag_frame = clampi(bag_frame, 0, 2)
			bag_button.texture_normal = [BAG_CLOSED, BAG_HALF, BAG_OPEN][bag_frame]
			bag_button.texture_hover = bag_button.texture_normal
			if (bag_is_open and bag_frame == 2) or (not bag_is_open and bag_frame == 0):
				bag_anim_timer = -1.0
