extends SceneTree

const HeartDB=preload("res://scripts/heart_db.gd")

func _initialize() -> void: call_deferred("run_checks")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool,message: String) -> bool:
	if ok:
		print("PASS: ",message)
		return true
	push_error(message)
	quit(1)
	return false

func run_checks() -> void:
	var mongdal:Dictionary=HeartDB.get_heart("mongdal")
	var changgui:Dictionary=HeartDB.get_heart("changgui")
	if not check(mongdal["hp"]==90.0 and mongdal["skill_name"]=="" and mongdal["dash_charges"]==3,"Mongdal has 90 HP, no Q skill and three dash charges"): return
	if not check(changgui["hp"]==70.0 and changgui["skill_name"]=="창귀원혼","Changgui has 70 HP and the soul-bind skill"): return

	var world=load("res://scenes/random_run.tscn").instantiate()
	root.add_child(world)
	await frames(35)
	world.player.set_heart_role("mongdal",3)
	var mongdal_idle_heights:=[216.0,174.0,187.0,173.0,185.0,184.0,224.0,198.0]
	var mongdal_run_heights:=[173.0,160.0,177.0,147.0,140.0,141.0,157.0,165.0]
	for i in range(8):
		if not check(is_equal_approx(mongdal_idle_heights[i]*world.player.visual.new_heart_frame_metrics(i).z,185.0),"Mongdal idle frame "+str(i)+" keeps a fixed visible height"): return
		if not check(is_equal_approx(mongdal_run_heights[i]*world.player.visual.new_heart_frame_metrics(i+8).z,185.0),"Mongdal run frame "+str(i)+" matches the idle visible height"): return
	world.player.set_heart_role("changgui",1)
	var changgui_idle_heights:=[156.0,158.0,161.0,164.0,164.0,158.0,153.0,148.0]
	var changgui_run_heights:=[145.0,144.0,139.0,146.0,154.0,144.0,139.0,143.0]
	for i in range(8):
		if not check(is_equal_approx(changgui_idle_heights[i]*world.player.visual.new_heart_frame_metrics(i).z,158.0),"Changgui idle frame "+str(i)+" keeps a fixed visible height"): return
		if not check(is_equal_approx(changgui_run_heights[i]*world.player.visual.new_heart_frame_metrics(i+8).z,158.0),"Changgui run frame "+str(i)+" matches the idle visible height"): return
	world.player.set_heart_role("mongdal",3)
	for i in range(3):
		world.player.dash_cooldown=0
		world.player.start_dash(Vector2.RIGHT)
	if not check(world.player.dash_charges==0,"Mongdal can spend three consecutive dashes"): return
	world.player.dash_cooldown=0
	world.player.start_dash(Vector2.RIGHT)
	if not check(world.player.dash_charges==0,"A fourth dash is rejected until a charge regenerates"): return

	world.combat.equipment["heart"]="changgui"
	world.combat.heart_cd=0
	var targets:Array=world.combat.living()
	if not check(not targets.is_empty(),"Combat room provides targets for Changgui test"): return
	var before_fx:int=world.combat.vfx.bursts.size()
	world.combat.use_heart()
	for enemy in targets:
		if not check(enemy.stun>=3.99,"Changgui soul freezes every living enemy for four seconds"): return
	if not check(world.combat.vfx.bursts.size()==before_fx+targets.size(),"One blue Pixelfx soul attaches to every living enemy"): return
	if not check(world.combat.heart_cd==30.0,"Changgui soul starts its 30 second cooldown"): return
	var next_room:int=world.run["rooms"][world.current_id]["links"][0]
	world.change_room(next_room,world.current_id)
	await frames(3)
	if not check(world.player.visual.role=="changgui","Room changes preserve the current heart character appearance"): return
	print("Heart identity checks completed.")
	quit(0)
