extends Control
## 시작 인트로: 빈 마당 → 대문 → 웅덩이에서 그림자 소환 → 타이틀.
## 좌표는 640×360 기준으로 그리고 768×432 화면에 1.2배로 확대한다 (intro-preview.html과 같은 값).

const YARD = preload("res://assets/haunted-courtyard.png")
const TITLE_BG = preload("res://assets/ui/title/title-background-v1.png")
const RISE = preload("res://assets/vfx/summon/shadow-rise.png")
const BUTTON_NORMAL = preload("res://assets/ui/modular/button-normal-v1.png")
const BUTTON_HOVER = preload("res://assets/ui/modular/button-hover-v1.png")
const BUTTON_PRESSED = preload("res://assets/ui/modular/button-pressed-v1.png")
const NEXT_SCENE := "res://scenes/title_screen.tscn"

const W := 640.0
const H := 360.0
const K := 1.2
const TOTAL := 24.0
const BAR := 26.0
const FW := 170
const FH := 112
const COLS := 11
const NF := 175
const PX := 85.0
const PY := 92.0

const SCENES := [
	{"t": 0.0, "d": 4.5, "cap": ["억울하게 죽은 이들은 이승을 떠나지 못했다."]},
	{"t": 4.5, "d": 5.0, "cap": ["날이 저물면 퇴마꾼들이 횃불을 들고 찾아왔다."]},
	{"t": 9.5, "d": 5.0, "cap": ["쫓겨나느니, 뭔지 모를 귀신에게 심장을 빌려주기로 했다."]},
	{"t": 14.5, "d": 5.5, "cap": ["심장을 건넨 자리에, 그림자가 몸을 얻는다.", "이번에는 우리가 되갚을 차례다."]},
	{"t": 20.0, "d": 4.0, "cap": []},
]

var elapsed := 0.0
var finished := false
var skip_button: Button
var glow_tex: GradientTexture2D
var vignette_tex: GradientTexture2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glow_tex = radial_texture(Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.0)
	vignette_tex = radial_texture(Color(0, 0, 0, 0), Color(0, 0, 0, 1), 0.38)
	var skip := Button.new()
	skip_button = skip
	skip.text = "건너뛰기"
	skip.focus_mode = Control.FOCUS_NONE
	skip.size = Vector2(92, 28)
	skip.position = Vector2(768 - 92 - 8, 2)
	skip.add_theme_font_size_override("font_size", 13)
	skip.add_theme_stylebox_override("normal", box(BUTTON_NORMAL, 12))
	skip.add_theme_stylebox_override("hover", box(BUTTON_HOVER, 12))
	skip.add_theme_stylebox_override("pressed", box(BUTTON_PRESSED, 12))
	skip.pressed.connect(finish)
	add_child(skip)

func radial_texture(inner: Color, outer: Color, inner_at: float) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([inner_at, 1.0])
	gradient.colors = PackedColorArray([inner, outer])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture

func box(texture: Texture2D, margin: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_right = margin
	style.texture_margin_top = margin
	style.texture_margin_bottom = margin
	return style

func _process(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	skip_button.visible = elapsed < float(SCENES[4]["t"])
	if elapsed >= TOTAL:
		finish()
		return
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		finish()
		get_viewport().set_input_as_handled()

func finish() -> void:
	if finished:
		return
	finished = true
	get_tree().change_scene_to_file(NEXT_SCENE)

# ---------- 그리기 도구 ----------
func rnd(n: float) -> float:
	var x := sin(n * 127.1 + 311.7) * 43758.5453
	return x - floor(x)

func seg(t: float, a: float, b: float) -> float:
	return clampf((t - a) / (b - a), 0.0, 1.0)

func ease_io(t: float) -> float:
	return 2.0 * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0

func cover(tex: Texture2D, src: Rect2, alpha: float = 1.0) -> void:
	draw_texture_rect_region(tex, Rect2(0, 0, W, H), src, Color(1, 1, 1, alpha))

func tint(color: Color, alpha: float) -> void:
	draw_rect(Rect2(0, 0, W, H), Color(color.r, color.g, color.b, alpha))

func glow(center: Vector2, radius: float, color: Color) -> void:
	draw_texture_rect(glow_tex, Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)

func vignette(alpha: float) -> void:
	draw_texture_rect(vignette_tex, Rect2(0, 0, W, H), false, Color(1, 1, 1, alpha))

func rain(t: float, amount: float, wind: float = 0.25) -> void:
	var count := int(90.0 * amount)
	for i in count:
		var sp := 260.0 + rnd(i) * 160.0
		var x0 := rnd(i + 9) * (W + 80.0) - 40.0
		var y := fposmod(rnd(i + 3) * H + t * sp, H + 30.0) - 15.0
		var x := x0 - y * wind * 0.4
		draw_line(Vector2(x, y), Vector2(x - wind * 5.0, y + 8.0 + rnd(i + 5) * 6.0), Color(0.59, 0.67, 0.76, 0.28), 1.0)

func caption(text: String, alpha: float) -> void:
	if alpha <= 0.0 or text == "":
		return
	var font := get_theme_default_font()
	var size := 13
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 28.0
	var y := H - BAR - 8.0
	draw_rect(Rect2(W / 2.0 - width / 2.0, y - 13.0, width, 26.0), Color(0, 0, 0, 0.55 * alpha))
	draw_string(font, Vector2(W / 2.0 - width / 2.0, y + 5.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, Color(0.9, 0.85, 0.73, alpha))

# ---------- 장면 ----------
func scene_dark(lt: float, t: float) -> void:
	draw_rect(Rect2(0, 0, W, H), Color("05070a"))
	var a := ease_io(seg(lt, 0.8, 4.2)) * 0.35
	cover(YARD, Rect2(lt * 2.0, 0, 724.0 * W / H, 724), a)
	rain(t, 0.6)
	vignette(0.9)

func scene_yard(lt: float, t: float, dur: float) -> void:
	var sw := 724.0 * W / H
	var max_pan := YARD.get_width() - sw
	var sx := max_pan * (0.15 + 0.55 * ease_io(lt / dur))
	cover(YARD, Rect2(sx, 0, sw, 724))
	tint(Color("06101c"), 0.28)
	rain(t, 1.0)
	var f := maxf(0.0, 1.0 - absf(lt - 2.35) * 9.0) + maxf(0.0, 0.6 - absf(lt - 2.7) * 9.0)
	if f > 0.0:
		tint(Color("cfe0ff"), clampf(f, 0.0, 1.0) * 0.5)
	torches(lt, t)
	vignette(0.7)

func torches(lt: float, t: float) -> void:
	var a := ease_io(seg(lt, 1.6, 3.4))
	if a <= 0.0:
		return
	var people := [Vector2(-20, 300), Vector2(-52, 306), Vector2(-86, 298)]
	var heights := [34.0, 38.0, 32.0]
	for i in people.size():
		var x: float = people[i].x + lt * 20.0 + a * 70.0
		var y: float = people[i].y
		var h: float = heights[i]
		var fl := 0.75 + 0.25 * sin(t * 17.0 + i * 2.0) + 0.1 * rnd(floor(t * 14.0) + i)
		glow(Vector2(x + 7.0, y - h + 8.0), 70.0, Color(1.0, 0.59, 0.24, 0.32 * fl * a))
		var dark := Color(0.024, 0.031, 0.043, a)
		draw_rect(Rect2(x - 4, y - h + 10, 9, h - 10), dark)
		draw_rect(Rect2(x - 3, y - h + 4, 7, 6), dark)
		draw_rect(Rect2(x - 6, y - h + 3, 13, 2), dark)
		draw_rect(Rect2(x + 5, y - h + 9, 2, (h - 9) * 0.55), dark)
		draw_rect(Rect2(x + 4, y - h + 3, 4, 6), Color(1.0, 0.67 + fl * 0.2, 0.27, a))
		draw_rect(Rect2(x + 5, y - h + 5, 2, 3), Color(1.0, 0.92, 0.63, a))
		draw_rect(Rect2(x - 10, y + 2, 24, 2), Color(1.0, 0.6, 0.25, a * 0.18 * fl))

func scene_gate(lt: float, t: float, dur: float) -> void:
	var k := ease_io(lt / dur)
	# 타이틀 배경 위쪽에 로고가 있어 y 200 아래(대문 하단)만 잘라 줌인한다
	var vh := 232.0 - 60.0 * k
	var vw := vh * 16.0 / 9.0
	var cx := 640.0 + 50.0 * k
	var sy := 200.0 + 22.0 * k
	var sx := clampf(cx - vw / 2.0, 0.0, 768.0 - vw)
	cover(TITLE_BG, Rect2(sx, sy, vw, vh))
	tint(Color("05080f"), 0.25)
	var gl := ease_io(seg(lt, 2.2, 4.6))
	glow(Vector2(560, 200), 170.0, Color(0.59, 0.12, 0.09, 0.28 * gl))
	rain(t, 0.9)
	vignette(0.75)

func scene_summon(lt: float, t: float, dur: float) -> void:
	cover(TITLE_BG, Rect2(150, 210, 395, 222))
	tint(Color("04070c"), 0.5 + 0.25 * (1.0 - ease_io(seg(lt, 0.0, 1.2))))
	var fi := mini(NF - 1, int(clampf(lt / (dur - 0.1), 0.0, 1.0) * NF))
	var sc := 2.8
	var dst := Rect2(W / 2.0 - PX * sc, 300.0 - PY * sc, FW * sc, FH * sc)
	draw_texture_rect_region(RISE, dst, Rect2((fi % COLS) * FW, (fi / COLS) * FH, FW, FH))
	rain(t, 0.8)
	vignette(0.8)

func scene_title(lt: float, t: float) -> void:
	cover(TITLE_BG, Rect2(0, 0, 768, 432))
	rain(t, 0.7)
	tint(Color.BLACK, 1.0 - ease_io(seg(lt, 0.0, 1.2)))
	vignette(0.5)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(K, K))
	var t := clampf(elapsed, 0.0, TOTAL - 0.001)
	var idx := 0
	for i in SCENES.size():
		if t >= SCENES[i]["t"]:
			idx = i
	var s: Dictionary = SCENES[idx]
	var lt: float = t - float(s["t"])
	var dur: float = s["d"]
	match idx:
		0: scene_dark(lt, t)
		1: scene_yard(lt, t, dur)
		2: scene_gate(lt, t, dur)
		3: scene_summon(lt, t, dur)
		_: scene_title(lt, t)
	if idx > 0 and idx < 4:
		var fade_in := 1.0 - seg(lt, 0.0, 0.6)
		if fade_in > 0.0:
			tint(Color.BLACK, fade_in)
	if idx < 3:
		var fade_out := seg(lt, dur - 0.5, dur)
		if fade_out > 0.0:
			tint(Color.BLACK, fade_out)
	# 레터박스: 타이틀 장면에서는 걷어 낸다
	var bar := BAR * (1.0 - ease_io(seg(lt, 0.0, 1.2)) if idx == 4 else 1.0)
	draw_rect(Rect2(0, 0, W, bar), Color.BLACK)
	draw_rect(Rect2(0, H - bar, W, bar), Color.BLACK)
	var cap: Array = s["cap"]
	var per := (dur - 0.4) / maxf(cap.size(), 1)
	for i in cap.size():
		var l := lt - i * per - 0.4
		caption(cap[i], minf(seg(l, 0.1, 0.7), 1.0 - seg(l, per - 0.8, per - 0.2)))
	if t > 19.85 and t < 20.3:
		tint(Color(0.81, 0.85, 0.9), (1.0 - seg(t, 19.85, 20.3)) * 0.55)
