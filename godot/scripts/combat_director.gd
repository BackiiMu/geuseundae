extends Node2D
const DB = preload("res://scripts/equipment_db.gd")
const PixelVFX = preload("res://scripts/pixel_vfx.gd")
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
var hurt_timer := 0.0
var heart_cd := 0.0
var skill_cd := {"main":0.0,"off":0.0}
var attack_cd := {"main":0.0,"off":0.0}
var equipment: Dictionary = {"heart":"songaksi","main":"songaksi_hand","off":"","head":"","legs":"","feet":"","a0":"","a1":"","a2":"","a3":""}
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
var inventory: PanelContainer
var inv_rows: VBoxContainer
var confirm: ConfirmationDialog
var pending_destroy := -1
var inventory_selection := 0
var inventory_shade: ColorRect
var skill_bar: Label
var toast: Label
var toast_time := 0.0
var boss_test := false
var heart_pending: Array = []
var heart_windup := 0.0
var tooth_ammo := 8
var tooth_reload := 0.0
var hit_pause := 0.0
var attack_serial := 0
var visual_clock := 0.0
var drop_textures := {}
var drop_info := {}
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
	hud=Label.new()
	hud.position=Vector2(18,88)
	hud.add_theme_font_size_override("font_size",18)
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
	inventory=PanelContainer.new()
	inventory.position=Vector2(30,26)
	inventory.size=Vector2(708,380)
	var box:=StyleBoxFlat.new()
	box.bg_color=Color("17242e")
	box.border_color=Color("a8946d")
	box.set_border_width_all(2)
	box.content_margin_left=14
	box.content_margin_right=14
	box.content_margin_top=10
	box.content_margin_bottom=10
	inventory.add_theme_stylebox_override("panel",box)
	ui.add_child(inventory)
	inv_rows=VBoxContainer.new()
	inv_rows.add_theme_constant_override("separation",8)
	inventory.add_child(inv_rows)
	inventory.hide()
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
		spawn_enemy("boss",safe_ground(width*.45),0)
		message("퇴마단 선봉대장 · 적을 모두 처치하면 문이 열립니다")
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
			spawn_enemy((["warrior","warrior","adept"] if world.current_id==world.run.get("start",0) else ["warrior","adept","monk"])[i],pos,i)
func spawn_enemy(kind: String, pos: Vector2, uid: int) -> Node:
	var enemy=Enemy.new()
	enemy.kind=kind
	enemy.hp=420 if kind=="boss" else 60 if kind=="monk" else 20 if kind=="adept" else 30
	enemy.position=pos
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
	if has_passive("heal") and regen_cd<=0:
		health=minf(60,health+3)
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
		pickups.append({"kind":"chest" if rng.randf()<.6 else "item","item":item,"pos":safe_ground(float(world.room.definition["width"])*.5)+Vector2(0,-18)})
		message("방 클리어 · 중앙에 보상이 나타났습니다")
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
	var selected: Array = []
	for enemy in living():
		if visible_rect().has_point(enemy.position+Vector2(0,-25)): selected.append(enemy)
	if selected.is_empty(): return
	heart_pending.clear()
	for enemy in selected:
		if enemy.boss and enemy.state=="windup" and enemy.pattern==2: continue
		heart_pending.append(enemy)
		enemy.stun=maxf(enemy.stun,.3)
	vfx.emit("seal",3,world.player.position+Vector2(0,-30),Vector2.RIGHT,.85,Color("b6cccd"))
	heart_windup=.25
	heart_animation=1.1
	heart_cd=30
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
	if inventory.visible: refresh_inventory()
func inv_label(text: String,size:=14,color:=Color("dce4d4")) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label
func attack_type_label(item: Dictionary) -> String:
	if not item.has("kind"): return ""
	return "[근접]" if item["kind"]=="melee" else "[원거리]"
func refresh_inventory() -> void:
	for child in inv_rows.get_children():
		inv_rows.remove_child(child)
		child.queue_free()
	var heading:=HBoxContainer.new()
	heading.add_child(inv_label("빌린 몸과 가방",22,Color("dfc58c")))
	var spacer:=Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_child(spacer)
	heading.add_child(inv_label("영혼조각 ◆ "+str(world.wallet["souls"]),15,Color("a7d6bc")))
	var close:=Button.new()
	close.text="닫기 [Tab]"
	close.focus_mode=Control.FOCUS_NONE
	close.pressed.connect(toggle_inventory)
	heading.add_child(close)
	inv_rows.add_child(heading)
	var body:=HBoxContainer.new()
	body.add_theme_constant_override("separation",16)
	var equipped_list:=VBoxContainer.new()
	equipped_list.custom_minimum_size.x=286
	equipped_list.add_theme_constant_override("separation",2)
	equipped_list.add_child(inv_label("심장 · 손각시  /  HP 60",15,Color("b8d5c2")))
	for slot in equipment:
		if slot=="heart": continue
		var item:=equipped(slot)
		var button:=Button.new()
		button.text=DB.slot_name(slot)+" · "+str(item.get("name","비어 있음"))
		button.tooltip_text=attack_type_label(item)+" "+str(item.get("effect",""))+" / 클릭하면 해제"
		button.add_theme_font_size_override("font_size",13)
		button.custom_minimum_size=Vector2(286,22)
		button.clip_text=true
		button.focus_mode=Control.FOCUS_NONE
		button.disabled=item.is_empty()
		button.pressed.connect(func():unequip(slot))
		equipped_list.add_child(button)
	body.add_child(equipped_list)
	var bag_column:=VBoxContainer.new()
	bag_column.add_child(inv_label("소지품 · "+str(world.wallet["bag"].size())+"개",15))
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(370,218)
	var grid:=GridContainer.new()
	grid.columns=6
	grid.add_theme_constant_override("h_separation",5)
	grid.add_theme_constant_override("v_separation",5)
	var bag: Array=world.wallet["bag"]
	inventory_selection=clampi(inventory_selection,0,maxi(0,bag.size()-1))
	for i in range(maxi(18,bag.size())):
		var button:=Button.new()
		button.custom_minimum_size=Vector2(54,54)
		button.focus_mode=Control.FOCUS_NONE
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("26383e") if i==inventory_selection else Color("101c26")
		style.border_color=Color("d8bf85") if i==inventory_selection else Color("42585b")
		style.set_border_width_all(2)
		button.add_theme_stylebox_override("normal",style)
		if i<bag.size():
			var icon=preload("res://scripts/item_icon.gd").new()
			icon.item=bag[i]
			icon.position=Vector2(6,6)
			button.add_child(icon)
			button.tooltip_text=str(bag[i]["name"])+" "+attack_type_label(bag[i])+" / "+str(bag[i].get("effect",""))
			button.pressed.connect(func():inventory_selection=i;refresh_inventory())
		else: button.disabled=true
		grid.add_child(button)
	scroll.add_child(grid)
	bag_column.add_child(scroll)
	body.add_child(bag_column)
	inv_rows.add_child(body)
	var footer:=HBoxContainer.new()
	var description:=VBoxContainer.new()
	description.custom_minimum_size.x=460
	if not bag.is_empty():
		var item: Dictionary=bag[inventory_selection]
		description.add_child(inv_label(str(item["name"])+" · "+DB.slot_name(item["slot"])+" · "+str(item.get("tier",1))+"단계 "+attack_type_label(item),16,Color("d8c7a3")))
		var effect_label:=inv_label(str(item.get("effect","")),13)
		effect_label.custom_minimum_size.x=450
		effect_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		description.add_child(effect_label)
		var equip_button:=Button.new()
		equip_button.text="장착"
		equip_button.focus_mode=Control.FOCUS_NONE
		equip_button.custom_minimum_size=Vector2(94,42)
		equip_button.pressed.connect(func():equip_bag(inventory_selection))
		footer.add_child(description)
		footer.add_child(equip_button)
		var destroy:=Button.new()
		destroy.text="파기"
		destroy.focus_mode=Control.FOCUS_NONE
		destroy.custom_minimum_size=Vector2(94,42)
		destroy.pressed.connect(func():
			pending_destroy=inventory_selection
			confirm.dialog_text=str(item["name"])+" ("+str(item.get("tier",1))+"단계)\n영구 파기하면 복구할 수 없습니다."
			confirm.popup_centered(Vector2i(420,160))
			confirm.get_cancel_button().grab_focus())
		footer.add_child(destroy)
	else: footer.add_child(inv_label("가방이 비어 있습니다. 장비는 가까이 가면 자동으로 획득합니다.",14))
	inv_rows.add_child(footer)
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
		if p["life"]<=0: projectiles.remove_at(i)
func tick_zones(delta: float) -> void:
	for i in range(zones.size()-1,-1,-1):
		var zone:Dictionary=zones[i]
		zone["life"]-=delta
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
			pickup["kind"]="item"
			message("상자 개봉 · "+str(pickup["item"]["name"]))
			return true
	return false
func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(world.player): return
	visual_clock += delta
	if Input.is_action_just_pressed("inventory") and not confirm.visible and not (is_instance_valid(world.merchant) and world.merchant.opened): toggle_inventory()
	hit_pause=maxf(0,hit_pause-delta)
	paused=vfx_preview_paused or inventory.visible or world.floor_map_open or world.traveling or (is_instance_valid(world.merchant) and world.merchant.opened) or world.seed_input.has_focus() or hit_pause>0
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
	hud.text="HP "+str(int(health))+" / 60   영혼조각 "+str(world.wallet["souls"])+"   가방 "+str(world.wallet["bag"].size())+"개 [Tab]"
	var skills:="Q 심장 "+("준비" if heart_cd<=0 else str(int(ceil(heart_cd)))+"초")
	for slot in ["main","off"]:
		if not str(equipped(slot).get("skill","")).is_empty() or (slot=="off" and duo_set()):
			skills+="  |  "+("F 주무기 " if slot=="main" else "G 보조 ")+("준비" if float(skill_cd[slot])<=0 else str(int(ceil(skill_cd[slot])))+"초")
	skill_bar.text=skills+"  |  방향키 공격 · J/좌클릭 공격 · F6 장비시험"
	for enemy in living():
		if enemy.boss: hud.text+="\n선봉대장 "+str(int(enemy.hp))+" / "+str(int(enemy.max_hp))
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
		if not p["friendly"]: draw_line(p["pos"]-Vector2(p["velocity"]).normalized()*10,p["pos"],Color("e1b17c"),3)
	for zone in zones:
		if zone["kind"]=="decoy": draw_rect(Rect2(zone["pos"]-Vector2(13,46),Vector2(26,46)),Color(.6,.8,.75,.5))
	for effect in effects:
		if effect["color"]==Color("db9a73"): draw_arc(effect["pos"],effect["radius"],-.8,2.4,24,effect["color"],2)
	for pickup in pickups:
		var pos: Vector2=pickup["pos"]
		if pickup["kind"]=="souls":
			draw_polygon(PackedVector2Array([pos+Vector2(0,-8),pos+Vector2(5,0),pos+Vector2(0,8),pos+Vector2(-5,0)]),PackedColorArray([Color("a6dec3")]))
		elif pickup["kind"]=="chest":
			draw_rect(Rect2(pos-Vector2(16,12),Vector2(32,24)),Color("9d7750"))
			draw_rect(Rect2(pos-Vector2(3,12),Vector2(6,24)),Color("d5b16d"))
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
				draw_arc(to,18*enemy.size_factor,0,TAU,24,Color("879f96"),2)

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
	var source := Rect2(Vector2(frame % columns, frame / columns) * size, size)
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
	var source := Rect2(Vector2(frame % columns, frame / columns) * size, size)
	draw_texture_rect_region(drop_textures[key], Rect2(Vector2(pickup["pos"]) + Vector2(0,18) - pivot, size), source)
	return true
