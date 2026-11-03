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
	assert(fx.manifest.size()==23)
	for key in fx.manifest:
		var info:Dictionary=fx.manifest[key]
		assert(fx.textures[key]!=null)
		assert(int(info["frames"])==19 and int(info["fps"])==25)
		assert(fx.textures[key].get_width()>=int(info["frameSize"][0])*int(info["columns"]))
	print("PASS: all 23 pixelfx sheets load with valid frame sizes and pivots")
	for tier in range(1,5):
		fx.clear()
		fx.attack({"id":"hair","tier":tier,"kind":"melee","set":"songaksi"},Vector2(650,676),Vector2.RIGHT,128)
		assert(fx.bursts[0]["key"]=="slash-"+str(tier))
	print("PASS: each equipment grade selects its matching animation")
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
