extends SceneTree
func _initialize() -> void: call_deferred("run_checks")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func require(ok: bool,message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
		return false
	print("PASS: ",message)
	return true
func run_checks() -> void:
	var world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(30)
	world.set_process(false)
	world.toggle_equipment_lab()
	await frames(20)
	var c=world.combat
	c.set_physics_process(false)
	var p=world.player
	p.set_physics_process(false)
	var visual=p.visual
	for actor in [p]+c.living():
		var texture:Texture2D=actor.visual.texture
		if not require(texture!=null and texture.get_width()==1536 and texture.get_height()==1024,"32-frame raster atlas loads: "+actor.visual.role): return
	p.velocity=Vector2.ZERO
	visual.action_time=0
	visual._physics_process(.1)
	if not require(visual.frame_index<8,"Player idle chooses breathing row"): return
	p.velocity.x=200
	visual._physics_process(.1)
	if not require(visual.frame_index>=8 and visual.frame_index<16,"Player movement chooses run row"): return
	p.velocity=Vector2.ZERO
	visual.play_attack(.25)
	visual._physics_process(.05)
	if not require(visual.frame_index>=16 and visual.frame_index<24,"Player attack chooses action row"): return
	c.hurt_timer=.6
	visual._physics_process(.01)
	if not require(visual.frame_index>=30,"Player damage chooses hurt pose"): return
	c.hurt_timer=0
	p.dash_time=.1
	visual._physics_process(.01)
	if not require(visual.frame_index in [28,29],"Eight-direction dash uses its own pose"): return
	p.dash_time=0
	c.paused=true
	var before:float=visual.clock
	visual._physics_process(.5)
	if not require(visual.clock==before,"Inventory pause freezes animation clocks"): return
	c.paused=false
	for enemy in c.living():
		enemy.state="windup"
		enemy.timer=.3
		enemy.visual._physics_process(.01)
		if not require(enemy.visual.frame_index>=16 and enemy.visual.frame_index<=19,"Enemy anticipation pose: "+enemy.kind): return
		enemy.state="recover"
		enemy.timer=.3
		enemy.visual._physics_process(.01)
		if not require(enemy.visual.frame_index>=20 and enemy.visual.frame_index<=23,"Enemy strike/recovery pose: "+enemy.kind): return
		enemy.state="approach"
		enemy.timer=.1
	# Live third enemy's attack, using normal damage rules and real physics.
	var monk=c.living()[2]
	monk.training_dummy=false
	monk.max_hp=60
	monk.hp=60
	monk.position=Vector2(820,704)
	p.position=Vector2(755,704)
	p.velocity=Vector2.ZERO
	c.equipment_lab=false
	c.health=60
	c.hurt_timer=0
	await frames(110)
	if not require(c.health==48 and monk.attack==12 and monk.speed==65,"Moktak monk telegraphs then deals one heavy 12-damage hit"): return
	print("Actor visual and monk checks completed.")
	quit(0)
