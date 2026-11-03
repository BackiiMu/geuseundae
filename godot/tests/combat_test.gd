extends SceneTree
const DB=preload("res://scripts/equipment_db.gd")
const Stock=preload("res://scripts/merchant_stock.gd")
func _initialize() -> void: call_deferred("run_checks")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func check(ok: bool,text: String) -> bool:
	if not ok:
		push_error(text)
		quit(1)
		return false
	print("PASS: ",text)
	return true
func run_checks() -> void:
	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	await frames(40)
	world.set_process(false)
	var combat=world.combat
	combat.set_physics_process(false)
	combat.paused=true
	if not check(combat.living().size()>0 and combat.locked(),"Combat room spawns temporary enemies and locks portals"): return
	combat.hurt_timer=0
	combat.hurt(8)
	combat.hurt(8)
	if not check(combat.health==52,"Hurt immunity prevents simultaneous double damage"): return
	for enemy in combat.living(): enemy.take_damage(1000)
	if not check(not combat.enemies[0].visible,"Dead enemies disappear rather than retain attack telegraphs"): return
	if not check(world.room.z_index<combat.z_index,"Room art renders behind combat actors"): return
	if not check(combat.data.get("cleared",false) and not combat.locked(),"Kills clear room and unlock portals"): return
	var rewards:=0
	for pickup in combat.pickups:
		if pickup["kind"] in ["chest","item"]: rewards+=1
	if not check(rewards==1,"Room awards exactly one clear reward"): return
	var id: int=world.current_id
	world.change_room(world.run["shop_room"],-1)
	world.change_room(id,-1)
	if not check(combat.living().is_empty() and combat.pickups.size()>0,"Revisit preserves cleared state and unclaimed drops"): return
	world.player.set_physics_process(false)
	world.player.position=Vector2(700,704)
	combat.pickups=[{"kind":"souls","amount":3,"pos":Vector2(700,684)}]
	var before:int=world.wallet["souls"]
	combat.tick_pickups(.1)
	combat.tick_pickups(.1)
	if not check(world.wallet["souls"]==before+3 and combat.pickups.is_empty(),"Soul magnet credits once"): return
	var bag_before:int=world.wallet["bag"].size()
	combat.pickups=[{"kind":"item","item":DB.get_item("fist"),"pos":Vector2(700,684)}]
	combat.tick_pickups(.1)
	if not check(world.wallet["bag"].size()==bag_before+1,"Equipment magnet delivers to bag without auto equip"): return
	combat.equip_bag(world.wallet["bag"].size()-1)
	if not check(combat.equipment["main"]=="fist" and combat.equipment["off"]=="","Two-hand weapon occupies both hands"): return
	world.wallet["bag"].append(DB.get_item("water_hand"))
	combat.equip_bag(world.wallet["bag"].size()-1)
	if not check(combat.equipment["main"]=="" and combat.equipment["off"]=="water_hand","Offhand swap returns two-hand weapon to bag"): return
	for accessory in ["stomach","duo_curse"]:
		world.wallet["bag"].append(DB.get_item(accessory))
		combat.equip_bag(world.wallet["bag"].size()-1)
	if not check(combat.equipment["a0"]=="stomach" and combat.equipment["a1"]=="duo_curse","Accessory slots accept independent equipment"): return
	bag_before=world.wallet["bag"].size()
	combat.pending_destroy=0
	combat.confirm.canceled.emit()
	if not check(world.wallet["bag"].size()==bag_before,"Cancel destruction keeps item"): return
	combat.pending_destroy=0
	combat.destroy_confirmed()
	if not check(world.wallet["bag"].size()==bag_before-1,"Confirmed destruction removes only one bag item"): return
	# Instantiate every weapon and execute its primary/skill path to catch invalid data or dispatch.
	for weapon in DB.weapons():
		var slot: String="off" if weapon[2]=="off" else "main"
		combat.equipment[slot]=weapon[0]
		combat.skill_cd[slot]=0.0
		combat.perform_attack(slot)
		combat.use_skill(slot)
	combat.tick_projectiles(.01)
	combat.tick_zones(.01)
	if not check(DB.weapons().size()>=31,"All weapon candidate profiles dispatch without errors"): return
	world.change_room(world.run["goal"],-1)
	combat.paused=true
	world.player.set_physics_process(false)
	world.player.position=Vector2(800,704)
	world.player.camera.position_smoothing_enabled=false
	world.player.camera.force_update_scroll()
	await frames(2)
	var boss=combat.living()[0]
	if not check(boss.boss and boss.max_hp==420 and boss.size_factor==1.5,"Boss arena spawns 420 HP leader at 1.5x scale"): return
	boss.position=Vector2(900,704)
	for pattern in range(3):
		boss.pattern=pattern
		boss.attack_direction=Vector2.LEFT
		boss.release_attack(world.player.position+Vector2(0,-23))
	if not check(combat.projectiles.size()>=5,"Boss ranged fan and shockwave patterns emit attacks"): return
	combat.heart_cd=0
	boss.state="approach"
	combat.use_heart()
	if not check(combat.heart_cd==30 and combat.heart_pending.has(boss),"Heart skill targets visible boss and starts 30-second cooldown"): return
	boss.pull_to(Vector2(860,704),.7)
	if not check(boss.pull_remaining>0,"Hair gather uses moving pull rather than teleport"): return
	boss.pull_remaining=0
	combat.fire_projectile(world.player.position,Vector2.RIGHT,12,false,"wave",boss)
	boss.take_damage(1000)
	var clear_health:float=combat.health
	combat.hurt_timer=0
	combat.hurt(100)
	if not check(combat.health==clear_health,"Lingering enemy attacks cannot kill player after room clear"): return
	if not check(not combat.locked() and combat.data["cleared"],"Boss defeat unlocks floor exit and reward"): return
	world.change_room(world.run["shop_room"],-1)
	if not check(combat.living().is_empty(),"Peace room never spawns enemies"): return
	world.wallet["souls"]=200
	var purchase: int=world.wallet["bag"].size()
	Stock.buy(world.merchant.stock,0,world.wallet)
	if not check(world.wallet["bag"].size()==purchase+1,"Earned-currency purchase enters the same equipment bag"): return
	print("Combat integration checks completed.")
	quit(0)
