extends SceneTree
func _initialize() -> void: call_deferred("run_checks")
func run_checks() -> void:
	var world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	world.set_process(false)
	world.toggle_equipment_lab()
	var c=world.combat
	var fx=c.vfx
	assert(fx.manifest.size()==24)
	assert(fx.manifest.has("dash-2"))
	for key in fx.manifest:
		var info:Dictionary=fx.manifest[key]
		assert(fx.textures[key]!=null)
		if key=="dash-2":
			assert(int(info["frames"])==14 and int(info["fps"])==30)
		else:
			assert(int(info["frames"])==19 and int(info["fps"])==25)
		assert(fx.textures[key].get_width()>=int(info["frameSize"][0])*int(info["columns"]))
	print("PASS: all 24 pixelfx sheets load with valid frame sizes and pivots")
	for tier in range(1,5):
		fx.clear()
		fx.attack({"id":"songaksi_hand","tier":tier,"kind":"melee","set":"songaksi"},Vector2(650,676),Vector2.RIGHT,84)
		assert(fx.bursts[0]["key"]=="slash-"+str(tier))
	print("PASS: each equipment grade selects its matching animation")
	fx.clear()
	fx.attack({"id":"hair","tier":2,"kind":"melee","set":"songaksi"},Vector2(650,676),Vector2.RIGHT,128)
	assert(fx.bursts[0]["provided"]=="hair-lash")
	assert(fx.bursts[0]["follow_player"])
	var before: Vector2=fx.bursts[0]["pos"]
	world.player.position += Vector2(40,0)
	fx._physics_process(.01)
	assert(Vector2(fx.bursts[0]["pos"]).is_equal_approx(before+Vector2(40,0)))
	assert(not fx.PROVIDED_ATTACKS.has("fist"))
	fx.clear()
	fx.attack({"id":"pin","tier":2,"kind":"ranged","set":"songaksi"},Vector2(650,676),Vector2.RIGHT,128)
	assert(not fx.bursts[0].get("follow_player",false))
	print("PASS: melee VFX follows the moving player while ranged VFX stays launched")
	fx.clear()
	fx.attack({"id":"songaksi_hand","tier":1,"kind":"melee","set":"songaksi"},Vector2(650,676),Vector2.RIGHT,84)
	assert(not fx.bursts[0].has("gear2") and fx.bursts[0]["key"]=="slash-1")
	fx.clear()
	fx.attack({"id":"eggshell","tier":1,"kind":"ranged","set":"egg"},Vector2(650,676),Vector2.RIGHT,300)
	assert(fx.bursts[0]["gear2"]=="eggshell-cast")
	fx.clear()
	fx.cast({"id":"ribbon","tier":2,"kind":"melee","set":"songaksi"},Vector2(650,676),Vector2.RIGHT,"pull")
	assert(fx.bursts[0]["gear2"]=="broken-ribbon" and fx.bursts[0]["follow_player"])
	for name in ["blank-face","jokduri-cast","jokduri-shot","jokduri-hit","eggshell-shot","eggshell-hit","hollow-gaze-beam"]:
		assert(not fx.load_gear2(name).is_empty() and fx.gear2_textures[name]!=null)
	assert(c.GEAR2_DROPS.size()==14)
	assert(preload("res://scripts/item_icon.gd").GEAR2_ITEMS.size()==14)
	print("PASS: gear2 icons/drops and split cast-shot-hit sheets load; Songaksi hand keeps old attack VFX")
	fx.clear()
	fx.heavy(Vector2(650,676),Vector2.LEFT,"fist")
	assert(fx.bursts[0]["key"]=="fist-4" and is_equal_approx(fx.bursts[0]["angle"],PI))
	for i in range(80): fx.emit("impact",4,Vector2.ZERO)
	assert(fx.bursts.size()==40)
	c.paused=true
	var age:float=fx.bursts[0]["age"]
	fx._physics_process(.3)
	assert(fx.bursts[0]["age"]==age)
	c.paused=false
	fx._physics_process(1)
	assert(fx.bursts.is_empty())
	print("PASS: left-facing effects, burst cap, pause and one-shot cleanup")
	world.toggle_equipment_lab()
	assert(fx.bursts.is_empty() and not c.equipment_lab)
	print("PASS: room transitions clear visual leftovers")
	quit(0)
