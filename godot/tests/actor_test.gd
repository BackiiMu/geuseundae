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
	var adept=c.living()[1]
	if not require(is_equal_approx(adept.windup_duration(),1.1) and is_equal_approx(adept.recovery_duration(),1.5),"Early ranged enemy cycle doubles to 2.6 seconds with a longer telegraph"): return
	var warrior=c.living().filter(func(enemy): return enemy.kind=="warrior")[0]
	var early_monk=c.living().filter(func(enemy): return enemy.kind=="monk")[0]
	if not require(is_equal_approx(warrior.windup_duration()+warrior.recovery_duration(),2.0),"Early warrior attack cycle leaves a readable two-second gap"): return
	if not require(is_equal_approx(early_monk.windup_duration()+early_monk.recovery_duration(),2.25),"Early monk attack cycle leaves a readable recovery window"): return
	for actor in [p]+c.living():
		var texture:Texture2D=actor.visual.texture
		if not require(texture!=null and texture.get_width()==1536 and texture.get_height()==1024,"32-frame raster atlas loads: "+actor.visual.role): return
	p.velocity=Vector2.ZERO
	visual.action_time=0
	visual._physics_process(.1)
	if not require(visual.frame_index<8,"Player idle chooses breathing row"): return
	p.position=Vector2(650,500)
	p.velocity=Vector2(0,-100)
	p.move_and_slide()
	visual._physics_process(.1)
	if not require(visual.frame_index==25,"Jump ascent holds the tucked-leg pose"): return
	p.velocity.y=100
	visual._physics_process(.1)
	if not require(visual.frame_index==25,"Jump descent keeps the same tucked-leg pose"): return
	p.position=Vector2(650,704)
	p.velocity=Vector2(200,10)
	p.move_and_slide()
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
	if not require(visual.dash_fx_texture!=null and visual.dash_fx_age<.1 and visual.dash_trail_time>0,"Dash starts the pixelfx trail and translucent body echoes"): return
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
