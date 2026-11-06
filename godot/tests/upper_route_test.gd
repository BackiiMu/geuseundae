extends SceneTree
const Catalog = preload("res://scripts/room_catalog.gd")
func _initialize() -> void: call_deferred("run_checks")
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func fail(message: String) -> void:
	push_error(message)
	quit(1)
func run_checks() -> void:
	var main = load("res://scenes/random_run.tscn").instantiate()
	main.combat_enabled=false
	root.add_child(main)
	await frames(35)
	main.set_process(false)
	for key in Catalog.templates():
		var def: Dictionary = Catalog.templates()[key]
		main.run = {"version":3,"seed":1,"start":0,"goal":1,"rooms":[{"id":0,"template":key,"links":[1],"grid":[0,1],"decor_seed":1,"visited":false},{"id":1,"template":"gate","links":[0],"grid":[0,0],"decor_seed":1,"visited":false}]}
		main.change_room(0,-1)
		await frames(35)
		var p = main.player
		var top: Array = def["platforms"][0]
		for platform in def["platforms"]:
			if platform[1]<top[1]: top=platform
		var route: Array = []
		for platform in def["platforms"]:
			if platform[0]<=top[0]: route.append(platform)
		var current_right := float(def["width"])
		var current_y := 704.0
		for target in route:
			var launch := minf(float(target[0])-70,current_right-18)
			Input.action_press("move_right")
			for tick in range(500):
				if p.position.x>=launch: break
				await frames(1)
			Input.action_press("jump")
			var landed := false
			for tick in range(100):
				# Several authored upper ledges sit above the 450 jump's physical
				# apex. Exercise the intended upward dash for those tall steps.
				if tick==8 and current_y-float(target[1])>145:
					p.dash_cooldown=0
					p.dash_charges=maxi(1,p.dash_charges)
					Input.action_press("aim_up")
					Input.action_press("dash")
				if tick==10:
					Input.action_release("dash")
					Input.action_release("aim_up")
				# Brake inside the destination, without using a dash or another jump.
				if p.position.x>target[0]+target[2]-35: Input.action_release("move_right")
				await frames(1)
				if tick>5 and p.is_on_floor():
					landed = absf(p.position.y-float(target[1]))<3
					break
			Input.action_release("jump")
			Input.action_release("move_right")
			await frames(10)
			if not landed:
				fail("Upper route failed "+key+" target "+str(target)+" actual "+str(p.position))
				return
			current_right=float(target[0]+target[2])
			current_y=float(target[1])
		var portal: Vector2 = main.portal_position(0,1)
		# Walk along the top balcony to its portal, then return to lower ground.
		Input.action_press("move_right" if p.position.x<portal.x else "move_left")
		for tick in range(250):
			if absf(p.position.x-portal.x)<20: break
			await frames(1)
		Input.action_release("move_right")
		Input.action_release("move_left")
		await frames(10)
		if p.position.distance_to(portal)>60:
			fail("Cannot reach upper portal "+key)
			return
		# Return from the upper portal to the right-side exit without using dash.
		Input.action_press("move_right")
		var previous_x: float = p.position.x
		var reset_count := 0
		for tick in range(700):
			var near_gap := false
			for gap in def["gaps"]:
				if p.position.x>gap[0]-72 and p.position.x<gap[0]+gap[1]+28: near_gap=true
			if near_gap: Input.action_press("jump")
			else: Input.action_release("jump")
			await frames(1)
			if p.position.x<previous_x-100: reset_count+=1
			previous_x=p.position.x
		Input.action_release("move_right")
		Input.action_release("jump")
		await frames(65)
		if p.position.x<float(def["width"])-110 or not p.is_on_floor() or reset_count>0:
			fail("Cannot return from upper portal to exit "+key)
			return
		print("PASS jump/up-dash ascent + return to exit ",key)
	print("All upper portal routes are reachable with the standard movement kit.")
	quit(0)
