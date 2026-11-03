extends Node2D
const Generator = preload("res://scripts/run_generator.gd")
const Catalog = preload("res://scripts/room_catalog.gd")
const RoomView = preload("res://scripts/room_view.gd")
const Merchant = preload("res://scripts/merchant.gd")
const MerchantStock = preload("res://scripts/merchant_stock.gd")
const CombatDirector = preload("res://scripts/combat_director.gd")
const Player = preload("res://scripts/player.gd")
@export var start_in_village := false
@export var combat_enabled := true
var combat: Node2D
var in_village := false
var floor_number := 1
var village_stock: Array = []
var wallet: Dictionary = {"souls":0,"bag":[]}
var merchant: Node2D
var run: Dictionary
var current_id := 0
var room: Node2D
var player: CharacterBody2D
var portal_links: Array = []
var hint: Label
var title: Label
var minimap: Control
var seed_input: LineEdit
var visited_count := 0
var cooldown := 0.0
var web_status_timer := 0.0
var lab_snapshot: Dictionary = {}
var lab_index := 0
var lab_button: Button
var complete := false
var floor_exit_position := Vector2.ZERO

func bind_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action,event)

func _ready() -> void:
	var bindings: Dictionary = {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE],"dash":[KEY_SHIFT],"restart":[KEY_R],"collision_view":[KEY_F1],"interact":[KEY_E],"new_run":[KEY_N],"inventory":[KEY_TAB,KEY_I],"heart_skill":[KEY_Q],"main_skill":[KEY_F],"off_skill":[KEY_G],"boss_test":[KEY_F8],"fx_freeze":[KEY_F9],"equipment_lab":[KEY_F6],"lab_next":[KEY_BRACKETRIGHT],"lab_previous":[KEY_BRACKETLEFT],"lab_ai":[KEY_Y],"lab_reset":[KEY_T],"lab_set":[KEY_P],"attack":[KEY_J]}
	for action in bindings:
		bind_action(action,bindings[action])
	var mouse := InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack",mouse)
	build_hud()
	combat=CombatDirector.new()
	combat.world=self
	combat.enabled=combat_enabled
	add_child(combat)
	if combat_enabled: combat.seed_starter()
	var initial_seed := 1103
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			initial_seed = int(argument.trim_prefix("--seed="))
	var session_rng := RandomNumberGenerator.new()
	session_rng.randomize()
	village_stock = MerchantStock.roll(session_rng.randi(),1,true)
	if start_in_village: show_village()
	else: new_run(initial_seed)
	if OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--touch"):
		var layer:=CanvasLayer.new()
		layer.layer=15
		add_child(layer)
		var touch=load("res://scripts/mobile_controls.gd").new()
		touch.world=self
		layer.add_child(touch)
		lab_button.hide()

func new_run(value: int) -> void:
	in_village = false
	run = Generator.generate(value)
	assert(Generator.validate(run))
	complete = false
	seed_input.text = str(value)
	change_room(0,-1)

func show_village() -> void:
	in_village = true
	complete = false
	run = {"version":Generator.VERSION,"seed":1103,"start":0,"goal":-1,"rooms":[{"id":0,"template":"courtyard","links":[],"grid":[0,0],"decor_seed":1103,"visited":false,"peaceful":true}]}
	change_room(0,-1)
	var sign := Label.new()
	sign.position = Vector2(1570,578)
	sign.text = "[E] 1층으로 출발"
	room.add_child(sign)

func is_combat_room() -> bool:
	return not in_village and not bool(run["rooms"][current_id].get("peaceful",false))

func portal_position(source: int, destination: int) -> Vector2:
	var def: Dictionary = Catalog.templates()[run["rooms"][source]["template"]]
	var grid: Array = run["rooms"][source]["grid"]
	var other: Array = run["rooms"][destination]["grid"]
	var width := float(def["width"])
	if other[0] < grid[0]:
		return Vector2(96, 704)
	if other[0] > grid[0]:
		return Vector2(width-96, 704)
	if other[1] < grid[1]:
		# The upper connection sits on a reachable authored balcony.
		var top: Array = def["platforms"][0]
		for platform in def["platforms"]:
			if platform[1] < top[1]:
				top = platform
		return Vector2(top[0]+top[2]/2.0, top[1])
	# The remaining floor connection is well away from both edge doors.
	var x := width*.70
	for gap in def["gaps"]:
		if x > gap[0]-100 and x < gap[0]+gap[1]+100:
			x = gap[0]+gap[1]+100
	return Vector2(x,704)

func change_room(id: int, previous: int) -> void:
	if is_instance_valid(combat): combat.leave_room()
	if is_instance_valid(merchant):
		remove_child(merchant)
		merchant.queue_free()
	merchant = null
	if is_instance_valid(room):
		remove_child(room)
		room.queue_free()
	if is_instance_valid(player):
		remove_child(player)
		player.queue_free()
	current_id = id
	var data: Dictionary = run["rooms"][id]
	data["visited"] = true
	var def: Dictionary = Catalog.templates()[data["template"]]
	if combat_enabled and not in_village and id==run["goal"]:
		def=Catalog.templates()["sanctum"]
		data["template"]="sanctum"
	room = RoomView.new()
	room.z_index=-20
	add_child(room)
	room.build(def,data["decor_seed"])
	portal_links = data["links"].duplicate()
	for next in portal_links:
		var door: Vector2 = portal_position(id,next)
		room.door_positions.append(door)
		var label := Label.new()
		label.position = door + Vector2(-62,-118)
		label.text = "[E] " + str(Catalog.templates()[run["rooms"][next]["template"]]["name"])
		label.add_theme_font_size_override("font_size",15)
		room.add_child(label)
	room.queue_redraw()
	player = Player.new()
	player.name = "ScaleMarker"
	var spawn_point := Vector2(144,690)
	if previous >= 0:
		var door := portal_position(id,previous)
		spawn_point = door + Vector2(60 if door.x < float(def["width"])/2 else -60,-14)
	player.spawn = spawn_point
	player.position = spawn_point
	add_child(player)
	player.camera.limit_right = def["width"]
	player.camera.limit_bottom = 864
	player.camera.reset_smoothing()
	cooldown = .3
	if not is_combat_room():
		merchant = Merchant.new()
		merchant.position = Vector2(400,704)
		merchant.wallet = wallet
		if in_village:
			merchant.stock = village_stock
			merchant.title = "마을 도깨비상인 · 1~2단계"
		else:
			if not data.has("shop_stock"):
				data["shop_stock"] = MerchantStock.roll(int(run["seed"]) ^ (floor_number*7919),floor_number)
			merchant.stock = data["shop_stock"]
			merchant.title = str(floor_number)+"층 도깨비상인 · 평화구역"
		add_child(merchant)
		if not in_village and is_instance_valid(combat) and not data.get("rested",false):
			data["rested"]=true
			combat.health=60
			combat.message("평화구역 · 도깨비의 쉼터에서 HP 회복")
	if id == run["goal"]:
		var exit_label := Label.new()
		floor_exit_position=Vector2(float(def["width"])*.5,704)
		exit_label.position = floor_exit_position+Vector2(-65,-96)
		exit_label.text = "[E] 구간 출구"
		exit_label.add_theme_font_size_override("font_size",14)
		room.add_child(exit_label)
	title.text = str(def["name"]) + "  ·  SEED " + str(run["seed"]) + " / V" + str(run["version"]) + " / 포탈 " + str(data["links"].size()) + "개"
	if in_village: title.text = "흉가 마을 · 도깨비상인 / 재접속 시 재고 갱신"
	else: title.text = str(floor_number)+"층 · "+title.text
	minimap.queue_redraw()
	if is_instance_valid(combat): combat.enter_room(data)

func _process(delta: float) -> void:
	web_status_timer-=delta
	if web_status_timer<=0:
		update_web_status()
		web_status_timer=.2
	if not is_instance_valid(player):
		return
	if Input.is_action_just_pressed("equipment_lab"):
		toggle_equipment_lab()
		return
	if combat.equipment_lab:
		if Input.is_action_just_pressed("fx_freeze"): combat.vfx_preview_paused=not combat.vfx_preview_paused
		if not combat.inventory.visible:
			if Input.is_action_just_pressed("lab_next"): cycle_lab(1)
			if Input.is_action_just_pressed("lab_previous"): cycle_lab(-1)
			if Input.is_action_just_pressed("lab_reset"): reset_lab_targets()
			if Input.is_action_just_pressed("lab_ai"):
				for enemy in combat.living(): enemy.training_dummy=not enemy.training_dummy
				combat.message("Y · 적 행동 전환 / 시험장에서는 피격 피해 없음")
			if Input.is_action_just_pressed("lab_set"):
				combat.equipment.merge({"main":"fist","off":"","head":"duo_head","a0":"duo_curse"},true)
				combat.skill_cd={"main":0.0,"off":0.0}
				combat.message("두억시니 3종 장착 · G 짓누르기 / Shift 대시 공격")
		hint.text="시험장 · [ ] 장비 · T 초기화 · Y 적 AI · P 세트 · F9 정지 · F6 복귀"
		return
	cooldown = maxf(0,cooldown-delta)
	if is_instance_valid(merchant) and merchant.opened:
		player.controls_enabled = false
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_cancel"):
			merchant.toggle()
		return
	player.controls_enabled = not seed_input.has_focus() and not (is_instance_valid(combat) and combat.inventory.visible)
	if not player.controls_enabled:
		return
	if is_instance_valid(merchant) and player.position.distance_to(merchant.position)<80:
		hint.text = "E · 도깨비상인 / 평화구역 / 영혼조각 "+str(wallet["souls"])
		if Input.is_action_just_pressed("interact"): merchant.toggle()
		return
	if combat_enabled and Input.is_action_just_pressed("boss_test"):
		new_run(1103)
		change_room(run["goal"],-1)
		combat.health=60
		combat.hurt_timer=1.0
		return
	if in_village:
		if player.position.x>1570:
			hint.text = "E · 1층으로 출발"
			if Input.is_action_just_pressed("interact"):
				floor_number=1
				new_run(1103)
		else: hint.text = "마을 · 도깨비상인과 거래 / 오른쪽에서 1층 출발"
		return
	if Input.is_action_just_pressed("new_run"):
		new_run(int(run["seed"])+1)
		return
	if Input.is_action_just_pressed("collision_view"):
		room.debug_visible = not room.debug_visible
		room.queue_redraw()
	if combat_enabled and combat.locked():
		hint.text="남은 적 "+str(combat.living().size())+" · "+combat.enemy_location_hint()+" · 전멸 시 문 열림"
		return
	var nearby := -1
	var closest := 78.0
	for i in range(room.door_positions.size()):
		if player.position.distance_to(room.door_positions[i]) < closest:
			closest = player.position.distance_to(room.door_positions[i])
			nearby = i
	if combat_enabled and Input.is_action_just_pressed("interact") and combat.try_open_chest():
		return
	if nearby >= 0:
		hint.text = "E · " + str(Catalog.templates()[run["rooms"][portal_links[nearby]]["template"]]["name"])+" 이동"
		if cooldown<=0 and Input.is_action_just_pressed("interact"):
			change_room(portal_links[nearby],current_id)
		return
	if current_id==run["goal"] and player.position.distance_to(floor_exit_position)<84:
		hint.text="E · 다음 층으로 출발" if complete else "E · 구간 탐색 완료"
		if Input.is_action_just_pressed("interact"):
			if complete:
				floor_number+=1
				new_run(int(run["seed"])+1009)
			else: complete=true
		return
	hint.text="E · 클리어 보상 상자 열기" if combat_enabled and combat.near_chest() else "문 앞 E · 이동  |  Tab 가방  |  목표: 봉인의 마당"

func update_web_status() -> void:
	if not OS.has_feature("web") or not is_instance_valid(player) or not is_instance_valid(combat): return
	var text:="마을" if in_village else str(floor_number)+"층 · "+str(room.definition["name"])
	text+=" | HP "+str(int(combat.health))+"/60 | 영혼조각 "+str(wallet["souls"])+" | 남은 적 "+str(combat.living().size())
	if combat.inventory.visible: text+=" | 가방 열림 (일시정지)"
	if is_instance_valid(merchant) and merchant.opened:
		text+=" | 상점 · "+str(merchant.stock[merchant.selected]["name"])+" "+str(merchant.stock[merchant.selected]["price"])+"조각"
	if combat.equipment_lab:
		text="장비 시험장 | "+str(combat.equipped("main").get("name","없음"))+" + "+str(combat.equipped("off").get("name","없음"))+" | 표적 "+str(combat.living().size())+" | 가방 "+str(wallet["bag"].size())
	text+=" | "+hint.text
	JavaScriptBridge.eval("document.getElementById('playtest-status').textContent="+JSON.stringify(text),true)

func combat_death() -> void:
	combat.inventory.hide()
	combat.inventory_shade.hide()
	combat.health=60
	combat.heart_cd=0
	combat.hurt_timer=1
	show_village()
	combat.message("빌린 모습이 깨졌습니다 · 마을로 귀환")

func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := ColorRect.new()
	panel.position = Vector2(10,10)
	panel.size = Vector2(748,72)
	panel.color = Color(0.04,.06,.09,.9)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	title = Label.new()
	title.position = Vector2(22,14)
	title.size.x=435
	title.clip_text=true
	title.add_theme_font_size_override("font_size",17)
	layer.add_child(title)
	var instructions := Label.new()
	instructions.position = Vector2(22,43)
	instructions.text = "A/D 이동  Space 점프  Shift 대시  E 상호작용  Tab 가방"
	instructions.add_theme_font_size_override("font_size",15)
	layer.add_child(instructions)
	seed_input = LineEdit.new()
	seed_input.position = Vector2(22,90)
	seed_input.size = Vector2(100,28)
	seed_input.placeholder_text = "시드 번호"
	seed_input.text_submitted.connect(func(value: String):
		if value.is_valid_int():
			seed_input.release_focus()
			new_run(int(value)))
	seed_input.hide()
	layer.add_child(seed_input)
	var button := Button.new()
	button.position = Vector2(130,90)
	button.size = Vector2(84,28)
	button.text = "배치 생성"
	button.pressed.connect(func():
		if seed_input.text.is_valid_int():
			seed_input.release_focus()
			new_run(int(seed_input.text)))
	button.focus_mode = Control.FOCUS_NONE
	button.hide()
	layer.add_child(button)
	hint = Label.new()
	hint.position = Vector2(16,406)
	hint.size.x=736
	hint.clip_text=true
	hint.add_theme_font_size_override("font_size",15)
	layer.add_child(hint)
	lab_button=Button.new()
	lab_button.position=Vector2(620,88)
	lab_button.size=Vector2(130,28)
	lab_button.text="장비시험 [F6]"
	lab_button.add_theme_font_size_override("font_size",13)
	lab_button.focus_mode=Control.FOCUS_NONE
	lab_button.pressed.connect(toggle_equipment_lab)
	layer.add_child(lab_button)
	minimap = Control.new()
	minimap.position = Vector2(480,16)
	minimap.size = Vector2(255,58)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.draw.connect(draw_minimap)
	layer.add_child(minimap)

func draw_minimap() -> void:
	if run.is_empty():
		return
	var min_cell := Vector2(1000,1000)
	var max_cell := Vector2(-1000,-1000)
	for data in run["rooms"]:
		var cell := Vector2(data["grid"][0],data["grid"][1])
		min_cell = min_cell.min(cell)
		max_cell = max_cell.max(cell)
	var extent := max_cell-min_cell
	var spacing := minf(30,minf(240/maxf(1,extent.x),46/maxf(1,extent.y)))
	for data in run["rooms"]:
		var point := (Vector2(data["grid"][0],data["grid"][1])-min_cell)*spacing+Vector2(6,6)
		for next in data["links"]:
			var grid: Array = run["rooms"][next]["grid"]
			var other := (Vector2(grid[0],grid[1])-min_cell)*spacing+Vector2(6,6)
			minimap.draw_line(point,other,Color("627576"),2)
	for data in run["rooms"]:
		var point := (Vector2(data["grid"][0],data["grid"][1])-min_cell)*spacing+Vector2(2,2)
		var color := Color("c8d9b1") if data["id"]==current_id else Color("779a91") if data["visited"] else Color("354953")
		if bool(data.get("peaceful",false)) and data["id"]!=current_id: color=Color("d2ad72")
		minimap.draw_rect(Rect2(point,Vector2(8,8)),color)

func toggle_equipment_lab() -> void:
	combat.vfx_preview_paused=false
	combat.inventory.hide()
	combat.inventory_shade.hide()
	if is_instance_valid(merchant) and merchant.opened: merchant.toggle()
	combat.leave_room()
	if combat.equipment_lab:
		combat.equipment_lab=false
		lab_button.text="장비시험 [F6]"
		wallet=lab_snapshot["wallet"]
		run=lab_snapshot["run"]
		in_village=lab_snapshot["village"]
		floor_number=lab_snapshot["floor"]
		combat.equipment=lab_snapshot["equipment"]
		combat.health=lab_snapshot["health"]
		combat.heart_cd=lab_snapshot["heart_cd"]
		combat.data={}
		change_room(lab_snapshot["id"],-1)
		player.position=lab_snapshot["position"]
		combat.message("장비 시험 종료 · 원래 진행과 가방 복원")
		lab_snapshot.clear()
		return
	lab_snapshot={"wallet":wallet.duplicate(true),"run":run.duplicate(true),"village":in_village,"floor":floor_number,"equipment":combat.equipment.duplicate(true),"health":combat.health,"id":current_id,"position":player.position,"heart_cd":combat.heart_cd}
	combat.equipment_lab=true
	lab_button.text="탐색 복귀 [F6]"
	combat.data={}
	wallet={"souls":0,"bag":CombatDirector.DB.items()}
	in_village=false
	run={"seed":1103,"version":Generator.VERSION,"goal":0,"rooms":[{"id":0,"template":"sanctum","links":[],"grid":[0,0],"decor_seed":1103,"visited":true}]}
	change_room(0,-1)
	combat.equipment={"heart":"songaksi","main":"hair","off":"","head":"","legs":"","feet":"","a0":"","a1":"","a2":"","a3":""}
	combat.health=60
	lab_index=0
	reset_lab_targets()
	title.text="캐릭터·장비 시험장 · 전 장비 41종"
	for child in room.get_children():
		if child is Label: child.hide()
func cycle_lab(step: int) -> void:
	lab_index=posmod(lab_index+step,CombatDirector.DB.weapons().size())
	var item:Dictionary=CombatDirector.DB.get_item(CombatDirector.DB.weapons()[lab_index][0])
	combat.equipment["main"]="hair" if item["slot"]=="off" else item["id"]
	combat.equipment["off"]=item["id"] if item["slot"]=="off" else ""
	combat.attack_cd={"main":0.0,"off":0.0}
	combat.skill_cd={"main":0.0,"off":0.0}
	combat.arsenal.reset_room()
	combat.message(str(lab_index+1)+"/33 · "+str(item["name"])+" · "+str(item["effect"]))
func reset_lab_targets() -> void:
	combat.leave_room()
	combat.vfx_preview_paused=false
	combat.hit_pause=0
	combat.paused=false
	combat.attack_cd={"main":0.0,"off":0.0}
	combat.hurt_timer=0
	combat.previous_dash=false
	combat.data=run["rooms"][0]
	combat.data["cleared"]=false
	combat.pickups.clear()
	combat.health=60
	combat.heart_cd=0
	combat.skill_cd={"main":0.0,"off":0.0}
	combat.tooth_ammo=8
	combat.tooth_reload=0
	player.position=Vector2(650,704)
	player.velocity=Vector2.ZERO
	player.facing=1
	player.camera.reset_smoothing()
	player.controls_enabled=true
	for i in range(3):
		var enemy=combat.spawn_enemy(["warrior","adept","monk"][i],Vector2(790+i*100,704),i)
		enemy.training_dummy=true
		enemy.max_hp=120
		enemy.hp=120
	combat.message("표적 3기 · 각 HP120 · [ ]로 무기 전환 / Tab 전 장비 가방")
