extends SceneTree
const DB=preload("res://scripts/equipment_db.gd")
const HeartDB=preload("res://scripts/heart_db.gd")
var world
var c
func _initialize() -> void: call_deferred("run_checks")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool,message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
		return false
	print("PASS: ",message)
	return true
func prepare(id: String) -> void:
	world.reset_lab_targets()
	world.player.set_physics_process(false)
	world.player.position=Vector2(650,704)
	world.player.facing=1
	c.equipment={"heart":"songaksi","main":"","off":"","head":"","legs":"","feet":"","a0":"","a1":"","a2":"","a3":""}
	var item=DB.get_item(id)
	c.equipment["off" if item["slot"]=="off" else "main"]=id
	c.arsenal.counters.clear()
	for enemy in c.living():
		enemy.position.x=720+enemy.uid*65
		enemy.hp=10000
		enemy.max_hp=10000
	c.set_physics_process(false)
	c.paused=false
func run_checks() -> void:
	world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	world.set_process(false)
	var original_bag=world.wallet["bag"].duplicate(true)
	var original_max_health:float=world.combat.max_health
	world.toggle_equipment_lab()
	c=world.combat
	if not check(DB.weapons().size()==34 and DB.items().size()==43 and world.wallet["bag"].size()==43,"All 34 weapons and 9 passive items are available in lab"): return
	for heart_id in HeartDB.HEARTS:
		world.set_lab_heart(heart_id)
		var heart:=HeartDB.get_heart(heart_id)
		if not check(c.equipment["heart"]==heart_id and world.player.visual.role==heart["role"] and c.max_health==heart["hp"],"Lab can immediately switch to playable character: "+heart["name"]): return
	world.lab_index=0
	for i in range(DB.items().size()):
		world.cycle_lab(0 if i==0 else 1)
		var item:Dictionary=DB.items()[i]
		var equipped_ids:Array=c.equipment.values()
		if not check(equipped_ids.has(item["id"]),"Lab direct cycle equips catalog item: "+item["name"]): return
	world.set_lab_heart("songaksi")
	c.equipment={"heart":"songaksi","main":"","off":"","head":"","legs":"","feet":"","internal":"","a0":"","a1":"","a2":"","a3":""}
	var ids={}
	for item in DB.items():
		if not check(not ids.has(item["id"]) and not str(item["effect"]).is_empty(),"Unique item and effect: "+item["name"]): return
		ids[item["id"]]=true
	for w in DB.weapons():
		prepare(w[0])
		var slot="off" if w[2]=="off" else "main"
		if w[2]=="off" and not check(float(w[5])>0,"Off-hand weapon has a visible basic attack: "+w[0]): return
		if float(w[5])>0:
			c.perform_attack(slot)
			c.arsenal.tick(.31)
			if not check(c.attack_cd[slot]>0,"Basic attack dispatch: "+w[0]): return
		if w[8]!="":
			if w[0]=="mouth": c.arsenal.swallowed=3
			c.use_skill(slot)
			if not check(c.skill_cd[slot]>0,"Active skill dispatch: "+w[0]): return
		c.tick_projectiles(.02)
		c.tick_zones(.02)
	prepare("hair")
	var foe=c.living()[0]
	for i in range(3): c.perform_attack("main")
	if not check(foe.stun>0,"Hair third attack binds"): return
	prepare("nails")
	for i in range(4): c.perform_attack("main")
	if not check(c.arsenal.combo>=4 and c.attack_cd["main"]<.2,"Nails accelerate on actual consecutive hits"): return
	prepare("fist")
	foe=c.living()[0]
	c.perform_attack("main")
	if not check(foe.hp==10000,"Fist does not damage during windup"): return
	c.arsenal.tick(.31)
	if not check(foe.hp==9970 and c.hit_pause>0,"Fist lands 30 damage after windup with hit stop"): return
	prepare("water_hand")
	c.perform_attack("off")
	if not check(c.living()[0].slow>0 and c.living()[0].stun==0,"Water hand slows rather than permanent stun lock"): return
	prepare("gaze")
	c.perform_attack("main")
	if not check(c.arsenal.beam_time>0 and c.living()[0].slow>0,"Held gaze creates a real slowing beam"): return
	prepare("goose")
	c.perform_attack("main")
	c.tick_projectiles(.16)
	var before:float=c.living()[0].hp
	c.projectiles[0]["age"]=.5
	c.projectiles[0]["pos"]=Vector2(790,676)
	c.tick_projectiles(.16)
	if not check(c.living()[0].hp<before,"Goose can hit same enemy on return leg"): return
	prepare("tooth")
	for i in range(8): c.perform_attack("main")
	var count=c.projectiles.size()
	c.perform_attack("main")
	if not check(c.tooth_reload>0 and c.projectiles.size()==count,"Eight teeth then reload blocks firing"): return
	prepare("mirror")
	foe=c.living()[0]
	c.arsenal.hit(foe,12,"mirror")
	var before_hit:float=foe.hp
	foe.take_damage(10)
	if not check(before_hit-foe.hp==15 and foe.vulnerable==0,"Jokduri marks exactly one amplified next hit"): return
	prepare("tiger_soul")
	foe=c.living()[0]
	foe.take_damage(20000)
	if not check(c.arsenal.spirits.size()==1,"Killed soul joins the companion group"): return
	prepare("belt")
	c.perform_attack("main")
	foe=c.living()[0]
	if not check(foe.throw_remaining>0,"Belt physically throws a surviving enemy"): return
	await frames(18)
	if not check(c.living().any(func(e):return e.hp<9982),"Thrown enemy collision deals extra damage"): return
	prepare("mouth")
	foe=c.living()[0]
	foe.hp=10
	c.perform_attack("main")
	if not check(c.arsenal.swallowed==1,"Mouth stores swallowed kill"): return
	c.use_skill("main")
	if not check(c.projectiles.size()==1 and c.arsenal.swallowed==0,"Spit spends stored enemy count"): return
	prepare("fox_mirror")
	c.use_skill("off")
	var zone=c.zones[0]
	c.area_effect(zone["pos"]+Vector2(0,-23),50,20,c.living()[0])
	c.tick_zones(.02)
	if not check(c.zones.is_empty(),"Enemy strike breaks the decoy and triggers its explosion"): return
	prepare("fist")
	c.equipment["head"]="duo_head"
	c.equipment["a0"]="duo_curse"
	c.use_skill("off")
	if not check(c.duo_set() and c.skill_cd["off"]>0,"Three-piece two-hand set exposes its offhand skill"): return
	prepare("water_bucket")
	c.perform_attack("main")
	for i in range(80): c.tick_projectiles(.02)
	if not check(c.zones.any(func(z):return z["kind"]=="water"),"Water projectile survives its arc and creates a puddle"): return
	prepare("hair")
	c.living()[0].position.x=810
	c.perform_attack("main")
	var health_before:float=c.living()[0].hp
	c.equipment["head"]="wig"
	c.perform_attack("main")
	if not check(c.living()[0].hp<health_before,"Wig extends hair to an otherwise unreachable target"): return
	prepare("fist")
	c.living()[0].position.x=810
	c.equipment["head"]="duo_head"
	c.perform_attack("main")
	c.arsenal.tick(.31)
	if not check(c.living()[0].hp<10000,"Duo head increases melee reach"): return
	prepare("pin")
	c.equipment["head"]="duo_head"
	c.perform_attack("main")
	if not check(c.projectiles[0]["size"]==1.5,"Duo head increases projectile collision and drawn size"): return
	prepare("fist")
	c.equipment["a0"]="duo_curse"
	c.world.player.dash_direction=Vector2.RIGHT
	c.world.player.dash_time=.1
	c.previous_dash=false
	c._physics_process(.016)
	if not check(is_equal_approx(c.living()[0].hp,9968.5),"Curse multiplies 0.7x melee dash into 31.5 damage"): return
	c.world.player.dash_time=0
	prepare("hair")
	c.equipment["legs"]="bent_leg"
	c._physics_process(.016)
	if not check(is_equal_approx(c.world.player.movement_multiplier,1.12),"Bent leg changes movement speed"): return
	c.equipment["legs"]="mongdal_legs"
	c.living()[0].take_damage(20000)
	c._physics_process(.016)
	c.perform_attack("main")
	if not check(c.world.player.movement_multiplier>1 and c.attack_cd["main"]<.45,"Mongdal leg grants movement and attack speed after a kill"): return
	prepare("hair")
	c.equipment["feet"]="wet_shoes"
	c.previous_dash=false
	c.world.player.dash_time=.1
	c._physics_process(.016)
	if not check(c.zones.any(func(z):return z["kind"]=="water"),"Wet shoes leave a slowing trail on dash"): return
	c.world.player.dash_time=0
	prepare("hair")
	c.equipment["a0"]="stomach"
	c.health=40
	c.regen_cd=0
	c.living()[0].take_damage(20000)
	if not check(c.health==43,"Stomach heals on kill"): return
	world.toggle_equipment_lab()
	if not check(world.in_village and world.wallet["bag"]==original_bag and c.max_health==original_max_health and not c.equipment_lab,"Leaving lab restores original inventory, health and run"): return
	world.start_full_test_run()
	if not check(world.full_test_run and not c.equipment_lab and not world.in_village and world.run["rooms"].size()>1,"Full unlock test starts a real seeded multi-room run"): return
	if not check(world.wallet["bag"].size()==DB.items().size() and world.wallet["souls"]==9999,"Full unlock run starts with every item and test currency"): return
	for heart_id in HeartDB.HEARTS:
		world.set_lab_heart(heart_id)
		if not check(c.equipment["heart"]==heart_id and world.player.visual.role==HeartDB.get_heart(heart_id)["role"],"Full unlock run can switch playable character: "+HeartDB.display_name(heart_id)): return
	world.set_lab_heart("songaksi")
	c.refresh_inventory()
	var test_heart_buttons:Array=c.get_tree().get_nodes_in_group("inventory_heart_slot").filter(func(button): return not button.disabled)
	if not check(test_heart_buttons.size()==1,"Full unlock inventory exposes a touch heart switch button"): return
	test_heart_buttons[0].pressed.emit()
	if not check(c.equipment["heart"]!="songaksi","Touch heart switch changes playable character during the real run"): return
	print("All equipment behavior checks completed.")
	quit(0)
