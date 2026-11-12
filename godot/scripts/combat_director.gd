extends Node2D
const DB = preload("res://scripts/equipment_db.gd")
const Progression = preload("res://scripts/progression.gd")
const PixelVFX = preload("res://scripts/pixel_vfx.gd")
const InventoryPaperDoll = preload("res://scripts/inventory_paper_doll.gd")
const InventorySelectFX = preload("res://scripts/inventory_select_fx.gd")
const InventoryHeartIcon = preload("res://scripts/inventory_heart_icon.gd")
const InventoryAccessoryRail = preload("res://scripts/inventory_accessory_rail.gd")
const BagUtil = preload("res://scripts/bag_util.gd")
const DragSlot = preload("res://scripts/inventory_drag_slot.gd")
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
var bag_scroll: ScrollContainer
var bag_scroll_value := 0
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
var warden_pattern_active := false
var warden_pattern := ""
var warden_last_pattern := ""
var warden_boss: Node = null
var warden_orb := {}
var warden_orbs_left := 0
var warden_pattern_time := 0.0
var warden_spawn_timer := 0.0
var warden_no_hit := true
var warden_saved_max_health := 0.0
var warden_saved_dash_max := 1
var warden_saved_role := ""
var warden_saved_modulate := Color.WHITE
var warden_heart_sealed := false
var warden_player_stagger := 0.0
const PROVIDED_DROPS = {"hair":"hair","pin":"hairpin","water_bucket":"gourd","fox_bead":"foxbead","claws":"claw","goblin_fire":"ghostfire","plague":"jar","fist":"fist"}
const GEAR2_DROPS = {"songaksi_hand":"songakHand","ribbon":"ribbon","mirror":"jokduri","eggshell":"eggshell","blank_face":"blankface","gaze":"hollowgaze","wig":"wig","duo_head":"mask","bent_leg":"brokenLeg","mongdal_legs":"leg","wet_shoes":"shoe","single_shoe":"oneShoe","stomach":"stomach","duo_curse":"curse"}
const GEAR3_DROPS = {"nails":"mongdalNail","goose":"woodGoose","mongdal_rush":"mongdalHan","call":"changgwiBell","tiger_soul":"boundSoul","tiger_fang":"tigerFang","water_hand":"drownedHand","well_bucket":"wellBucket","fox_fire":"foxFire","fox_mirror":"shapeMirror","club":"dokkaebiClub","broom":"oldBroom","belt":"ssireumSash","tooth":"agwiTeeth","tongue":"agwiTongue","shadow":"murkShadow","voice":"mimicVoice","whistle":"thinWhistle","mouth":"giantMouth","jangsan_paw":"jangsanPaw","fox_tail":"foxTail"}
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
			BagUtil.add(world.wallet["bag"],DB.get_item(id))
		world.wallet["starter_given"]=true
func message(text: String) -> void:
	toast.text=text
	toast_time=3
func leave_room() -> void:
	end_warden_pattern(false)
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
			spawn_enemy("soul-warden",safe_ground(width*.52),0)
			message("쇄혼대감 · 심장을 봉인하는 집행관을 쓰러뜨리십시오")
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

func start_random_warden_pattern(boss: Node) -> bool:
	if warden_pattern_active or not is_instance_valid(boss) or boss.dead: return false
	var chosen:="capture" if rng.randf()<.5 else "stakes"
	if boss.hp<=boss.max_hp*.3 and rng.randf()<.2: chosen="heart"
	if chosen==warden_last_pattern:
		chosen="stakes" if chosen=="capture" else "capture"
	start_warden_pattern(boss,chosen)
	return true

func start_warden_pattern(boss: Node, chosen: String) -> void:
	if warden_pattern_active: return
	warden_pattern_active=true
	warden_pattern=chosen
	warden_boss=boss
	warden_pattern_time=0.0
	warden_no_hit=true
	boss.state="approach"
	boss.velocity=Vector2.ZERO
	if chosen=="capture":
		warden_orbs_left=rng.randi_range(3,5)
		world.player.controls_enabled=false
		spawn_warden_orb()
		message("쇄혼 포획 · 2초 안에 봉인구슬을 연타하십시오")
	elif chosen=="stakes":
		warden_saved_max_health=max_health
		warden_saved_dash_max=world.player.dash_max_charges
		max_health=maxf(30.0,max_health-15.0)
		health=minf(health,max_health)
		world.player.dash_max_charges=maxi(1,world.player.dash_max_charges-1)
		world.player.dash_charges=mini(world.player.dash_charges,world.player.dash_max_charges)
		warden_heart_sealed=true
		var width:=float(world.room.definition["width"])
		for ratio in [.28,.5,.72]:
			zones.append({"kind":"warden-stake","pos":safe_ground(width*ratio),"life":999.0,"hp":50.0,"max_hp":50.0})
		message("삼중 봉인 · 말뚝을 부숴 심장과 체력을 되찾으십시오")
	else:
		warden_saved_max_health=max_health
		warden_saved_role=str(world.player.visual.role)
		warden_saved_modulate=world.player.visual.modulate
		max_health=maxf(30.0,max_health-15.0)
		health=minf(health,max_health)
		warden_heart_sealed=true
		world.player.visual.set_role("songaksi")
		world.player.visual.modulate=Color("11121a")
		warden_spawn_timer=.35
		message("심장 적출 · 5초 동안 떨어지는 부적을 피하십시오")

func spawn_warden_orb() -> void:
	var view:=visible_rect().grow(-74)
	warden_orb={"pos":Vector2(rng.randf_range(view.position.x,view.end.x),rng.randf_range(view.position.y+75,view.end.y-45)),"hits":0,"time":2.0}

func hit_warden_orb(world_pos: Vector2, aimed:=false) -> bool:
	if not warden_pattern_active or warden_pattern!="capture" or warden_orb.is_empty(): return false
	var orb_pos:Vector2=warden_orb["pos"]
	if not aimed and orb_pos.distance_to(world_pos)>34: return false
	if aimed:
		var from:Vector2=world.player.position+Vector2(0,-28)
		var aim_dir:Vector2=(world_pos-from).normalized()
		var orb_dir:Vector2=(orb_pos-from).normalized()
		if aim_dir.dot(orb_dir)<.92: return false
	warden_orb["hits"]=int(warden_orb["hits"])+1
	if int(warden_orb["hits"])>=4:
		warden_orbs_left-=1
		if warden_orbs_left<=0:
			if is_instance_valid(warden_boss):
				warden_boss.take_damage(warden_boss.max_hp*.05)
				warden_boss.stun=maxf(warden_boss.stun,2.0)
				warden_boss.vulnerable=maxf(warden_boss.vulnerable,2.0)
			end_warden_pattern(true)
		else: spawn_warden_orb()
	return true

func damage_warden_stakes(origin: Vector2, radius: float, damage: float) -> bool:
	var hit_any:=false
	for zone in zones.duplicate():
		if zone.get("kind","")!="warden-stake" or Vector2(zone["pos"]).distance_to(origin)>radius+22: continue
		zone["hp"]=float(zone["hp"])-damage
		hit_any=true
		if float(zone["hp"])<=0:
			zones.erase(zone)
			max_health=minf(warden_saved_max_health,max_health+5.0)
			health=minf(max_health,health+5.0)
	if warden_pattern_active and warden_pattern=="stakes" and not zones.any(func(z): return z.get("kind","")=="warden-stake"):
		if is_instance_valid(warden_boss):
			warden_boss.stun=maxf(warden_boss.stun,3.0)
			warden_boss.vulnerable=maxf(warden_boss.vulnerable,3.0)
		end_warden_pattern(true)
	return hit_any

func end_warden_pattern(success: bool) -> void:
	if not warden_pattern_active: return
	var finished:=warden_pattern
	if finished=="capture": world.player.controls_enabled=true
	if finished in ["stakes","heart"] and warden_saved_max_health>0:
		max_health=warden_saved_max_health
		health=minf(health,max_health)
	if finished=="stakes":
		world.player.dash_max_charges=warden_saved_dash_max
		world.player.dash_charges=mini(world.player.dash_charges,world.player.dash_max_charges)
		for zone in zones.duplicate():
			if zone.get("kind","")=="warden-stake": zones.erase(zone)
	if finished=="heart" and is_instance_valid(world.player.visual):
		world.player.visual.set_role(warden_saved_role)
		world.player.visual.modulate=warden_saved_modulate
	warden_heart_sealed=false
	warden_orb.clear()
	if is_instance_valid(warden_boss):
		warden_boss.special_cooldown=20.0 if finished=="heart" else rng.randf_range(10.0,15.0)
	warden_last_pattern=finished
	warden_pattern_active=false
	warden_pattern=""
	warden_saved_max_health=0.0
	if success: message("봉인 파훼 · 쇄혼대감이 빈틈을 보입니다")

func tick_warden_pattern(delta: float) -> void:
	if not warden_pattern_active: return
	warden_pattern_time+=delta
	if warden_pattern=="capture":
		warden_orb["time"]=float(warden_orb.get("time",0.0))-delta
		if float(warden_orb["time"])<=0:
			hurt(15.0)
			end_warden_pattern(false)
			warden_player_stagger=1.0
			world.player.controls_enabled=false
			message("포획 실패 · 1초간 움직일 수 없습니다")
	elif warden_pattern=="heart":
		warden_spawn_timer-=delta
		if warden_spawn_timer<=0 and warden_pattern_time<4.3:
			warden_spawn_timer=rng.randf_range(.52,.72)
			var view:=visible_rect().grow(-65)
			queue_enemy_strike("warden-talisman",Vector2(rng.randf_range(view.position.x,view.end.x),world.player.position.y),.7,8.0,warden_boss)
		if warden_pattern_time>=5.0:
			if warden_no_hit and is_instance_valid(warden_boss):
				warden_boss.stun=maxf(warden_boss.stun,2.0)
				warden_boss.vulnerable=maxf(warden_boss.vulnerable,2.0)
			end_warden_pattern(warden_no_hit)

func _unhandled_input(event: InputEvent) -> void:
	if not warden_pattern_active or warden_pattern!="capture": return
	var screen_pos:=Vector2.ZERO
	var pressed:=false
	if event is InputEventMouseButton:
		pressed=event.pressed and event.button_index==MOUSE_BUTTON_LEFT
		screen_pos=event.position
	elif event is InputEventScreenTouch:
		pressed=event.pressed
		screen_pos=event.position
	if pressed:
		var world_pos:=get_viewport().get_canvas_transform().affine_inverse()*screen_pos
		hit_warden_orb(world_pos)

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
		damage_warden_stakes(origin,radius,damage)
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
	if warden_pattern_active and warden_pattern=="heart": warden_no_hit=false
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
		BagUtil.add(world.wallet["bag"],reward)
		var newly_unlocked := Progression.unlock_changgui_and_jangsan()
		message("장산범 처치 · "+str(reward["name"])+" 획득"+(" · 장산범 장비·창귀 심장 해금" if newly_unlocked else ""))
	elif enemy.kind=="soul-warden":
		end_warden_pattern(false)
		message("쇄혼대감 처치 · 퇴마단 주둔지의 봉인이 무너졌습니다")
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
	if heart_cd>0 or warden_heart_sealed: return
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
func slot_for_item(item: Dictionary, target := "") -> String:
	# 아이템이 들어갈 장착 칸. target이 있으면 그 칸에 맞는지 확인해 맞으면 target, 아니면 ""을 돌려준다.
	var slot: String = item["slot"]
	if slot=="accessory":
		if target!="": return target if target in ["a0","a1","a2","a3"] else ""
		for candidate in ["a0","a1","a2","a3"]:
			if equipment[candidate]=="": return candidate
		return "a0"
	if slot=="two": return "main" if target in ["","main"] else ""
	if target!="" and target!=slot: return ""
	return slot
func equip_bag(index: int, target := "") -> void:
	var bag: Array = world.wallet["bag"]
	if BagUtil.is_empty_slot(bag,index): return
	var item: Dictionary = DB.get_item(str(bag[index]["id"]))
	if item.is_empty(): return
	var slot:=slot_for_item(item,target)
	if slot=="": return
	var displaced: Array = []                      # 교체돼 가방으로 돌아가는 장비
	if item["slot"]=="two":
		for hand in ["main","off"]:
			if equipment[hand]!="": displaced.append(equipped(hand))
			equipment[hand]=""
	elif slot=="off" and DB.is_two(equipped("main")):
		displaced.append(equipped("main"))
		equipment["main"]=""
	if equipment[slot]!="": displaced.append(equipped(slot))
	bag[index]={}                                  # 방금 비운 칸에 교체된 장비를 우선 넣고, 남으면 앞의 빈 칸으로
	equipment[slot]=item["id"]
	for old in displaced:
		if (bag[index] as Dictionary).is_empty(): bag[index]=old
		else: BagUtil.add(bag,old)
	BagUtil.trim(bag)
	refresh_inventory()
func unequip(slot: String) -> void:
	if slot=="heart" or equipment.get(slot,"")=="": return
	BagUtil.add(world.wallet["bag"],equipped(slot))
	equipment[slot]=""
	refresh_inventory()
# 끌어서 놓기: source={"bag":i} 또는 {"equip":slot}, target도 같은 형식. dry=true면 가능 여부만 돌려준다.
func handle_drop(target: Dictionary, source: Dictionary, dry: bool) -> bool:
	var bag: Array = world.wallet["bag"]
	if source.has("bag") and target.has("bag"):
		var a:int=source["bag"]; var b:int=target["bag"]
		if a==b or BagUtil.is_empty_slot(bag,a): return false
		if not dry:
			BagUtil.swap(bag,a,b)
			inventory_selection=b
			refresh_inventory()
		return true
	if source.has("bag") and target.has("equip"):
		var i:int=source["bag"]
		if BagUtil.is_empty_slot(bag,i) or target["equip"]=="heart": return false
		var item: Dictionary = DB.get_item(str(bag[i]["id"]))
		if item.is_empty() or slot_for_item(item,str(target["equip"]))=="": return false
		if not dry: equip_bag(i,str(target["equip"]))
		return true
	if source.has("equip") and target.has("bag"):
		var slot:String=str(source["equip"]); var j:int=target["bag"]
		if slot=="heart" or equipment.get(slot,"")=="": return false
		if not BagUtil.is_empty_slot(bag,j):
			var occupant: Dictionary = DB.get_item(str(bag[j]["id"]))
			if occupant.is_empty() or slot_for_item(occupant,slot)=="": return false   # 같은 종류끼리만 맞바꾼다
		if not dry:
			var old:=equipped(slot)
			equipment[slot]=""
			if not BagUtil.is_empty_slot(bag,j):
				var incoming:Dictionary=bag[j]
				bag[j]=old
				equip_bag_into(incoming,slot)
			else:
				while bag.size()<=j: bag.append({})
				bag[j]=old
			inventory_selection=j
			refresh_inventory()
		return true
	return false
func equip_bag_into(item: Dictionary, slot: String) -> void:
	# 가방 밖으로 나온 아이템을 장착 칸에 바로 넣는다(맞바꾸기용). 양손 무기는 반대 손을 비운 뒤 주무기에 둔다.
	if item["slot"]=="two":
		for hand in ["main","off"]:
			if equipment[hand]!="": BagUtil.add(world.wallet["bag"],equipped(hand))
			equipment[hand]=""
		equipment["main"]=str(item["id"])
	else: equipment[slot]=str(item["id"])
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
	var button:=DragSlot.new()
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
	var test_heart_button:bool = slot=="heart" and world.full_test_run and not item.is_empty()
	button.tooltip_text=label_text+" · "+str(item.get("name","비어 있음"))+"\n"+str(item.get("effect",""))
	if test_heart_button: button.tooltip_text+="\n터치하여 다음 심장으로 변경"
	button.disabled=(item.is_empty() and slot=="heart") or (slot=="heart" and not test_heart_button)
	if test_heart_button:
		button.pressed.connect(func():
			world.cycle_full_test_heart(1)
			refresh_inventory())
	elif slot!="heart": button.pressed.connect(func():unequip(slot))
	if slot!="heart":
		button.drop_handler=func(source:Dictionary,dry:bool)->bool:return handle_drop({"equip":slot},source,dry)
		if not item.is_empty():
			button.payload={"equip":slot}
			button.preview_item=item
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

func restore_bag_scroll() -> void:
	if is_instance_valid(bag_scroll): bag_scroll.scroll_vertical=bag_scroll_value

func style_bag_scrollbar(scroll: ScrollContainer) -> void:
	# 잡기 쉬운 굵은 막대: 폭 14, 손잡이 최소 길이 32, 눌림·호버 색 구분, 휠 한 번에 한 줄(40px)씩 이동.
	var bar:=scroll.get_v_scroll_bar()
	bar.custom_minimum_size=Vector2(14,0)
	bar.custom_step=40.0
	var track:=inventory_style(Color("120c0a"),Color("4a2a22"),1,0)
	bar.add_theme_stylebox_override("scroll",track)
	bar.add_theme_stylebox_override("scroll_focus",track)
	for state in [["grabber",Color("8c5a36")],["grabber_highlight",Color("b57a48")],["grabber_pressed",Color("d9a05f")]]:
		var grab:=inventory_style(state[1],Color("2a1710"),1,0)
		grab.content_margin_top=16
		grab.content_margin_bottom=16
		bar.add_theme_stylebox_override(state[0],grab)

func autoscroll_bag_while_dragging(delta: float) -> void:
	# 아이템을 끌고 가방 위·아래 가장자리에 가면 목록이 자동으로 스크롤된다.
	if not is_instance_valid(bag_scroll) or not inventory.visible or not get_viewport().gui_is_dragging(): return
	var rect:=bag_scroll.get_global_rect()
	var mouse:=get_viewport().get_mouse_position()
	if not rect.grow(8).has_point(mouse): return
	var edge:=28.0
	if mouse.y<rect.position.y+edge: bag_scroll.scroll_vertical-=int(300.0*delta*(1.0-(mouse.y-rect.position.y)/edge))
	elif mouse.y>rect.end.y-edge: bag_scroll.scroll_vertical+=int(300.0*delta*(1.0-(rect.end.y-mouse.y)/edge))

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
	if is_instance_valid(bag_scroll): bag_scroll_value=bag_scroll.scroll_vertical      # 다시 그려도 스크롤 위치를 유지한다
	for child in inv_rows.get_children():
		inv_rows.remove_child(child)
		child.queue_free()
	var title_text := "테스트 · 심장 터치=변경" if world.full_test_run else "빌린 몸"
	var title:=inv_label(title_text,11 if world.full_test_run else 17,Color("2a1710"))
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
		var accessory_button:=DragSlot.new()
		accessory_button.custom_minimum_size=Vector2.ONE*accessory_rail.slot_size
		accessory_button.focus_mode=Control.FOCUS_NONE
		style_movable_slot(accessory_button,false)
		var accessory:=equipped(slot)
		if not accessory.is_empty(): add_slot_icon(accessory_button,accessory,accessory_rail.slot_size/42.0*.88)
		accessory_button.disabled=false
		accessory_button.drop_handler=func(source:Dictionary,dry:bool)->bool:return handle_drop({"equip":slot},source,dry)
		if not accessory.is_empty():
			accessory_button.payload={"equip":slot}
			accessory_button.preview_item=accessory
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
	scroll.scroll_deadzone=6
	scroll.add_theme_stylebox_override("panel",inventory_style(Color(0,0,0,0),Color(0,0,0,0),0,0))
	style_bag_scrollbar(scroll)
	bag_scroll=scroll
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
		var button:=DragSlot.new()
		button.custom_minimum_size=Vector2(cell[0],cell[1])
		button.focus_mode=Control.FOCUS_NONE
		style_movable_slot(button,i==inventory_selection)
		button.add_to_group("inventory_bag_slot")
		button.set_meta("bag_index",i)
		button.drop_handler=func(source:Dictionary,dry:bool)->bool:return handle_drop({"bag":i},source,dry)
		if not BagUtil.is_empty_slot(bag,i):
			add_slot_icon(button,bag[i],.72)
			button.tooltip_text=str(bag[i]["name"])+" "+attack_type_label(bag[i])+" / "+str(bag[i].get("effect",""))
			button.payload={"bag":i}
			button.preview_item=bag[i]
			button.pressed.connect(func():select_inventory(i))
			button.gui_input.connect(func(event:InputEvent):
				if event is InputEventMouseButton and event.double_click and event.button_index==MOUSE_BUTTON_LEFT: equip_bag(i))
		else:
			button.pressed.connect(func():select_inventory(i))
		grid.add_child(button)
	scroll.add_child(grid)
	inv_rows.add_child(scroll)
	restore_bag_scroll.call_deferred()
	if not get_tree().process_frame.is_connected(restore_bag_scroll): get_tree().process_frame.connect(restore_bag_scroll,CONNECT_ONE_SHOT)
	if not BagUtil.is_empty_slot(bag,inventory_selection):
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
		var empty_label:=inv_label("가방이 비어 있습니다. 장비는 가까이 가면 자동으로 획득합니다." if BagUtil.count(bag)==0 else "아이템을 눌러 선택하고, 끌어서 칸을 옮기거나 장착하세요.",14,Color("bcae91"))
		apply_inventory_rect(empty_label,"empty_hint")
		inv_rows.add_child(empty_label)
func destroy_confirmed() -> void:
	if pending_destroy>=0 and pending_destroy<world.wallet["bag"].size(): BagUtil.clear_slot(world.wallet["bag"],pending_destroy)
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
			for zone in zones.duplicate():
				if zone.get("kind","")=="warden-stake" and Geometry2D.get_closest_point_to_segment(Vector2(zone["pos"])+Vector2(0,-28),from,to).distance_to(Vector2(zone["pos"])+Vector2(0,-28))<24:
					damage_warden_stakes(Vector2(zone["pos"]),4,float(p["damage"]))
					p["life"]=0
					break
			if p["life"]<=0:
				projectiles.remove_at(i)
				continue
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
		if str(zone["kind"]).begins_with("enemy-") or zone["kind"]=="warden-talisman":
			zone["delay"]=float(zone.get("delay",0.0))-delta
			zone["hurt_cd"]=maxf(0.0,float(zone.get("hurt_cd",0.0))-delta)
			if float(zone["delay"])<=0:
				if zone["kind"] in ["enemy-arrow-rain","warden-talisman"] and not bool(zone["triggered"]):
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
					BagUtil.add(world.wallet["bag"],pickup["item"].duplicate(true))
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
func _process(delta: float) -> void:
	autoscroll_bag_while_dragging(delta)

func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(world.player): return
	visual_clock += delta
	if Input.is_action_just_pressed("inventory") and not confirm.visible and not (is_instance_valid(world.merchant) and world.merchant.opened): toggle_inventory()
	hit_pause=maxf(0,hit_pause-delta)
	paused=vfx_preview_paused or inventory.visible or (is_instance_valid(game_hud) and game_hud.settings_open) or world.floor_map_open or world.traveling or boss_transitioning or (is_instance_valid(world.merchant) and world.merchant.opened) or world.seed_input.has_focus() or hit_pause>0
	if paused: return
	var stagger_before:=warden_player_stagger
	warden_player_stagger=maxf(0.0,warden_player_stagger-delta)
	if stagger_before>0 and warden_player_stagger<=0:
		world.player.controls_enabled=true
	tick_warden_pattern(delta)
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
	var capture_aim_pressed:=Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("attack_left") or Input.is_action_just_pressed("attack_right") or Input.is_action_just_pressed("attack_up") or Input.is_action_just_pressed("attack_down")
	if warden_pattern_active and warden_pattern=="capture" and capture_aim_pressed:
		hit_warden_orb(world.player.position+Vector2(0,-28)+aim()*600.0,true)
	elif attack_input_held() and not world.in_village and not (warden_pattern_active and warden_pattern in ["capture","heart"]):
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
	game_hud.set_stats(health,max_health,BagUtil.count(world.wallet["bag"]),world.player.dash_charges,world.player.dash_max_charges)
	hud.text=""
	var heart:Dictionary=HeartDB.get_heart(str(equipment.get("heart","")))
	var heart_id:=str(equipment.get("heart",""))
	var skills:String=""
	if heart_id=="mongdal": skills="대시 "+str(world.player.dash_charges)+"/"+str(world.player.dash_max_charges)
	elif not heart_id.is_empty(): skills=str(heart.get("skill_name","심장"))+" "+("봉인" if warden_heart_sealed else "준비" if heart_cd<=0 else str(int(ceil(heart_cd)))+"초")
	for slot in ["main","off"]:
		if not str(equipped(slot).get("skill","")).is_empty() or (slot=="off" and duo_set()):
			if not skills.is_empty(): skills+="  |  "
			skills+=("주무기 " if slot=="main" else "보조무기 ")+("준비" if float(skill_cd[slot])<=0 else str(int(ceil(skill_cd[slot])))+"초")
	skill_bar.text=skills
	for enemy in living():
		if enemy.boss:
			var phase_text:=" · "+str(enemy.jangsan_phase)+"페이즈" if enemy.kind=="jangsanbeom" else ""
			var boss_name:="장산범" if enemy.kind=="jangsanbeom" else "쇄혼대감" if enemy.kind=="soul-warden" else "선봉대장"
			hud.text+=boss_name+" "+str(int(enemy.hp))+" / "+str(int(enemy.max_hp))+phase_text
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
		elif zone["kind"] in ["enemy-arrow-rain","warden-talisman"]:
			var warning_alpha:=.28 if float(zone.get("delay",0.0))>0 else .75
			var warning_color:=Color(0.45,0.32,0.52,warning_alpha) if zone["kind"]=="warden-talisman" else Color(0.76,0.32,0.24,warning_alpha)
			draw_line(Vector2(zone["pos"])+Vector2(-24,0),Vector2(zone["pos"])+Vector2(24,0),warning_color,3)
			draw_line(Vector2(zone["pos"])+Vector2(0,-180),Vector2(zone["pos"])+Vector2(0,-8),warning_color,2)
		elif zone["kind"]=="warden-stake":
			var stake_pos:Vector2=zone["pos"]
			draw_rect(Rect2(stake_pos+Vector2(-7,-58),Vector2(14,58)),Color("26242b"))
			draw_polygon(PackedVector2Array([stake_pos+Vector2(-13,-58),stake_pos+Vector2(0,-76),stake_pos+Vector2(13,-58)]),PackedColorArray([Color("665263")]))
			draw_rect(Rect2(stake_pos+Vector2(-16,-84),Vector2(32*float(zone["hp"])/float(zone["max_hp"]),4)),Color("8e5964"))
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
	if warden_pattern_active and warden_pattern=="capture" and not warden_orb.is_empty():
		var orb_pos:Vector2=warden_orb["pos"]
		var pulse:=2.0+sin(visual_clock*12.0)*2.0
		draw_circle(orb_pos,18+pulse,Color(0.12,0.1,0.16,.5))
		draw_arc(orb_pos,23+pulse,0,TAU,28,Color("8b7695"),3)
		for pip in range(4):
			draw_circle(orb_pos+Vector2((pip-1.5)*9,28),3,Color("b6a4bd") if pip<int(warden_orb["hits"]) else Color("3b3542"))

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
	if GEAR3_DROPS.has(id): return draw_gear3_drop(pickup, str(GEAR3_DROPS[id]))
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

func draw_gear3_drop(pickup: Dictionary, name: String) -> bool:
	var key := "gear3_" + name
	if not drop_info.has(key):
		var base := "res://assets/gear3/drop/" + name
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
