extends Node2D
const DB = preload("res://scripts/equipment_db.gd")
const Progression = preload("res://scripts/progression.gd")
const PixelVFX = preload("res://scripts/pixel_vfx.gd")
const InventoryPaperDoll = preload("res://scripts/inventory_paper_doll.gd")
const InventorySelectFX = preload("res://scripts/inventory_select_fx.gd")
const InventoryHeartIcon = preload("res://scripts/inventory_heart_icon.gd")
const InventoryAccessoryRail = preload("res://scripts/inventory_accessory_rail.gd")
const InventoryModularSkin = preload("res://scripts/inventory_modular_skin.gd")
const InventoryFont = preload("res://assets/fonts/NotoSansKR-Semibold.ttf")
const HeartDB = preload("res://scripts/heart_db.gd")
const GameHUD = preload("res://scripts/game_hud.gd")
const InventoryLayout = preload("res://scripts/inventory_layout.gd")
const REWARD_CHEST_TEXTURE = preload("res://assets/vfx/pickups/reward-chest.png")
var vfx: Node2D
const Arsenal = preload("res://scripts/equipment_runtime.gd")
var arsenal = Arsenal.new()
var equipment_lab := false
var vfx_preview_paused := false
const Enemy = preload("res://scripts/combat_enemy.gd")
var world: Node2D
var enabled := true
var paused := false
var health := 60.0
var max_health := 60.0
var hurt_timer := 0.0
var heart_cd := 0.0
var skill_cd := {"main":0.0,"off":0.0}
var attack_cd := {"main":0.0,"off":0.0}
var equipment: Dictionary = {"heart":"","main":"","off":"","head":"","legs":"","feet":"","internal":"","a0":"","a1":"","a2":"","a3":""}
var enemies: Array = []
var projectiles: Array = []
var pickups: Array = []
var zones: Array = []
var effects: Array = []
var data: Dictionary
var rng := RandomNumberGenerator.new()
var previous_dash := false
var previous_floor := true
var attack_count := 0
var frenzy := 0.0
var regen_cd := 0.0
var heart_animation := 0.0
var ui: CanvasLayer
var hud: Label
var game_hud: Control
var inventory: Control
var inv_rows: Control
var confirm: ConfirmationDialog
var pending_destroy := -1
var inventory_selection := 0
var inventory_shade: ColorRect
var inventory_fx: Control
var skill_bar: Label
var toast: Label
var toast_time := 0.0
var boss_test := false
var heart_pending: Array = []
var heart_windup := 0.0
var tooth_ammo := 8
var tooth_reload := 0.0
var hit_pause := 0.0
var boss_transitioning := false
var attack_serial := 0
var visual_clock := 0.0
var drop_textures := {}
var drop_info := {}
var reward_chest_info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/vfx/pickups/reward-chest.json"))["meta"]["pixelfx"]
const PROVIDED_DROPS = {"hair":"hair","pin":"hairpin","water_bucket":"gourd","fox_bead":"foxbead","claws":"claw","goblin_fire":"ghostfire","plague":"jar","fist":"fist"}
const GEAR2_DROPS = {"songaksi_hand":"songakHand","ribbon":"ribbon","mirror":"jokduri","eggshell":"eggshell","blank_face":"blankface","gaze":"hollowgaze","wig":"wig","duo_head":"mask","bent_leg":"brokenLeg","mongdal_legs":"leg","wet_shoes":"shoe","single_shoe":"oneShoe","stomach":"stomach","duo_curse":"curse"}
func _ready() -> void:
	arsenal.c=self
	vfx=PixelVFX.new()
	vfx.combat=self
	add_child(vfx)
	ui=CanvasLayer.new()
	ui.layer=10
	add_child(ui)
	game_hud=GameHUD.new()
	game_hud.inventory_requested.connect(toggle_inventory)
	ui.add_child(game_hud)
	hud=Label.new()
	hud.position=Vector2(282,8)
	hud.size=Vector2(204,54)
	hud.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hud.add_theme_font_size_override("font_size",14)
	ui.add_child(hud)
	skill_bar=Label.new()
	skill_bar.position=Vector2(18,368)
	skill_bar.add_theme_font_size_override("font_size",15)
	ui.add_child(skill_bar)
	toast=Label.new()
	toast.position=Vector2(18,338)
	toast.size.x=730
	toast.clip_text=true
	toast.add_theme_font_size_override("font_size",13)
	ui.add_child(toast)
	inventory_shade=ColorRect.new()
	inventory_shade.color=Color(0.02,.035,.05,.78)
	inventory_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(inventory_shade)
	inventory_shade.hide()
	inventory=Control.new()
	inventory.position=Vector2.ZERO
	inventory.size=Vector2(768,432)
	ui.add_child(inventory)
	var inventory_frame:=InventoryModularSkin.new()
	inventory_frame.size=Vector2(768,432)
	inventory.add_child(inventory_frame)
	inv_rows=Control.new()
	inv_rows.size=Vector2(768,432)
	inventory.add_child(inv_rows)
	inventory.hide()
	inventory_fx=InventorySelectFX.new()
	inventory_fx.z_index=40
	ui.add_child(inventory_fx)
	confirm=ConfirmationDialog.new()
	confirm.title="아이템 영구 파기"
	confirm.ok_button_text="파기"
	confirm.cancel_button_text="취소"
	confirm.confirmed.connect(destroy_confirmed)
	ui.add_child(confirm)
func seed_starter() -> void:
	if not world.wallet.has("starter_given"):
		# A small explicit starter kit, not a grant of currency or high-tier loot.
		for id in ["eggshell","water_hand","wig","bent_leg","wet_shoes"]:
			world.wallet["bag"].append(DB.get_item(id))
		world.wallet["starter_given"]=true
func message(text: String) -> void:
	toast.text=text
	toast_time=3
func leave_room() -> void:
	boss_transitioning=false
	arsenal.reset_room()
	if is_instance_valid(vfx): vfx.clear()
	if not data.is_empty(): data["pickups"]=pickups.duplicate(true)
	for enemy in enemies:
		if is_instance_valid(enemy):
			remove_child(enemy)
			enemy.queue_free()
	enemies.clear()
	heart_pending.clear()
	heart_windup=0
	projectiles.clear()
	zones.clear()
	effects.clear()
func enter_room(room_data: Dictionary) -> void:
	leave_room()
	data=room_data
	pickups=data.get("pickups",[]).duplicate(true)
	rng.seed=int(world.run["seed"]) ^ (world.current_id*65537+0x424154)
	if not enabled or not world.is_combat_room(): return
	if data.get("cleared",false): return
	var width:=float(world.room.definition["width"])
	if world.current_id==world.run["goal"]:
		if world.floor_number>=3:
			spawn_enemy("exorcist-spearman",safe_ground(width*.34),0)
			spawn_enemy("exorcist-archer",safe_ground(width*.67),1)
			spawn_enemy("bell-exorcist",safe_ground(width*.52),2)
			spawn_enemy("hunting-hawk",safe_ground(width*.76),3)
			message("지휘 막사 정예전 · 진형을 무너뜨리면 출구가 열립니다")
		else:
			var boss_kind:="jangsanbeom" if world.floor_number==2 else "boss"
			spawn_enemy(boss_kind,safe_ground(width*.45),0)
			message(("장산범" if boss_kind=="jangsanbeom" else "퇴마단 선봉대장")+" · 적을 처치하면 문이 열립니다")
	else:
		var candidates: Array = []
		for x in range(352,int(width)-180,64):
			var pos:=safe_ground(x)
			var safe:=pos.distance_to(world.player.position)>220
			for door in world.room.door_positions:
				if pos.distance_to(door)<180: safe=false
			if safe: candidates.append(pos)
		for i in range(mini(3,candidates.size())):
			var index:=rng.randi_range(0,candidates.size()-1)
			var pos: Vector2 = candidates.pop_at(index)
			if world.floor_number>=3:
				var garrison_kinds:=["exorcist-spearman","exorcist-archer","bell-exorcist","hunting-hawk"]
				var garrison_kind:String=garrison_kinds[(world.current_id+i)%garrison_kinds.size()]
				# Two archers plus a hawk creates excessive off-axis pressure.
				if garrison_kind=="hunting-hawk" and i>1: garrison_kind="exorcist-spearman"
				spawn_enemy(garrison_kind,pos,i)
			elif world.floor_number==2:
				var mountain_kinds:=["changgui-remnant","mihokbul","hosikchong-wraith","mountain-tiger"]
				var mountain_kind:String="jangsan-shadow" if i==0 and world.current_id>0 and world.current_id%4==0 else mountain_kinds[(world.current_id+i)%mountain_kinds.size()]
				spawn_enemy(mountain_kind,pos,i)
			else:
				spawn_enemy((["warrior","warrior","adept"] if world.current_id==world.run.get("start",0) else ["warrior","adept","monk"])[i],pos,i)
func spawn_enemy(kind: String, pos: Vector2, uid: int) -> Node:
	var enemy=Enemy.new()
	enemy.kind=kind
	enemy.hp=-1
	enemy.position=pos+Vector2(0,-145) if kind=="hunting-hawk" else pos
	enemy.uid=uid
	enemy.director=self
	add_child(enemy)
	enemies.append(enemy)
	return enemy
func safe_ground(x: float) -> Vector2:
	var width:=float(world.room.definition["width"])
	x=clampf(x,64,width-64)
	for gap in world.room.definition["gaps"]:
		if x>gap[0]-24 and x<gap[0]+gap[1]+24: x=gap[0]+gap[1]+40
	return Vector2(x,704)

func reward_drop_position() -> Vector2:
	var width:=float(world.room.definition["width"])
	for offset in [0.0,-150.0,150.0,-300.0,300.0,-450.0,450.0]:
		var candidate:=safe_ground(width*.5+offset)+Vector2(0,-18)
		var blocked:=false
		if is_instance_valid(world.well_prop) and candidate.distance_to(world.well_position+Vector2(0,-18))<125:
			blocked=true
		for door in world.room.door_positions:
			if candidate.distance_to(Vector2(door)+Vector2(0,-18))<110: blocked=true
		if not blocked: return candidate
	return safe_ground(width*.25)+Vector2(0,-18)
func living() -> Array:
	return enemies.filter(func(enemy):return is_instance_valid(enemy) and not enemy.dead)
func locked() -> bool: return enabled and not living().is_empty()
func enemy_location_hint() -> String:
	var enemy=nearest_enemy(world.player.position,10000)
	if enemy==null: return "클리어"
	var difference: Vector2=enemy.position-world.player.position
	return ("← 왼쪽" if difference.x<0 else "오른쪽 →")+(" · 위층" if difference.y < -80 else "")
func visible_rect() -> Rect2:
	return Rect2(world.player.camera.get_screen_center_position()-Vector2(384,216),Vector2(768,432))
func attack_permission(requester: Node) -> bool:
	if requester.boss: return true
	var count:=0
	for enemy in living():
		if enemy!=requester and enemy.state=="windup" and (enemy.kind=="adept")== (requester.kind=="adept"): count+=1
	return count<(1 if requester.kind=="adept" else 2)

func queue_enemy_strike(kind: String,pos: Vector2,delay: float,damage: float,source: Node) -> void:
	zones.append({"kind":kind,"pos":safe_ground(pos.x),"life":delay+(2.2 if kind=="enemy-seal" else .2),"delay":delay,"tick":0.0,"damage":damage,"source":source,"triggered":false,"hurt_cd":0.0})
func enemy_target(enemy: Node) -> Vector2:
	if enemy.confusion>0:
		for other in living():
			if other!=enemy: return other.global_position+Vector2(0,-23)
	for zone in zones:
		if zone["kind"]=="decoy": return zone["pos"]+Vector2(0,-23)
	return world.player.global_position+Vector2(0,-23)
func area_effect(origin: Vector2,radius: float,damage: float,source: Node=null) -> void:
	effects.append({"pos":origin,"radius":radius,"time":.2,"color":Color("c9e1cc") if source==null else Color("db9a73")})
	if source==null:
		for enemy in living():
			if (enemy.global_position+Vector2(0,-25*enemy.size_factor)).distance_to(origin)<radius+15:
				enemy.take_damage(damage)
				if equipped("main").get("id","")=="fist": hit_pause=maxf(hit_pause,.06)
	elif source.confusion>0:
		for enemy in living():
			if enemy!=source and enemy.position.distance_to(origin)<radius+15: enemy.take_damage(damage)
	else:
		for zone in zones:
			if zone["kind"]=="decoy" and Vector2(zone["pos"]).distance_to(origin)<radius+24:
				zone["hp"]=float(zone.get("hp",18))-damage
				if zone["hp"]<=0: zone["life"]=0
				return
		if (world.player.position+Vector2(0,-23)).distance_to(origin)<radius+12: hurt(damage)
func hurt(amount: float) -> void:
	if equipment_lab or hurt_timer>0 or world.player.dash_time>0 or not enabled or data.get("cleared",false) or not world.is_combat_room(): return
	health=maxf(0,health-amount)
	hurt_timer=.65
	if health<=0:
		world.call_deferred("combat_death")
func enemy_killed(enemy: Node) -> void:
	arsenal.killed(enemy)
	frenzy=3
	if enemy.kind=="jangsanbeom":
		# The Chapter 2 reward pool starts with the finished legendary paw. Keeping
		# it as an array makes later Jangsan set pieces a drop-in addition.
		var jangsan_rewards := ["jangsan_paw"]
		var reward: Dictionary = DB.get_item(jangsan_rewards[rng.randi_range(0,jangsan_rewards.size()-1)])
		world.wallet["bag"].append(reward)
		var newly_unlocked := Progression.unlock_changgui_and_jangsan()
		message("장산범 처치 · "+str(reward["name"])+" 획득"+(" · 장산범 장비·창귀 심장 해금" if newly_unlocked else ""))
	elif enemy.boss:
		message("퇴마단 선봉대장 처치 · 안개 낀 산으로 향하는 길이 열렸습니다")
	if has_passive("heal") and regen_cd<=0:
		health=minf(max_health,health+3)
		regen_cd=.6
	if enemy.boss or rng.randf()<.6:
		pickups.append({"kind":"souls","amount":30 if enemy.boss else rng.randi_range(1,3),"pos":safe_ground(enemy.position.x)+Vector2(0,-18)})
	if equipped("main").get("id","")=="club" and rng.randf()<.3:
		pickups.append({"kind":"souls","amount":1,"pos":safe_ground(enemy.position.x)+Vector2(0,-18)})
	if living().is_empty() and not data.get("cleared",false):
		data["cleared"]=true
		for projectile in projectiles:
			if not projectile["friendly"]: projectile["life"]=0
		var stock=preload("res://scripts/merchant_stock.gd").roll(int(world.run["seed"])^(world.current_id*131+0x4c4f4f54),world.floor_number)
		var item: Dictionary = stock[0].duplicate(true)
		item.erase("sold")
		pickups.append({"kind":"chest" if rng.randf()<.6 else "item","item":item,"pos":reward_drop_position()})
		message("방 클리어 · 안전한 위치에 보상이 나타났습니다")
func equipped(slot: String) -> Dictionary: return DB.get_item(str(equipment.get(slot,"")))
func has_passive(passive: String) -> bool:
	for slot in equipment:
		if equipped(slot).get("passive","")==passive: return true
	return false
func duo_set() -> bool:
	var count:=0
	for slot in equipment:
		if equipped(slot).get("set","")=="duo": count+=1
	return count>=3
func keyboard_attack_direction() -> Vector2:
	return Vector2(Input.get_axis("attack_left","attack_right"),Input.get_axis("attack_up","attack_down"))
func attack_input_held() -> bool:
	return Input.is_action_pressed("attack") or keyboard_attack_direction().length_squared()>.01
func aim() -> Vector2:
	var keyboard_direction:=keyboard_attack_direction()
	if keyboard_direction.length_squared()>.01: return keyboard_direction.normalized()
	if OS.has_feature("mobile") or OS.get_cmdline_user_args().has("--touch"):
		var direction:=Vector2(Input.get_axis("move_left","move_right"),Input.get_axis("aim_up","aim_down"))
		return direction.normalized() if direction.length_squared()>.01 else Vector2(world.player.facing,0)
	if DisplayServer.get_name()=="headless" or Input.is_physical_key_pressed(KEY_J): return Vector2(world.player.facing,0)
	var difference: Vector2 =get_global_mouse_position()-(world.player.position+Vector2(0,-28))
	return difference.normalized() if difference.length()>4 else Vector2(world.player.facing,0)
func perform_attack(slot: String) -> void:
	arsenal.attack(slot)
func fire_projectile(pos: Vector2,direction: Vector2,damage: float,friendly: bool,kind: String,source: Node=null,homing:=false) -> void:
	projectiles.append({"pos":pos,"velocity":direction*(440 if friendly else 220),"damage":damage,"friendly":friendly,"kind":kind,"life":(1.2 if friendly else 2.0),"age":0.0,"hit":[],"source":source,"homing":homing})
func use_skill(slot: String) -> void:
	arsenal.skill(slot)
func use_heart() -> void:
	if heart_cd>0: return
	var heart_id:=str(equipment.get("heart",""))
	var heart:=HeartDB.get_heart(heart_id)
	if heart.is_empty(): return
	# Mongdal has no Q skill; its identity is three rechargeable dashes.
	if heart_id=="mongdal": return
	if heart_id=="changgui":
		var targets:=living()
		if targets.is_empty(): return
		for enemy in targets:
			enemy.stun=maxf(enemy.stun,4.0)
			vfx.changgui_soul_bind(enemy)
		heart_animation=4.0
		heart_cd=float(heart["cooldown"])
		return
	var selected: Array = []
	for enemy in living():
		if visible_rect().has_point(enemy.position+Vector2(0,-25)): selected.append(enemy)
	if selected.is_empty(): return
	heart_pending.clear()
	for enemy in selected:
		if enemy.boss and enemy.state=="windup" and enemy.pattern==2: continue
		heart_pending.append(enemy)
		enemy.stun=maxf(enemy.stun,.3)
	heart_windup=.25
	heart_animation=1.1
	heart_cd=float(heart["cooldown"])
func nearest_enemy(pos: Vector2,distance: float):
	var target=null
	for enemy in living():
		var d: float = enemy.position.distance_to(pos)
		if d<distance:
			distance=d
			target=enemy
	return target
func equip_bag(index: int) -> void:
	var bag: Array = world.wallet["bag"]
	if index<0 or index>=bag.size(): return
	var item: Dictionary = DB.get_item(str(bag[index]["id"]))
	if item.is_empty(): return
	bag.remove_at(index)
	var slot: String = item["slot"]
	if slot=="accessory":
		slot="a0"
		for candidate in ["a0","a1","a2","a3"]:
			if equipment[candidate]=="":
				slot=candidate
				break
	if slot=="two":
		for hand in ["main","off"]:
			if equipment[hand]!="": bag.append(equipped(hand))
			equipment[hand]=""
		slot="main"
	elif slot=="off" and DB.is_two(equipped("main")):
		bag.append(equipped("main"))
		equipment["main"]=""
	if equipment[slot]!="": bag.append(equipped(slot))
	equipment[slot]=item["id"]
	refresh_inventory()
func unequip(slot: String) -> void:
	if slot=="heart" or equipment.get(slot,"")=="": return
	world.wallet["bag"].append(equipped(slot))
	equipment[slot]=""
	refresh_inventory()
func toggle_inventory() -> void:
	inventory.visible=not inventory.visible
	inventory_shade.visible=inventory.visible
	if is_instance_valid(game_hud): game_hud.set_inventory_open(inventory.visible)
	if inventory.visible: refresh_inventory()
func inv_label(text: String,size:=14,color:=Color("dce4d4")) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_override("font",InventoryFont)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label
func attack_type_label(item: Dictionary) -> String:
	if not item.has("kind"): return ""
	return "[근접]" if item["kind"]=="melee" else "[원거리]"

func inventory_style(bg:Color,border:Color,width:=1,margins:=6) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=bg
	style.border_color=border
	style.set_border_width_all(width)
	style.content_margin_left=margins
	style.content_margin_right=margins
	style.content_margin_top=margins
	style.content_margin_bottom=margins
	return style

func style_inventory_button(button:Button,selected:=false,danger:=false) -> void:
	var border:=Color("9ebba4") if selected else Color("4e554d")
	if danger: border=Color("79504b")
	button.add_theme_stylebox_override("normal",inventory_style(Color("11191d"),border,2,2))
	button.add_theme_stylebox_override("hover",inventory_style(Color("1b2828"),Color("b7c9ae"),2,2))
	button.add_theme_stylebox_override("pressed",inventory_style(Color("253332"),Color("d4c28f"),2,2))
	button.add_theme_stylebox_override("disabled",inventory_style(Color("0c1215"),Color("343b38"),1,2))
	button.add_theme_color_override("font_color",Color("ded7c5"))
	button.add_theme_color_override("font_disabled_color",Color("6d736d"))

func style_skin_slot(button:Button,selected:=false) -> void:
	button.add_theme_font_override("font",InventoryFont)
	var clear:=inventory_style(Color(0,0,0,0),Color(0,0,0,0),0,0)
	button.add_theme_stylebox_override("normal",clear)
	button.add_theme_stylebox_override("disabled",clear)
	button.add_theme_stylebox_override("hover",inventory_style(Color(0.25,0.12,0.08,.28),Color("c8a66a"),1,0))
	button.add_theme_stylebox_override("pressed",inventory_style(Color(0.35,0.14,0.08,.34),Color("e0bf7c"),1,0))
	if selected: button.add_theme_stylebox_override("normal",inventory_style(Color(0.28,0.12,0.06,.24),Color("cfa65d"),1,0))

func style_movable_slot(button:Button,selected:=false) -> void:
	button.add_theme_font_override("font",InventoryFont)
	var normal_path:="res://assets/ui/modular/slot-selected-v1.png" if selected else "res://assets/ui/modular/slot-normal-v1.png"
	for state in ["normal","disabled","hover","pressed"]:
		var style:=StyleBoxTexture.new()
		style.texture=load("res://assets/ui/modular/slot-selected-v1.png" if state in ["hover","pressed"] else normal_path)
		style.texture_margin_left=9
		style.texture_margin_right=9
		style.texture_margin_top=9
		style.texture_margin_bottom=9
		if state=="disabled": style.modulate_color=Color(.68,.66,.63,1)
		elif state=="pressed": style.modulate_color=Color(.82,.78,.70,1)
		button.add_theme_stylebox_override(state,style)

func style_action_button(button:Button,danger:=false) -> void:
	button.add_theme_font_override("font",InventoryFont)
	var paths:={"normal":"res://assets/ui/modular/button-normal-v1.png","hover":"res://assets/ui/modular/button-hover-v1.png","pressed":"res://assets/ui/modular/button-pressed-v1.png"}
	for state in paths:
		var style:=StyleBoxTexture.new()
		style.texture=load(paths[state])
		style.texture_margin_left=38
		style.texture_margin_right=38
		style.texture_margin_top=24
		style.texture_margin_bottom=24
		style.modulate_color=Color(.62,.60,.58,1) if state=="normal" else Color(.78,.75,.70,1)
		button.add_theme_stylebox_override(state,style)
	button.add_theme_color_override("font_color",Color("dca49b") if danger else Color("eee2cc"))

func add_slot_icon(button:Button,item:Dictionary,scale_value:=.84) -> void:
	var icon=preload("res://scripts/item_icon.gd").new()
	icon.item=item
	icon.show_frame=false
	icon.scale=Vector2.ONE*scale_value
	button.add_child(icon)
	var center_icon:=func():
		if is_instance_valid(icon) and is_instance_valid(button):
			icon.position=(button.size-Vector2(42,42)*scale_value)*.5
	button.resized.connect(center_icon)
	center_icon.call()

func add_equipped_slot(board:Control,slot:String,label_text:String,pos:Vector2,label_pos:Vector2) -> void:
	var button:=Button.new()
	button.position=pos
	button.size=Vector2(38,38)
	if slot=="heart": button.add_to_group("inventory_heart_slot")
	button.focus_mode=Control.FOCUS_NONE
	style_movable_slot(button,false)
	var item:=equipped(slot)
	if slot=="heart" and str(equipment.get("heart",""))!="":
		var heart:=HeartDB.get_heart(str(equipment["heart"]))
		var identity:String="대시 3회" if str(equipment["heart"])=="mongdal" else str(heart.get("skill_name",""))
		item={"name":heart.get("heart_name","심장"),"effect":"HP "+str(int(max_health))+" · "+identity,"slot":"heart"}
		var heart_icon:=InventoryHeartIcon.new()
		heart_icon.scale=Vector2.ONE*.8
		heart_icon.position=Vector2(2,2)
		button.add_child(heart_icon)
	elif not item.is_empty():
		add_slot_icon(button,item,.8)
	button.tooltip_text=label_text+" · "+str(item.get("name","비어 있음"))+"\n"+str(item.get("effect",""))
	button.disabled=item.is_empty() or slot=="heart"
	if slot!="heart": button.pressed.connect(func():unequip(slot))
	board.add_child(button)
	var label:=inv_label(label_text,9,Color("d8c39e"))
	label.position=label_pos
	label.size=Vector2(40,18)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	board.add_child(label)
	if slot=="heart" and not item.is_empty():
		button.modulate=Color("e2a0a0")
		var pulse:=button.create_tween().set_loops()
		pulse.tween_property(button,"modulate",Color("ffffff"),.55).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(button,"modulate",Color("e2a0a0"),.75).set_trans(Tween.TRANS_SINE)

func inventory_rect(id: String) -> Rect2:
	return InventoryLayout.rect(id, inventory.size)

func apply_inventory_rect(control: Control, id: String) -> void:
	var target := inventory_rect(id)
	control.position = target.position
	control.size = target.size

func add_layout_equipped_slot(board: Control, id: String, slot: String, label_text: String) -> void:
	var node := InventoryLayout.node(id, inventory.size)
	var values: Array = node.get("rect", [0, 0, 38, 38])
	var label_values: Array = node.get("label", {}).get("rect", [0, 0, 40, 18])
	add_equipped_slot(board, slot, label_text, Vector2(values[0], values[1]), Vector2(label_values[0], label_values[1]))

func select_inventory(index:int) -> void:
	inventory_selection=index
	refresh_inventory()
	call_deferred("play_inventory_selection_fx",index)

func play_inventory_selection_fx(index:int) -> void:
	for node in get_tree().get_nodes_in_group("inventory_bag_slot"):
		if int(node.get_meta("bag_index",-1))==index and is_instance_valid(inventory_fx):
			inventory_fx.play_at(node.global_position+node.size*.5)
			return

func refresh_inventory() -> void:
	for child in inv_rows.get_children():
		inv_rows.remove_child(child)
		child.queue_free()
	var title:=inv_label("빌린 몸",17,Color("2a1710"))
	apply_inventory_rect(title,"title_label")
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	inv_rows.add_child(title)
	var souls:=inv_label("영혼조각  ◆ "+str(world.wallet["souls"]),13,Color("d9c59a"))
	apply_inventory_rect(souls,"souls")
	souls.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	inv_rows.add_child(souls)
	var close:=Button.new()
	close.text="닫기"
	apply_inventory_rect(close,"btn_close")
	close.focus_mode=Control.FOCUS_NONE
	style_action_button(close,false)
	close.pressed.connect(toggle_inventory)
	inv_rows.add_child(close)
	var board:=InventoryPaperDoll.new()
	apply_inventory_rect(board,"doll")
	add_layout_equipped_slot(board,"slot_head","head","머리")
	add_layout_equipped_slot(board,"slot_main","main","주무기")
	add_layout_equipped_slot(board,"slot_legs","legs","다리")
	add_layout_equipped_slot(board,"slot_feet","feet","발")
	add_layout_equipped_slot(board,"slot_heart","heart","심장")
	add_layout_equipped_slot(board,"slot_off","off","보조무기")
	add_layout_equipped_slot(board,"slot_internal","internal","내장")
	inv_rows.add_child(board)
	var accessory_slots:Array=equipment.keys().filter(func(key):return str(key).begins_with("a"))
	accessory_slots.sort()
	var accessory_rail:=InventoryAccessoryRail.new()
	apply_inventory_rect(accessory_rail,"rail_panel")
	accessory_rail.configure(accessory_slots.size())
	inv_rows.add_child(accessory_rail)
	var accessory_title:=inv_label("악세사리",10,Color("29170e"))
	accessory_title.position=Vector2((accessory_rail.size.x-88)*.5,1)
	accessory_title.size=Vector2(88,18)
	accessory_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	accessory_rail.add_child(accessory_title)
	var accessory_row:=HBoxContainer.new()
	accessory_row.position=accessory_rail.slots_origin()
	accessory_row.size=Vector2(accessory_rail.slots_width(),accessory_rail.slot_size)
	accessory_row.add_theme_constant_override("separation",int(accessory_rail.gap))
	for slot in accessory_slots:
		var accessory_button:=Button.new()
		accessory_button.custom_minimum_size=Vector2.ONE*accessory_rail.slot_size
		accessory_button.focus_mode=Control.FOCUS_NONE
		style_movable_slot(accessory_button,false)
		var accessory:=equipped(slot)
		if not accessory.is_empty(): add_slot_icon(accessory_button,accessory,accessory_rail.slot_size/42.0*.88)
		accessory_button.disabled=accessory.is_empty()
		accessory_button.add_to_group("inventory_accessory_slot")
		accessory_button.tooltip_text="악세사리 · "+str(accessory.get("name","비어 있음"))
		accessory_button.pressed.connect(func():unequip(slot))
		accessory_row.add_child(accessory_button)
	accessory_rail.add_child(accessory_row)
	var bag_title:=inv_label("가방",14,Color("28170f"))
	apply_inventory_rect(bag_title,"bag_title")
	bag_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	inv_rows.add_child(bag_title)
	var scroll:=ScrollContainer.new()
	apply_inventory_rect(scroll,"bag_grid")
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("panel",inventory_style(Color(0,0,0,0),Color(0,0,0,0),0,0))
	var grid:=GridContainer.new()
	var bag_layout := InventoryLayout.node("bag_grid",inventory.size)
	grid.columns=int(bag_layout.get("columns",6))
	var gaps: Array=bag_layout.get("gap",[7,4])
	grid.add_theme_constant_override("h_separation",int(gaps[0]))
	grid.add_theme_constant_override("v_separation",int(gaps[1]))
	var cell: Array=bag_layout.get("cell",[38,36])
	var bag: Array=world.wallet["bag"]
	inventory_selection=clampi(inventory_selection,0,maxi(0,bag.size()-1))
	for i in range(maxi(int(bag_layout.get("minCells",30)),bag.size())):
		var button:=Button.new()
		button.custom_minimum_size=Vector2(cell[0],cell[1])
		button.focus_mode=Control.FOCUS_NONE
		style_movable_slot(button,i==inventory_selection)
		button.add_to_group("inventory_bag_slot")
		button.set_meta("bag_index",i)
		if i<bag.size():
			add_slot_icon(button,bag[i],.72)
			button.tooltip_text=str(bag[i]["name"])+" "+attack_type_label(bag[i])+" / "+str(bag[i].get("effect",""))
			button.pressed.connect(func():select_inventory(i))
		else: button.disabled=true
		grid.add_child(button)
	scroll.add_child(grid)
	inv_rows.add_child(scroll)
	if not bag.is_empty():
		var item: Dictionary=bag[inventory_selection]
		var detail_icon_button:=Button.new()
		apply_inventory_rect(detail_icon_button,"detail_icon")
		detail_icon_button.mouse_filter=Control.MOUSE_FILTER_IGNORE
		style_movable_slot(detail_icon_button,false)
		add_slot_icon(detail_icon_button,item,1.0)
		inv_rows.add_child(detail_icon_button)
		var item_name:=inv_label(str(item["name"]),16,Color("f0dcae"))
		apply_inventory_rect(item_name,"detail_name")
		inv_rows.add_child(item_name)
		var meta:=inv_label(DB.slot_name(item["slot"])+" · "+attack_type_label(item)+" · "+str(item.get("tier",1))+"단계",10,Color("b99d72"))
		apply_inventory_rect(meta,"detail_meta")
		inv_rows.add_child(meta)
		var effect_label:=inv_label(str(item.get("effect","")),11,Color("d8d1c2"))
		apply_inventory_rect(effect_label,"detail_effect")
		effect_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		inv_rows.add_child(effect_label)
		var equip_button:=Button.new()
		equip_button.text="장착"
		apply_inventory_rect(equip_button,"btn_equip")
		equip_button.focus_mode=Control.FOCUS_NONE
		equip_button.add_theme_font_size_override("font_size",14)
		equip_button.add_theme_color_override("font_color",Color("e7dcc5"))
		style_action_button(equip_button,false)
		equip_button.pressed.connect(func():equip_bag(inventory_selection))
		inv_rows.add_child(equip_button)
		var destroy:=Button.new()
		destroy.text="파기"
		apply_inventory_rect(destroy,"btn_destroy")
		destroy.focus_mode=Control.FOCUS_NONE
		destroy.add_theme_font_size_override("font_size",14)
		style_action_button(destroy,true)
		destroy.pressed.connect(func():
			pending_destroy=inventory_selection
			confirm.dialog_text=str(item["name"])+" ("+str(item.get("tier",1))+"단계)\n영구 파기하면 복구할 수 없습니다."
			confirm.popup_centered(Vector2i(420,160))
			confirm.get_cancel_button().grab_focus())
		inv_rows.add_child(destroy)
	else:
		var empty_label:=inv_label("가방이 비어 있습니다. 장비는 가까이 가면 자동으로 획득합니다.",14,Color("bcae91"))
		apply_inventory_rect(empty_label,"empty_hint")
		inv_rows.add_child(empty_label)
func destroy_confirmed() -> void:
	if pending_destroy>=0 and pending_destroy<world.wallet["bag"].size(): world.wallet["bag"].remove_at(pending_destroy)
	pending_destroy=-1
	refresh_inventory()
func tick_projectiles(delta: float) -> void:
	for i in range(projectiles.size()-1,-1,-1):
		var p:Dictionary=projectiles[i]
		p["life"]-=delta
		p["age"]+=delta
		if p["life"]<=0:
			projectiles.remove_at(i)
			continue
		var from:Vector2=p["pos"]
		if p["homing"]:
			var target=nearest_enemy(from,300)
			if target!=null: p["velocity"]=Vector2(p["velocity"]).lerp((target.position+Vector2(0,-23)-from).normalized()*440,.08)
		if p["kind"]=="goblin": p["velocity"]=Vector2(p["velocity"]).rotated(sin(p["age"]*16)*delta*2)
		if p["kind"]=="boomerang" and p["age"]>.45:
			if not p.get("returning",false):
				p["returning"]=true
				p["hit"].clear()
			p["velocity"]=(world.player.position+Vector2(0,-28)-from).normalized()*440
			if from.distance_to(world.player.position+Vector2(0,-28))<18: p["life"]=0
		if p["kind"] in ["water","poison"]: p["velocity"]+=Vector2(0,500*delta)
		var to:Vector2=from+Vector2(p["velocity"])*delta
		var wall:Dictionary={}
		if p["kind"] not in ["whistle","tiger"]:
			wall=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from,to,1))
		if not wall.is_empty():
			to=wall["position"]
			if p["kind"]=="boomerang" and not p.get("returning",false):
				p["age"]=.46
			else: p["life"]=0
			if p["kind"] in ["water","poison","pin"]:
				zones.append({"kind":p["kind"],"weapon":p.get("weapon",""),"pos":to if p["kind"]=="pin" else safe_ground(to.x),"life":3.0,"tick":0.0})
		p["pos"]=to
		if p["friendly"]:
			for enemy in living():
				if p["hit"].has(enemy.get_instance_id()): continue
				var center:Vector2=enemy.position+Vector2(0,-25*enemy.size_factor)
				if Geometry2D.get_closest_point_to_segment(center,from,to).distance_to(center)<18*enemy.size_factor+6*float(p.get("size",1)):
					arsenal.hit(enemy,p["damage"],p.get("weapon",""))
					p["hit"].append(enemy.get_instance_id())
					if p["kind"] not in ["whistle","boomerang","beam","tiger"]:
						if p["kind"] in ["water","poison"]: zones.append({"kind":p["kind"],"weapon":p.get("weapon",""),"pos":safe_ground(to.x),"life":3.0,"tick":0.0})
						p["life"]=0
						break
		else:
			var absorbed:=false
			for zone in zones:
				if zone["kind"]=="decoy" and Geometry2D.get_closest_point_to_segment(zone["pos"]+Vector2(0,-23),from,to).distance_to(zone["pos"]+Vector2(0,-23))<24:
					zone["hp"]=float(zone.get("hp",18))-float(p["damage"])
					if zone["hp"]<=0: zone["life"]=0
					absorbed=true
					p["life"]=0
					break
			if not absorbed and is_instance_valid(p["source"]) and p["source"].confusion>0:
				for enemy in living():
					if enemy!=p["source"] and Geometry2D.get_closest_point_to_segment(enemy.position+Vector2(0,-23),from,to).distance_to(enemy.position+Vector2(0,-23))<24:
						enemy.take_damage(p["damage"])
						p["life"]=0
			elif not absorbed:
				var center:Vector2=world.player.position+Vector2(0,-23)
				if Geometry2D.get_closest_point_to_segment(center,from,to).distance_to(center)<17:
					hurt(p["damage"])
					p["life"]=0
		if p["life"]<=0:
			projectiles.remove_at(i)
func tick_zones(delta: float) -> void:
	for i in range(zones.size()-1,-1,-1):
		var zone:Dictionary=zones[i]
		zone["life"]-=delta
		if str(zone["kind"]).begins_with("enemy-"):
			zone["delay"]=float(zone.get("delay",0.0))-delta
			zone["hurt_cd"]=maxf(0.0,float(zone.get("hurt_cd",0.0))-delta)
			if float(zone["delay"])<=0:
				if zone["kind"]=="enemy-arrow-rain" and not bool(zone["triggered"]):
					zone["triggered"]=true
					area_effect(Vector2(zone["pos"])+Vector2(0,-12),34,float(zone["damage"]),zone.get("source"))
					zone["life"]=minf(float(zone["life"]),.12)
				elif zone["kind"]=="enemy-seal" and Vector2(zone["pos"]).distance_to(world.player.position)<48 and float(zone["hurt_cd"])<=0:
					hurt(float(zone["damage"]))
					zone["hurt_cd"]=.75
			if zone["life"]<=0: zones.remove_at(i)
			continue
		zone["tick"]-=delta
		if zone["tick"]<=0 and zone["life"]>0:
			zone["tick"]=.15 if zone["kind"] in ["well","lure","rush"] else .4
			if zone["kind"]=="rush":
				zone["pos"]=world.player.position+Vector2(0,-23)
				for enemy in living():
					if enemy.position.distance_to(zone["pos"])<110 and not zone["hit"].has(enemy.get_instance_id()):
						zone["hit"].append(enemy.get_instance_id())
						arsenal.hit(enemy,30,"mongdal_rush")
				arsenal.mark(zone["pos"],50)
			else:
				for enemy in living():
					var distance:float=enemy.position.distance_to(zone["pos"])
					if zone["kind"] in ["well","lure"] and distance<220:
						enemy.pull_to(safe_ground(Vector2(zone["pos"]).x),.22)
					if distance<80:
						if zone["kind"]=="water": enemy.slow=1.0
						if zone["kind"] in ["poison","pin"]: enemy.take_damage(3)
						if zone["kind"]=="mine":
							vfx.emit("bloom",int(DB.get_item(zone.get("weapon","")).get("tier",1)),zone["pos"]+Vector2(0,-12),Vector2.RIGHT,.8)
							area_effect(zone["pos"]+Vector2(0,-12),90,20)
							zone["life"]=0
							break
		if zone["life"]<=0:
			if zone["kind"]=="decoy": area_effect(zone["pos"]+Vector2(0,-20),100,15)
			zones.remove_at(i)
func tick_pickups(delta: float) -> void:
	for i in range(pickups.size()-1,-1,-1):
		var pickup: Dictionary = pickups[i]
		var pos: Vector2 = pickup["pos"]
		var target: Vector2 = world.player.position+Vector2(0,-20)
		if pickup["kind"]=="chest": continue
		elif pickup["kind"]=="chest_opening":
			pickup["open_age"]=float(pickup.get("open_age",0.0))+delta
			if float(pickup["open_age"])>=1.15:
				pickup["kind"]="item"
				pickup["pickup_delay"]=.55
				message("상자 개봉 · "+str(pickup["item"]["name"]))
			continue
		elif float(pickup.get("pickup_delay",0.0))>0:
			pickup["pickup_delay"]=maxf(0.0,float(pickup["pickup_delay"])-delta)
			continue
		elif pos.distance_to(target)<120:
			pickup["pos"]=pos.move_toward(target,380*delta)
			if Vector2(pickup["pos"]).distance_to(target)<16:
				if pickup["kind"]=="souls": world.wallet["souls"]+=int(pickup["amount"])
				else:
					world.wallet["bag"].append(pickup["item"].duplicate(true))
					message("획득 · "+str(pickup["item"]["name"]))
				pickups.remove_at(i)
func near_chest() -> bool:
	for pickup in pickups:
		if pickup["kind"]=="chest" and Vector2(pickup["pos"]).distance_to(world.player.position+Vector2(0,-20))<75: return true
	return false
func try_open_chest() -> bool:
	for pickup in pickups:
		if pickup["kind"]=="chest" and Vector2(pickup["pos"]).distance_to(world.player.position+Vector2(0,-20))<75:
			pickup["kind"]="chest_opening"
			pickup["open_age"]=0.0
			message("봉인된 보상 상자를 엽니다")
			return true
	return false
func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(world.player): return
	visual_clock += delta
	if Input.is_action_just_pressed("inventory") and not confirm.visible and not (is_instance_valid(world.merchant) and world.merchant.opened): toggle_inventory()
	hit_pause=maxf(0,hit_pause-delta)
	paused=vfx_preview_paused or inventory.visible or (is_instance_valid(game_hud) and game_hud.settings_open) or world.floor_map_open or world.traveling or boss_transitioning or (is_instance_valid(world.merchant) and world.merchant.opened) or world.seed_input.has_focus() or hit_pause>0
	if paused: return
	hurt_timer=maxf(0,hurt_timer-delta)
	heart_cd=maxf(0,heart_cd-delta)
	heart_animation=maxf(0,heart_animation-delta)
	frenzy=maxf(0,frenzy-delta)
	regen_cd=maxf(0,regen_cd-delta)
	tooth_reload=maxf(0,tooth_reload-delta)
	if heart_windup>0:
		heart_windup=maxf(0,heart_windup-delta)
		if heart_windup<=0:
			for i in range(heart_pending.size()):
				var enemy=heart_pending[i]
				if is_instance_valid(enemy) and not enemy.dead:
					enemy.pull_to(safe_ground(world.player.position.x+world.player.facing*(62+i*5)),.7)
			heart_pending.clear()
	arsenal.tick(delta)
	toast_time=maxf(0,toast_time-delta)
	if toast_time<=0: toast.text=""
	for slot in ["main","off"]:
		attack_cd[slot]=maxf(0,float(attack_cd[slot])-delta)
		skill_cd[slot]=maxf(0,float(skill_cd[slot])-delta)
	if attack_input_held() and not world.in_village:
		for slot in ["main","off"]:
			if float(attack_cd[slot])<=0: perform_attack(slot)
	if Input.is_action_just_pressed("heart_skill") and not world.in_village: use_heart()
	if Input.is_action_just_pressed("main_skill") and not world.in_village: use_skill("main")
	if Input.is_action_just_pressed("off_skill") and not world.in_village: use_skill("off")
	var dashing: bool = world.player.dash_time>0
	world.player.movement_multiplier=(1.12 if has_passive("speed") else 1.0)*(1.15 if has_passive("frenzy") and frenzy>0 else 1.0)
	if dashing and not previous_dash:
		var main:=equipped("main")
		if main.get("kind","")=="melee":
			area_effect(world.player.position+world.player.dash_direction*48+Vector2(0,-20),70,float(main.get("damage",0))*.7*(1.5 if has_passive("dash_power") else 1.0))
		if has_passive("wet_dash"): zones.append({"kind":"water","weapon":"wet_shoes","pos":safe_ground(world.player.position.x),"life":2.0,"tick":0.0})
	previous_dash=dashing
	if world.player.is_on_floor() and not previous_floor and has_passive("landing"):
		for enemy in living():
			if enemy.position.distance_to(world.player.position)<90: enemy.knockback=signf(enemy.position.x-world.player.position.x)*260
	previous_floor=world.player.is_on_floor()
	tick_projectiles(delta)
	tick_zones(delta)
	tick_pickups(delta)
	for i in range(effects.size()-1,-1,-1):
		effects[i]["time"]-=delta
		if effects[i]["time"]<=0: effects.remove_at(i)
	game_hud.set_stats(health,max_health,world.wallet["bag"].size(),world.player.dash_charges,world.player.dash_max_charges)
	hud.text=""
	var heart:Dictionary=HeartDB.get_heart(str(equipment.get("heart","")))
	var heart_id:=str(equipment.get("heart",""))
	var skills:String=""
	if heart_id=="mongdal": skills="대시 "+str(world.player.dash_charges)+"/"+str(world.player.dash_max_charges)
	elif not heart_id.is_empty(): skills=str(heart.get("skill_name","심장"))+" "+("준비" if heart_cd<=0 else str(int(ceil(heart_cd)))+"초")
	for slot in ["main","off"]:
		if not str(equipped(slot).get("skill","")).is_empty() or (slot=="off" and duo_set()):
			if not skills.is_empty(): skills+="  |  "
			skills+=("주무기 " if slot=="main" else "보조무기 ")+("준비" if float(skill_cd[slot])<=0 else str(int(ceil(skill_cd[slot])))+"초")
	skill_bar.text=skills
	for enemy in living():
		if enemy.boss:
			var phase_text:=" · "+str(enemy.jangsan_phase)+"페이즈" if enemy.kind=="jangsanbeom" else ""
			hud.text+=("장산범" if enemy.kind=="jangsanbeom" else "선봉대장")+" "+str(int(enemy.hp))+" / "+str(int(enemy.max_hp))+phase_text
	queue_redraw()
func _draw() -> void:
	arsenal.draw()
	if is_instance_valid(world.player):
		var view:=visible_rect().grow(-28)
		for enemy in living():
			var pos: Vector2=enemy.position+Vector2(0,-28)
			if not view.has_point(pos):
				var point:=Vector2(clampf(pos.x,view.position.x,view.end.x),clampf(pos.y,view.position.y+80,view.end.y-45))
				var direction: Vector2=(pos-view.get_center()).normalized()
				var side:=direction.orthogonal()
				draw_polygon(PackedVector2Array([point+direction*10,point-direction*5+side*6,point-direction*5-side*6]),PackedColorArray([Color("e2a78b")]))
	for p in projectiles:
		if not p["friendly"] and p["kind"]!="talisman": draw_line(p["pos"]-Vector2(p["velocity"]).normalized()*10,p["pos"],Color("e1b17c"),3)
	for zone in zones:
		if zone["kind"]=="decoy": draw_rect(Rect2(zone["pos"]-Vector2(13,46),Vector2(26,46)),Color(.6,.8,.75,.5))
		elif zone["kind"]=="enemy-arrow-rain":
			var warning_alpha:=.28 if float(zone.get("delay",0.0))>0 else .75
			draw_line(Vector2(zone["pos"])+Vector2(-24,0),Vector2(zone["pos"])+Vector2(24,0),Color(0.76,0.32,0.24,warning_alpha),3)
			draw_line(Vector2(zone["pos"])+Vector2(0,-180),Vector2(zone["pos"])+Vector2(0,-8),Color(0.72,0.62,0.42,warning_alpha),2)
		elif zone["kind"]=="enemy-seal":
			var active:=float(zone.get("delay",0.0))<=0
			draw_rect(Rect2(Vector2(zone["pos"])+Vector2(-42,-8),Vector2(84,8)),Color(0.18,0.12,0.1,.72 if active else .28))
			if active:
				for knot in range(-32,33,16): draw_line(Vector2(zone["pos"])+Vector2(knot,-8),Vector2(zone["pos"])+Vector2(knot+8,-34),Color("9b7350"),3)
	for effect in effects:
		if effect["color"]==Color("db9a73"): draw_arc(effect["pos"],effect["radius"],-.8,2.4,24,effect["color"],2)
	for pickup in pickups:
		var pos: Vector2=pickup["pos"]
		if pickup["kind"]=="souls":
			draw_polygon(PackedVector2Array([pos+Vector2(0,-8),pos+Vector2(5,0),pos+Vector2(0,8),pos+Vector2(-5,0)]),PackedColorArray([Color("a6dec3")]))
		elif pickup["kind"] in ["chest","chest_opening"]:
			draw_reward_chest(pickup)
		else:
			if not draw_provided_drop(pickup):
				draw_circle(pos,8,[Color("c2ccbe"),Color("7fadd0"),Color("b39dd1"),Color("e4c178")][mini(3,int(pickup["item"].get("tier",1))-1)])
	if heart_animation>0 and is_instance_valid(world.player):
		var from: Vector2=world.player.position+Vector2(0,-36)
		for enemy in living():
			if enemy.pull_remaining>0 or heart_pending.has(enemy):
				var to: Vector2=enemy.position+Vector2(0,-28*enemy.size_factor)
				for j in range(4):
					var points:=PackedVector2Array()
					for k in range(20):
						var u:=k/19.0*(1-heart_windup/.25) if heart_windup>0 else k/19.0
						points.append(from.lerp(to,u)+Vector2(0,sin(u*PI)*(-18+j*2)))
					draw_polyline(points,Color("3b414e") if j!=1 else Color("a5bfb6"),2)

func draw_reward_chest(pickup: Dictionary) -> void:
	var frame:=0
	if pickup["kind"]=="chest_opening":
		frame=clampi(int(float(pickup.get("open_age",0.0))*float(reward_chest_info["fps"])),0,int(reward_chest_info["frames"])-1)
	var frame_size:=Vector2(reward_chest_info["frameSize"][0],reward_chest_info["frameSize"][1])
	var pivot:=Vector2(reward_chest_info["pivot"][0],reward_chest_info["pivot"][1])
	var columns:=int(reward_chest_info["columns"])
	var source:=Rect2(Vector2(frame%columns,floori(float(frame)/columns))*frame_size,frame_size)
	var pos:Vector2=pickup["pos"]+Vector2(0,18)
	draw_texture_rect_region(REWARD_CHEST_TEXTURE,Rect2(pos-pivot,frame_size),source)

func draw_provided_drop(pickup: Dictionary) -> bool:
	var item: Dictionary = pickup.get("item", {})
	var id := str(item.get("id", ""))
	if GEAR2_DROPS.has(id): return draw_gear2_drop(pickup, str(GEAR2_DROPS[id]))
	if not PROVIDED_DROPS.has(id): return false
	# Drops use the neutral sheet at every rarity; tier is communicated in UI,
	# without escalating sparkle pillars or motes around the item itself.
	var key: String = str(PROVIDED_DROPS[id]) + "_tier0"
	if not drop_info.has(key):
		var base := "res://assets/provided_vfx/items/" + key
		drop_info[key] = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))["meta"]["pixelfx"]
		drop_textures[key] = load(base + ".png")
	var info: Dictionary = drop_info[key]
	var frame := int(visual_clock * float(info["fps"])) % int(info["frames"])
	var size := Vector2(info["frameSize"][0], info["frameSize"][1])
	var pivot := Vector2(info["pivot"][0], info["pivot"][1])
	var columns := int(info["columns"])
	var row := floori(float(frame)/float(columns))
	var source := Rect2(Vector2(frame % columns, row) * size, size)
	draw_texture_rect_region(drop_textures[key], Rect2(Vector2(pickup["pos"]) + Vector2(0, 18) - pivot, size), source)
	return true

func draw_gear2_drop(pickup: Dictionary, name: String) -> bool:
	var key := "gear2_" + name
	if not drop_info.has(key):
		var base := "res://assets/gear2/drop/" + name
		drop_info[key] = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))["meta"]["pixelfx"]
		drop_textures[key] = load(base + ".png")
	var info: Dictionary = drop_info[key]
	var frame := int(visual_clock * float(info["fps"])) % int(info["frames"])
	var size := Vector2(info["frameSize"][0], info["frameSize"][1])
	var pivot := Vector2(info["pivot"][0], info["pivot"][1])
	var columns := int(info["columns"])
	var row := floori(float(frame)/float(columns))
	var source := Rect2(Vector2(frame % columns, row) * size, size)
	draw_texture_rect_region(drop_textures[key], Rect2(Vector2(pickup["pos"]) + Vector2(0,18) - pivot, size), source)
	return true
