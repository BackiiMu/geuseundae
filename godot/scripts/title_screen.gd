extends Control

const BACKGROUND = preload("res://assets/ui/title/title-background-v1.png")
const PANEL_TEXTURE = preload("res://assets/ui/modular/panel-normal-v1.png")
const BUTTON_NORMAL = preload("res://assets/ui/modular/button-normal-v1.png")
const BUTTON_HOVER = preload("res://assets/ui/modular/button-hover-v1.png")
const BUTTON_PRESSED = preload("res://assets/ui/modular/button-pressed-v1.png")
const PLAQUE = preload("res://assets/ui/modular/plaque-v1.png")
const SETTINGS_ICON = preload("res://assets/ui/hud/settings-icon-v1.png")
const PixelSlider = preload("res://scripts/pixel_slider.gd")

var settings_shade: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(background)
	var menu := VBoxContainer.new()
	var show_mobile_test := OS.has_feature("mobile") or OS.is_debug_build()
	menu.position = Vector2(282, 165 if show_mobile_test else 225)
	menu.size = Vector2(204, 174 if show_mobile_test else 112)
	menu.add_theme_constant_override("separation", 12)
	add_child(menu)
	var start := title_button("게임 시작")
	start.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/village.tscn"))
	menu.add_child(start)
	if show_mobile_test:
		var full_test := title_button("전체 장비 테스트")
		full_test.pressed.connect(start_full_test_run)
		menu.add_child(full_test)
	var settings := title_button("설정", SETTINGS_ICON)
	settings.pressed.connect(toggle_settings)
	menu.add_child(settings)
	build_settings()

func start_full_test_run() -> void:
	get_tree().set_meta("full_test_run_requested", true)
	get_tree().change_scene_to_file("res://scenes/village.tscn")

func box(texture: Texture2D, margin: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style

func title_button(text: String, icon: Texture2D = null) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 24)
	button.custom_minimum_size = Vector2(204, 50)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", box(BUTTON_NORMAL, 16))
	button.add_theme_stylebox_override("hover", box(BUTTON_HOVER, 16))
	button.add_theme_stylebox_override("pressed", box(BUTTON_PRESSED, 16))
	button.add_theme_stylebox_override("focus", box(BUTTON_HOVER, 16))
	button.add_theme_font_size_override("font_size", 16)
	return button

func flat_box(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	return style

func setting_toggle(label_text: String, active: bool, callback: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var toggle := title_button("켜짐" if active else "꺼짐")
	toggle.custom_minimum_size = Vector2(72,30)
	toggle.toggle_mode = true
	toggle.button_pressed = active
	toggle.toggled.connect(func(on: bool):
		toggle.text = "켜짐" if on else "꺼짐"
		callback.call(on))
	row.add_child(toggle)
	return row

func build_settings() -> void:
	settings_shade = ColorRect.new()
	settings_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_shade.color = Color(0, 0, 0, .72)
	add_child(settings_shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(204, 70)
	panel.size = Vector2(360, 292)
	panel.add_theme_stylebox_override("panel", box(PANEL_TEXTURE, 28))
	settings_shade.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	var plaque := TextureRect.new()
	plaque.texture = PLAQUE
	plaque.custom_minimum_size = Vector2(150, 44)
	plaque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var title := Label.new()
	title.text = "설정"
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("4a2a1a"))
	title.add_theme_font_size_override("font_size", 15)
	plaque.add_child(title)
	var plaque_center := CenterContainer.new()
	plaque_center.add_child(plaque)
	content.add_child(plaque_center)
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = "전체 음량"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var slider := PixelSlider.new()
	slider.custom_minimum_size = Vector2(170, 28)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	var master := AudioServer.get_bus_index("Master")
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(master)) * 100.0
	slider.value_changed.connect(func(value: float): AudioServer.set_bus_volume_db(master, linear_to_db(maxf(value / 100.0, .001))))
	row.add_child(slider)
	content.add_child(row)
	content.add_child(setting_toggle("전체 화면",DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,func(on: bool): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)))
	var close_center := CenterContainer.new()
	var close := title_button("닫기")
	close.custom_minimum_size = Vector2(130, 42)
	close.pressed.connect(toggle_settings)
	close_center.add_child(close)
	content.add_child(close_center)
	settings_shade.hide()

func toggle_settings() -> void:
	settings_shade.visible = not settings_shade.visible

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings_shade.visible:
		toggle_settings()
		get_viewport().set_input_as_handled()
