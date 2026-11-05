extends Node2D
const Stock = preload("res://scripts/merchant_stock.gd")
var stock: Array = []
var wallet: Dictionary
var ui: CanvasLayer
var panel: PanelContainer
const Icon = preload("res://scripts/item_icon.gd")
const MerchantArt = preload("res://assets/actors/concepts/dokkaebi-merchant-game-v1.png")
var rows: VBoxContainer
var details: VBoxContainer
var message: Label
var balance: Label
var title := "도깨비상인"
var opened := false
var selected := 0
var entries: Array[Button] = []
var buy_button: Button
const RARITIES := ["일반","희귀","영웅","전설"]
const COLORS := [Color("b8c1b5"),Color("80b2d8"),Color("bd9bd7"),Color("e0be73")]

func style(background: Color,border: Color) -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=background
	box.border_color=border
	box.set_border_width_all(2)
	box.content_margin_left=12
	box.content_margin_right=12
	box.content_margin_top=8
	box.content_margin_bottom=8
	return box
func text_label(text: String,size:=14,color:=Color("dce2d2")) -> Label:
	var label:=Label.new()
	label.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	label.text=text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label
func _ready() -> void:
	ui=CanvasLayer.new()
	ui.layer=20
	add_child(ui)
	var shade:=ColorRect.new()
	shade.color=Color(0.025,.04,.06,.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	shade.name="Shade"
	shade.hide()
	panel=PanelContainer.new()
	panel.position=Vector2(38,32)
	panel.size=Vector2(692,368)
	panel.add_theme_stylebox_override("panel",style(Color("19262e"),Color("9b8864")))
	ui.add_child(panel)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	panel.add_child(content)
	var header:=HBoxContainer.new()
	header.add_child(text_label("도깨비 장터",23,Color("e0c58a")))
	var space:=Control.new()
	space.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(space)
	balance=text_label("",16,Color("a8d8c0"))
	header.add_child(balance)
	var close:=Button.new()
	close.text="닫기 ×"
	close.focus_mode=Control.FOCUS_NONE
	close.pressed.connect(toggle)
	header.add_child(close)
	content.add_child(header)
	content.add_child(text_label(title,14,Color("8faaa9")))
	var body:=HBoxContainer.new()
	body.add_theme_constant_override("separation",16)
	rows=VBoxContainer.new()
	rows.custom_minimum_size=Vector2(274,238)
	rows.add_theme_constant_override("separation",6)
	body.add_child(rows)
	var detail_panel:=PanelContainer.new()
	detail_panel.custom_minimum_size=Vector2(366,238)
	detail_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel",style(Color("111d27"),Color("3f555a")))
	details=VBoxContainer.new()
	details.add_theme_constant_override("separation",9)
	detail_panel.add_child(details)
	body.add_child(detail_panel)
	content.add_child(body)
	message=text_label("상품 선택 → 설명 확인 → 구매. 장비는 가방으로 들어갑니다.",14,Color("b8c8bc"))
	content.add_child(message)
	content.add_child(text_label("1~4 상품 선택  ·  ↑↓ 이동  ·  Enter 구매  ·  E / Esc 닫기",14,Color("a8bfbb")))
	panel.hide()
	var sign:=text_label("[E] 도깨비상인 · 평화구역",14)
	sign.position=Vector2(-88,-142)
	add_child(sign)
	queue_redraw()

func _draw() -> void:
	# Seated hanryang merchant, bundles and antique coin piles are one readable
	# prop cluster so the peaceful shop room is identifiable at a glance.
	draw_texture(MerchantArt,Vector2(-95,-126))

func toggle() -> void:
	opened=not opened
	if opened: refresh()
	panel.visible=opened
	ui.get_node("Shade").visible=opened
func refresh() -> void:
	balance.text="영혼조각  ◆ "+str(wallet["souls"])
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	entries.clear()
	selected=clampi(selected,0,maxi(0,stock.size()-1))
	for i in range(stock.size()):
		var item: Dictionary=stock[i]
		var row:=Button.new()
		row.custom_minimum_size=Vector2(274,52)
		row.focus_mode=Control.FOCUS_NONE
		row.add_theme_stylebox_override("normal",style(Color("233039") if i!=selected else Color("34473f"),COLORS[int(item["tier"])-1] if i==selected else Color("35464a")))
		row.add_theme_stylebox_override("hover",style(Color("35463f"),Color("c7b184")))
		var line:=HBoxContainer.new()
		line.mouse_filter=Control.MOUSE_FILTER_IGNORE
		line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		line.offset_left=6
		line.offset_top=5
		line.offset_right=-6
		var icon:=Icon.new()
		icon.item=item
		line.add_child(icon)
		var labels:=VBoxContainer.new()
		labels.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var type_badge := " [근접]" if item.get("kind","")=="melee" else " [원거리]" if item.get("kind","")=="ranged" else ""
		var name_label:=text_label(str(item["name"])+type_badge,15,COLORS[int(item["tier"])-1])
		name_label.custom_minimum_size.x=196
		name_label.clip_text=true
		labels.add_child(name_label)
		labels.add_child(text_label("판매 완료" if item["sold"] else str(item["price"])+" ◆  ·  "+Stock.DB.slot_name(item["slot"]),14,Color("b4c6ba")))
		line.add_child(labels)
		row.add_child(line)
		row.pressed.connect(func():selected=i;refresh())
		rows.add_child(row)
		entries.append(row)
	refresh_detail()
func refresh_detail() -> void:
	for child in details.get_children():
		details.remove_child(child)
		child.queue_free()
	if stock.is_empty(): return
	var item: Dictionary=stock[selected]
	var tint: Color=COLORS[int(item["tier"])-1]
	var name_label:=text_label(str(item["name"]),21,tint)
	name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	details.add_child(name_label)
	details.add_child(text_label(RARITIES[int(item["tier"])-1]+" · "+Stock.DB.slot_name(item["slot"]),15,tint))
	if item.has("damage"):
		details.add_child(text_label("피해 "+str(item["damage"])+"   /   공격 간격 "+str(item["interval"])+"초",14))
		details.add_child(text_label("사거리 "+str(item["range"])+"   ·   "+("근접" if item["kind"]=="melee" else "원거리"),15,Color("bfd0c5")))
	var effect:=text_label(str(item.get("effect","")),13)
	effect.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	details.add_child(effect)
	var owner=get_parent()
	if owner.get("combat")!=null:
		var slot: String="main" if item["slot"]=="two" else str(item["slot"])
		var current: Dictionary=owner.combat.equipped(slot)
		details.add_child(text_label("현재 장착: "+str(current.get("name","없음")),12,Color("8fa5a3")))
	var spacer:=Control.new()
	spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	details.add_child(spacer)
	buy_button=Button.new()
	buy_button.custom_minimum_size=Vector2(0,38)
	buy_button.focus_mode=Control.FOCUS_NONE
	buy_button.text="판매 완료" if item["sold"] else "영혼조각 부족 · "+str(item["price"])+" ◆" if int(wallet["souls"])<item["price"] else "구매 · "+str(item["price"])+" ◆"
	buy_button.disabled=item["sold"] or int(wallet["souls"])<item["price"]
	buy_button.add_theme_stylebox_override("normal",style(Color("38534b"),Color("b6bd8d")))
	buy_button.pressed.connect(purchase_selected)
	details.add_child(buy_button)
func purchase_selected() -> void:
	var result:=Stock.buy(stock,selected,wallet)
	refresh()
	message.text=result
func _unhandled_key_input(event: InputEvent) -> void:
	if not opened or not event is InputEventKey or not event.pressed or event.echo: return
	var key: int=event.physical_keycode
	if key>=KEY_1 and key<=KEY_4:
		selected=clampi(key-KEY_1,0,stock.size()-1)
		refresh()
	elif key in [KEY_UP,KEY_DOWN]:
		selected=posmod(selected+(-1 if key==KEY_UP else 1),stock.size())
		refresh()
	elif key==KEY_ENTER: purchase_selected()
