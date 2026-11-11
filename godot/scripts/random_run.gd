extends Node2D
const Generator = preload("res://scripts/run_generator.gd")
const Catalog = preload("res://scripts/room_catalog.gd")
const RoomView = preload("res://scripts/room_view.gd")
const Merchant = preload("res://scripts/merchant.gd")
const MerchantStock = preload("res://scripts/merchant_stock.gd")
const CombatDirector = preload("res://scripts/combat_director.gd")
const Player = preload("res://scripts/player.gd")
const TravelProp = preload("res://scripts/travel_prop.gd")
const FloorMapView = preload("res://scripts/floor_map_view.gd")
const SummonEffect = preload("res://scripts/summon_effect.gd")
const SongaksiNPC = preload("res://scripts/songaksi_npc.gd")
const HeartNPC = preload("res://scripts/heart_npc.gd")
const HeartDB = preload("res://scripts/heart_db.gd")
const Progression = preload("res://scripts/progression.gd")
const ChapterFogOverlay = preload("res://scripts/chapter_fog_overlay.gd")
const MOUNTAIN_NAMES := {
	"gate":"안개 고개","courtyard":"부서진 전망대","well":"메아리 웅덩이","hall":"바람 동굴",
	"gallery":"절벽 잔도","forest":"검은 소나무숲","store":"산중 보급굴","shrine":"버려진 산신당",
	"moon_gate":"흰안개 능선","collapsed_house":"무너진 암자","servants_quarters":"버려진 화전터",
	"black_kitchen":"그을린 숯막","granary":"바위 창고","dry_pond":"마른 폭포터","bamboo_path":"귀울음 대숲",
	"rotten_bridge":"썩은 현수교","ritual_yard":"호랑이 제단","grave_yard":"호식총 묘역",
	"paper_corridor":"찢긴 금줄길","sanctum":"장산범의 소굴"
}
const GARRISON_NAMES := {
	"gate":"주둔지 외곽 목책","courtyard":"훈련장 안뜰","well":"봉인 우물","hall":"병사 막사",
	"gallery":"궁술 회랑","forest":"순찰 목책길","store":"퇴마단 보급막사","shrine":"봉인 제단",
	"moon_gate":"달빛 감시로","collapsed_house":"무너진 초소","servants_quarters":"하급병 막사",
	"black_kitchen":"취사 막사","granary":"화살 보관고","dry_pond":"마른 해자","bamboo_path":"금줄 통로",
	"rotten_bridge":"감시탑 연결로","ritual_yard":"봉인 훈련장","grave_yard":"귀신 감옥",
	"paper_corridor":"부적 회랑","sanctum":"지휘 막사"
}
@export var start_in_village := false
@export var combat_enabled := true
var combat: Node2D
var in_village := false
var floor_number := 1
var village_stock: Array = []
var wallet: Dictionary = {"souls":0,"bag":[]}
var merchant: Node2D
var songaksi_npc: Node2D
var songaksi_dialog: ConfirmationDialog
var heart_npcs: Dictionary = {}
var pending_heart := "songaksi"
var summon_in_progress := false
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
var lab_heart_index := 0
var lab_button: Button
var session_rng := RandomNumberGenerator.new()
var complete := false
var floor_exit_position := Vector2.ZERO
var portal_props: Dictionary = {}
var well_prop: Node2D
var well_position := Vector2.ZERO
var floor_map_panel: PanelContainer
var floor_map_view: Control
var floor_map_open := false
var traveling := false
var travel_phase := ""
var travel_timer := 0.0
var travel_destination := -1
var travel_start_position := Vector2.ZERO
var fog_layer: CanvasLayer

func bind_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action,event)

func _ready() -> void:
	var bindings: Dictionary = {"move_left":[KEY_A],"move_right":[KEY_D],"jump":[KEY_W,KEY_SPACE],"dash":[KEY_SHIFT],"restart":[KEY_R],"collision_view":[KEY_F1],"interact":[KEY_E],"new_run":[KEY_N],"inventory":[KEY_TAB,KEY_I],"heart_skill":[KEY_Q],"main_skill":[KEY_F],"off_skill":[KEY_G],"boss_test":[KEY_F8],"fx_freeze":[KEY_F9],"equipment_lab":[KEY_F6],"lab_next":[KEY_BRACKETRIGHT],"lab_previous":[KEY_BRACKETLEFT],"lab_heart_next":[KEY_PERIOD],"lab_heart_previous":[KEY_COMMA],"lab_ai":[KEY_Y],"lab_reset":[KEY_T],"lab_set":[KEY_P],"attack":[KEY_J],"attack_left":[KEY_LEFT],"attack_right":[KEY_RIGHT],"attack_up":[KEY_UP],"attack_down":[KEY_DOWN]}
	for action in bindings:
		bind_action(action,bindings[action])
	var mouse := InputEventMouseButton.new()
	mouse.button_index=MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack",mouse)
	build_hud()
	build_fog_overlay()
	build_songaksi_dialog()
	combat=CombatDirector.new()
	combat.world=self
	combat.enabled=combat_enabled
	add_child(combat)
	if combat_enabled: combat.seed_starter()
	session_rng.randomize()
	var initial_seed := fresh_seed()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="):
			initial_seed = int(argument.trim_prefix("--seed="))
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

func fresh_seed() -> int:
	# A new play session gets a new layout, while the displayed numeric seed can
	# still be supplied again to reproduce that exact floor graph.
	return session_rng.randi_range(1,2147483646)

func display_room_name(template: String) -> String:
	return chapter_title()

func chapter_title() -> String:
	if in_village: return "흉가 마을"
	if floor_number>=3: return "3챕터 · 퇴마단 주둔지"
	if floor_number==2: return "2챕터 · 안개 낀 산"
	return "1챕터 · 흉가"

func build_fog_overlay() -> void:
	fog_layer=CanvasLayer.new()
	fog_layer.layer=5
	add_child(fog_layer)
	var overlay:=ChapterFogOverlay.new()
	fog_layer.add_child(overlay)
	fog_layer.hide()

func update_chapter_overlay() -> void:
	if is_instance_valid(fog_layer):
		fog_layer.visible=not in_village and floor_number==2

func show_village() -> void:
	in_village = true
	complete = false
	run = {"version":Generator.VERSION,"seed":1103,"start":0,"goal":-1,"rooms":[{"id":0,"template":"courtyard","links":[],"grid":[0,0],"decor_seed":1103,"visited":false,"peaceful":true}]}
	change_room(0,-1)
	call_deferred("spawn_songaksi_npc")
	call_deferred("enter_heartless_form",true)

func spawn_songaksi_npc() -> void:
	if not in_village or not is_instance_valid(room): return
	heart_npcs.clear()
	songaksi_npc=SongaksiNPC.new()
	songaksi_npc.position=Vector2(700,704)
	var label:=Label.new()
	label.text="손각시"
	label.position=Vector2(-42,-82)
	label.add_theme_font_size_override("font_size",14)
	songaksi_npc.add_child(label)
	room.add_child(songaksi_npc)
	heart_npcs["songaksi"]=songaksi_npc
	var profile:=Progression.load_profile()
	var positions:={"mongdal":Vector2(940,704),"changgui":Vector2(1180,704)}
	for heart_id in ["mongdal","changgui"]:
		var data:=HeartDB.get_heart(heart_id)
		var npc:=HeartNPC.new()
		npc.heart_id=heart_id
		npc.display_name=data["name"]
		npc.art_path=data["npc_art"]
		npc.unlocked=HeartDB.unlocked(heart_id,profile)
		npc.position=positions[heart_id]
		var npc_label:=Label.new()
		npc_label.text=str(data["name"])+("" if npc.unlocked else "\n잠김")
		npc_label.position=Vector2(-64,-92)
		npc_label.add_theme_font_size_override("font_size",14)
		npc.add_child(npc_label)
		room.add_child(npc)
		heart_npcs[heart_id]=npc

func build_songaksi_dialog() -> void:
	var layer:=CanvasLayer.new()
	layer.layer=30
	add_child(layer)
	songaksi_dialog=ConfirmationDialog.new()
	songaksi_dialog.title="손각시의 제안"
	songaksi_dialog.dialog_text="내 심장을 가져갈래?"
	songaksi_dialog.ok_button_text="예"
	songaksi_dialog.cancel_button_text="아니오"
	songaksi_dialog.confirmed.connect(accept_songaksi_heart)
	songaksi_dialog.canceled.connect(func():
		if is_instance_valid(player): player.controls_enabled=true)
	layer.add_child(songaksi_dialog)

func open_songaksi_dialog() -> void:
	open_heart_dialog("songaksi")

func open_heart_dialog(heart_id: String) -> void:
	if summon_in_progress or combat.equipment.get("heart","")!="": return
	var data:Dictionary=HeartDB.get_heart(heart_id)
	if data.is_empty(): return
	if not HeartDB.unlocked(heart_id,Progression.load_profile()):
		combat.message(str(data["name"])+"의 심장은 아직 잠겨 있습니다")
		return
	pending_heart=heart_id
	songaksi_dialog.title=str(data["name"])+"의 제안"
	var identity:String="대시 3회" if heart_id=="mongdal" else "Q "+str(data["skill_name"])
	songaksi_dialog.dialog_text="내 심장을 가져갈래?\nHP "+str(int(data["hp"]))+" · "+identity
	player.controls_enabled=false
	songaksi_dialog.popup_centered(Vector2i(420,180))

func play_player_summon(on_finished: Callable) -> void:
	if not is_instance_valid(player): return
	summon_in_progress=true
	player.controls_enabled=false
	player.visual.hide()
	var summon := SummonEffect.new()
	# Player.position is the collision body's foot point, so the summoning ring
	# stays planted on the floor instead of hovering around the torso.
	summon.position=player.position
	summon.finished.connect(func():
		if is_instance_valid(player):
			on_finished.call()
			player.visual.show()
			player.controls_enabled=true
		summon_in_progress=false)
	add_child(summon)

func enter_heartless_form(with_summon := false) -> void:
	var old_heart:=str(combat.equipment.get("heart",""))
	combat.equipment["heart"]=""
	var old_data:=HeartDB.get_heart(old_heart)
	if not old_data.is_empty() and combat.equipment.get("main","")==old_data.get("starter",""):
		combat.equipment["main"]=""
	combat.max_health=1
	combat.health=1
	if is_instance_valid(player):
		player.set_heart_role("songaksi",1)
		player.visual.modulate=Color("11121a")
	if with_summon: play_player_summon(func(): player.visual.modulate=Color("11121a"))

func accept_songaksi_heart() -> void:
	accept_heart(pending_heart)

func accept_heart(heart_id: String) -> void:
	if not is_instance_valid(player): return
	var data:=HeartDB.get_heart(heart_id)
	if data.is_empty(): return
	play_player_summon(func():
		combat.equipment["heart"]=heart_id
		var bag:Array=wallet["bag"]
		for i in range(bag.size()-1,-1,-1):
			if str(bag[i].get("id",""))==str(data["starter"]): bag.remove_at(i)
		if combat.equipment["main"]!="" and combat.equipment["main"]!=data["starter"]: bag.append(combat.equipped("main"))
		combat.equipment["main"]=data["starter"]
		player.set_heart_role(data["role"],int(data.get("dash_charges",1)))
		player.visual.modulate=Color.WHITE
		combat.max_health=float(data["hp"])
		combat.health=combat.max_health
		combat.heart_cd=0
		combat.message(str(data["name"])+"의 심장을 빌렸습니다 · "+str(CombatDirector.DB.get_item(data["starter"]).get("name","기본 무기"))+" 획득"))

func has_heart() -> bool:
	return str(combat.equipment.get("heart",""))!=""

func play_village_summon() -> void:
	play_player_summon(func(): player.visual.modulate=Color("11121a"))

func add_village_exit_sign() -> void:
	var sign := Label.new()
	sign.position = Vector2(1570,578)
	sign.text = "1층 입구"
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
			x = gap[0]-120
	return Vector2(x,704)

func change_room(id: int, previous: int) -> void:
	var previous_dash_charges:=-1
	var previous_dash_recharge:=0.0
	if is_instance_valid(player):
		previous_dash_charges=player.dash_charges
		previous_dash_recharge=player.dash_recharge_timer
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
	room.chapter=clampi(floor_number,1,3) if not in_village else 1
	room.z_index=-20
	add_child(room)
	room.build(def,data["decor_seed"])
	portal_links = data["links"].duplicate()
	portal_props.clear()
	for next in portal_links:
		var door: Vector2 = portal_position(id,next)
		room.door_positions.append(door)
		var is_boss_door: bool = next == run["goal"]
		if is_boss_door:
			room.boss_door_positions.append(door)
		else:
			var portal := TravelProp.new()
			portal.position = door
			portal.play("shadow-portal")
			room.add_child(portal)
			portal_props[next] = portal
		var label := Label.new()
		label.position = door + Vector2(-62,-118)
		label.text = "보스문" if is_boss_door else "그림자 포탈"
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
	var heart_id:=str(combat.equipment.get("heart","")) if is_instance_valid(combat) else ""
	var heart:=HeartDB.get_heart(heart_id)
	if not heart.is_empty():
		player.set_heart_role(str(heart["role"]),int(heart.get("dash_charges",1)))
		if previous_dash_charges>=0:
			player.dash_charges=mini(player.dash_max_charges,previous_dash_charges)
			player.dash_recharge_timer=previous_dash_recharge
	player.camera.limit_right = def["width"]
	player.camera.limit_bottom = 864
	player.camera.reset_smoothing()
	if not in_village and id != run["goal"]:
		well_position = safe_floor_position(def, float(def["width"]) * .5)
		well_prop = TravelProp.new()
		well_prop.position = well_position
		well_prop.play("well")
		room.add_child(well_prop)
	else:
		well_prop = null
	cooldown = .3
	if not is_combat_room():
		merchant = Merchant.new()
		merchant.z_index=-1
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
			combat.health=combat.max_health
			combat.message("평화구역 · 도깨비의 쉼터에서 HP 회복")
	if id == run["goal"]:
		var exit_label := Label.new()
		floor_exit_position=Vector2(float(def["width"])*.5,704)
		exit_label.position = floor_exit_position+Vector2(-65,-96)
		exit_label.text = "구간 출구"
		exit_label.add_theme_font_size_override("font_size",14)
		room.add_child(exit_label)
	title.text = chapter_title()
	update_chapter_overlay()
	minimap.visible=not in_village
	minimap.queue_redraw()
	if is_instance_valid(combat): combat.enter_room(data)
	if in_village: call_deferred("add_village_exit_sign")

func safe_floor_position(def: Dictionary, preferred: float) -> Vector2:
	var x := clampf(preferred, 150.0, float(def["width"]) - 150.0)
	for gap in def["gaps"]:
		if x > gap[0] - 80 and x < gap[0] + gap[1] + 80:
			x = clampf(gap[0] - 110, 150.0, float(def["width"]) - 150.0)
	return Vector2(x, 704)

func open_floor_map() -> void:
	floor_map_open = true
	floor_map_view.rebuild()
	floor_map_panel.show()

func close_floor_map() -> void:
	floor_map_open = false
	floor_map_panel.hide()

func begin_well_travel(destination: int) -> void:
	close_floor_map()
	traveling = true
	travel_phase = "well_enter"
	travel_timer = 0.0
	travel_destination = destination
	travel_start_position = player.position
	player.controls_enabled = false
	well_prop.play("well-enter", 1.8)

func begin_portal_travel(destination: int) -> void:
	traveling = true
	travel_phase = "portal_enter"
	travel_timer = 0.0
	travel_destination = destination
	player.controls_enabled = false
	if portal_props.has(destination): portal_props[destination].play("portal-enter", 2.5)

func tick_travel(delta: float) -> void:
	travel_timer += delta
	if travel_phase == "portal_enter" and travel_timer >= .48:
		var destination := travel_destination
		change_room(destination, current_id)
		traveling = false
		travel_phase = ""
		player.controls_enabled = true
	elif travel_phase == "well_enter":
		var enter_progress := minf(1.0, travel_timer / .62)
		player.position.x = lerpf(travel_start_position.x, well_position.x, minf(1.0, enter_progress * 2.2))
		player.position.y = lerpf(travel_start_position.y, well_position.y + 58, enter_progress * enter_progress) - sin(enter_progress * PI) * 20
		player.visual.modulate.a = 1.0 - clampf((enter_progress - .56) / .36, 0.0, 1.0)
		if travel_timer < .62: return
		player.visual.hide()
		var destination := travel_destination
		change_room(destination, -1)
		player.position = well_position + Vector2(0, 54)
		player.spawn = well_position
		player.visual.show()
		player.visual.modulate.a = 0.0
		well_prop.play("well-exit", 2.0)
		travel_phase = "well_exit"
		travel_timer = 0.0
	elif travel_phase == "well_exit":
		var exit_progress := minf(1.0, travel_timer / .72)
		player.visual.modulate.a = clampf(exit_progress * 4.0, 0.0, 1.0)
		player.position.x = well_position.x
		player.position.y = lerpf(well_position.y + 54, well_position.y, exit_progress) - sin(exit_progress * PI) * 34
		if travel_timer >= .72:
			player.position = well_position
			player.visual.modulate = Color.WHITE
			well_prop.play("well")
			traveling = false
			travel_phase = ""
			player.controls_enabled = true

func _process(delta: float) -> void:
	web_status_timer-=delta
	if web_status_timer<=0:
		update_web_status()
		web_status_timer=.2
	if not is_instance_valid(player):
		return
	if traveling:
		player.controls_enabled = false
		tick_travel(delta)
		return
	if summon_in_progress:
		player.controls_enabled=false
		return
	if is_instance_valid(songaksi_dialog) and songaksi_dialog.visible:
		player.controls_enabled=false
		return
	if floor_map_open:
		player.controls_enabled = false
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_cancel"): close_floor_map()
		return
	if Input.is_action_just_pressed("equipment_lab"):
		toggle_equipment_lab()
		return
	if combat.equipment_lab:
		if Input.is_action_just_pressed("fx_freeze"): combat.vfx_preview_paused=not combat.vfx_preview_paused
		if not combat.inventory.visible:
			if Input.is_action_just_pressed("lab_next"): cycle_lab(1)
			if Input.is_action_just_pressed("lab_previous"): cycle_lab(-1)
			if Input.is_action_just_pressed("lab_heart_next"): cycle_lab_heart(1)
			if Input.is_action_just_pressed("lab_heart_previous"): cycle_lab_heart(-1)
			if Input.is_action_just_pressed("lab_reset"): reset_lab_targets()
			if Input.is_action_just_pressed("lab_ai"):
				for enemy in combat.living(): enemy.training_dummy=not enemy.training_dummy
				combat.message("Y · 적 행동 전환 / 시험장에서는 피격 피해 없음")
			if Input.is_action_just_pressed("lab_set"):
				combat.equipment.merge({"main":"fist","off":"","head":"duo_head","a0":"duo_curse"},true)
				combat.skill_cd={"main":0.0,"off":0.0}
				combat.message("두억시니 3종 장착 · G 짓누르기 / Shift 대시 공격")
		hint.text="통합 시험장 · [ ] 전 장비 · , . 캐릭터 · Tab 장비목록 · T 표적 · Y AI · F6 복귀"
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
		hint.text = "E · 도깨비상인"
		if Input.is_action_just_pressed("interact"): merchant.toggle()
		return
	if combat_enabled and Input.is_action_just_pressed("boss_test"):
		new_run(1103)
		change_room(run["goal"],-1)
		combat.health=combat.max_health
		combat.hurt_timer=1.0
		return
	if in_village:
		for heart_id in heart_npcs:
			var npc:Node2D=heart_npcs[heart_id]
			if is_instance_valid(npc) and player.position.distance_to(npc.global_position)<90:
				var data:=HeartDB.get_heart(heart_id)
				var unlocked:=HeartDB.unlocked(heart_id,Progression.load_profile())
				hint.text="E · "+str(data["name"])+("의 심장 빌리기" if unlocked else " · 잠김")
				if Input.is_action_just_pressed("interact"): open_heart_dialog(heart_id)
				return
		if player.position.x>1570:
			hint.text = "E · 1층으로 출발" if has_heart() else "심장이 없어 출발할 수 없습니다 · 귀신에게 심장을 빌리세요"
			if Input.is_action_just_pressed("interact"):
				if has_heart():
					floor_number=1
					new_run(fresh_seed())
				else: combat.message("심장이 없이는 흉가에 들어갈 수 없습니다")
		else: hint.text = ""
		return
	if Input.is_action_just_pressed("new_run"):
		new_run(int(run["seed"])+1)
		return
	if Input.is_action_just_pressed("collision_view"):
		room.debug_visible = not room.debug_visible
		room.queue_redraw()
	if combat_enabled and combat.locked():
		hint.text=""
		return
	if is_instance_valid(well_prop) and player.position.distance_to(well_position) < 76:
		hint.text = "E · 우물 상세지도"
		if Input.is_action_just_pressed("interact"): open_floor_map()
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
		var destination_id:int=portal_links[nearby]
		hint.text = "E · 보스방 이동" if destination_id==run["goal"] else "E · 다음 방 이동"
		if cooldown<=0 and Input.is_action_just_pressed("interact"):
			var destination: int = portal_links[nearby]
			if destination == run["goal"]: change_room(destination,current_id)
			else: begin_portal_travel(destination)
		return
	if current_id==run["goal"] and player.position.distance_to(floor_exit_position)<84:
		hint.text="E · 다음 층으로 출발" if complete else "E · 구간 탐색 완료"
		if Input.is_action_just_pressed("interact"):
			if complete:
				floor_number+=1
				new_run(int(run["seed"])+1009)
			else: complete=true
		return
	hint.text="E · 상자 열기" if combat_enabled and combat.near_chest() else ""

func update_web_status() -> void:
	if not OS.has_feature("web") or not is_instance_valid(player) or not is_instance_valid(combat): return
	var text:=chapter_title()
	text+=" | HP "+str(int(combat.health))+"/"+str(int(combat.max_health))+" | 영혼조각 "+str(wallet["souls"])+" | 남은 적 "+str(combat.living().size())
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
	combat.heart_cd=0
	combat.hurt_timer=1
	show_village()
	combat.message("빌린 모습이 깨졌습니다 · 마을로 귀환")

func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer=10
	add_child(layer)
	title = Label.new()
	title.position = Vector2(282,58)
	title.size=Vector2(204,22)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.clip_text=true
	title.add_theme_font_size_override("font_size",13)
	layer.add_child(title)
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
	lab_button.position=Vector2(620,74)
	lab_button.size=Vector2(130,28)
	lab_button.text="장비시험 [F6]"
	lab_button.add_theme_font_size_override("font_size",13)
	lab_button.focus_mode=Control.FOCUS_NONE
	lab_button.pressed.connect(toggle_equipment_lab)
	layer.add_child(lab_button)
	lab_button.hide()
	minimap = Control.new()
	minimap.position = Vector2(284,82)
	minimap.size = Vector2(200,50)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.draw.connect(draw_minimap)
	layer.add_child(minimap)
	floor_map_panel = PanelContainer.new()
	floor_map_panel.position = Vector2(104, 38)
	floor_map_panel.size = Vector2(560, 350)
	var map_style := StyleBoxFlat.new()
	map_style.bg_color = Color("101923")
	map_style.border_color = Color("9d8663")
	map_style.set_border_width_all(3)
	map_style.set_content_margin_all(18)
	floor_map_panel.add_theme_stylebox_override("panel", map_style)
	layer.add_child(floor_map_panel)
	floor_map_view = FloorMapView.new()
	floor_map_view.custom_minimum_size = Vector2(554,344)
	floor_map_panel.add_child(floor_map_view)
	floor_map_view.setup(self)
	floor_map_panel.hide()

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
		combat.max_health=lab_snapshot["max_health"]
		combat.health=lab_snapshot["health"]
		combat.heart_cd=lab_snapshot["heart_cd"]
		combat.data={}
		change_room(lab_snapshot["id"],-1)
		player.position=lab_snapshot["position"]
		combat.message("장비 시험 종료 · 원래 진행과 가방 복원")
		lab_snapshot.clear()
		return
	lab_snapshot={"wallet":wallet.duplicate(true),"run":run.duplicate(true),"village":in_village,"floor":floor_number,"equipment":combat.equipment.duplicate(true),"max_health":combat.max_health,"health":combat.health,"id":current_id,"position":player.position,"heart_cd":combat.heart_cd}
	combat.equipment_lab=true
	lab_button.text="탐색 복귀 [F6]"
	combat.data={}
	wallet={"souls":0,"bag":CombatDirector.DB.items()}
	in_village=false
	run={"seed":1103,"version":Generator.VERSION,"goal":0,"rooms":[{"id":0,"template":"sanctum","links":[],"grid":[0,0],"decor_seed":1103,"visited":true}]}
	change_room(0,-1)
	combat.equipment={"heart":"songaksi","main":"songaksi_hand","off":"","head":"","legs":"","feet":"","a0":"","a1":"","a2":"","a3":""}
	combat.max_health=60
	combat.health=60
	lab_index=0
	reset_lab_targets()
	title.text="통합 시험장 · 캐릭터 "+str(HeartDB.HEARTS.size())+"종 · 장비 "+str(CombatDirector.DB.items().size())+"종"
	for child in room.get_children():
		if child is Label: child.hide()
func cycle_lab(step: int) -> void:
	var catalog:=CombatDirector.DB.items()
	lab_index=posmod(lab_index+step,catalog.size())
	var item:Dictionary=catalog[lab_index]
	var slot:String=str(item["slot"])
	if slot=="two":
		combat.equipment["main"]=item["id"]
		combat.equipment["off"]=""
	elif slot=="main":
		combat.equipment["main"]=item["id"]
	elif slot=="off":
		combat.equipment["off"]=item["id"]
	elif slot=="accessory":
		combat.equipment["a0"]=item["id"]
	else:
		combat.equipment[slot]=item["id"]
	combat.attack_cd={"main":0.0,"off":0.0}
	combat.skill_cd={"main":0.0,"off":0.0}
	combat.arsenal.reset_room()
	combat.message(str(lab_index+1)+"/"+str(catalog.size())+" · "+CombatDirector.DB.slot_name(slot)+" · "+str(item["name"])+" · "+str(item["effect"]))

func set_lab_heart(heart_id: String) -> void:
	var data:=HeartDB.get_heart(heart_id)
	if data.is_empty() or not is_instance_valid(player): return
	combat.equipment["heart"]=heart_id
	player.set_heart_role(str(data["role"]),int(data.get("dash_charges",1)))
	player.visual.modulate=Color.WHITE
	combat.max_health=float(data["hp"])
	combat.health=combat.max_health
	combat.heart_cd=0
	combat.skill_cd={"main":0.0,"off":0.0}
	combat.message("캐릭터 · "+str(data["name"])+" · HP "+str(int(data["hp"]))+" · "+("고유 스킬 없음" if str(data.get("skill_name",""))=="" else "Q "+str(data["skill_name"])))

func cycle_lab_heart(step: int) -> void:
	var hearts:Array=HeartDB.HEARTS.keys()
	hearts.sort()
	lab_heart_index=posmod(lab_heart_index+step,hearts.size())
	set_lab_heart(str(hearts[lab_heart_index]))
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
	combat.health=combat.max_health
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
