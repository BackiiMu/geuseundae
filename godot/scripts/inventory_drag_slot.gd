extends Button
## 가방·장착 칸 공용 버튼. 끌어서 옮기고(_get_drag_data) 다른 칸에 놓을 수 있다(_drop_data).
## 터치는 0.25초 길게 눌러야 집어 들고, 그 전에 밀면 가방 스크롤이 된다. 마우스는 바로 끌 수 있다.

var payload: Dictionary = {}           # {} = 끌 수 없음(빈 칸). 예: {"bag":3} 또는 {"equip":"main"}
var preview_item: Dictionary = {}
var drop_handler: Callable             # func(source:Dictionary, dry:bool) -> bool
var press_time := -1.0
var press_touch := false
var armed := false

const HOLD_SECONDS := .25
const ItemIcon = preload("res://scripts/item_icon.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS        # 스크롤 칸이 끌기를 받을 수 있게 이벤트를 통과시킨다

func _gui_input(event: InputEvent) -> void:
	var touch := event is InputEventScreenTouch or (event is InputEventMouseButton and (event as InputEventMouseButton).device == InputEvent.DEVICE_ID_EMULATION)
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			press_time = Time.get_ticks_msec() / 1000.0
			press_touch = touch
			armed = not touch
		else:
			press_time = -1.0
			armed = false

func _get_drag_data(_at: Vector2) -> Variant:
	if payload.is_empty(): return null
	if press_touch and Time.get_ticks_msec() / 1000.0 - press_time < HOLD_SECONDS: return null   # 길게 누르기 전의 이동은 스크롤
	var holder := Control.new()
	var icon := ItemIcon.new()
	icon.item = preview_item
	icon.show_frame = false
	icon.scale = Vector2.ONE * 1.1
	icon.position = Vector2(-23, -23)
	holder.add_child(icon)
	set_drag_preview(holder)
	return payload

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return drop_handler.is_valid() and data is Dictionary and bool(drop_handler.call(data, true))

func _drop_data(_at: Vector2, data: Variant) -> void:
	if drop_handler.is_valid(): drop_handler.call(data, false)
