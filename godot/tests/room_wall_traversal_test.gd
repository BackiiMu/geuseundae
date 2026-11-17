extends SceneTree

const Catalog = preload("res://scripts/room_catalog.gd")

func _initialize() -> void:
	call_deferred("run_checks")

func frames(count: int) -> void:
	for i in range(count): await physics_frame

func fail(message: String) -> void:
	push_error(message)
	quit(1)

func run_checks() -> void:
	var main=load("res://scenes/random_run.tscn").instantiate()
	main.combat_enabled=false
	root.add_child(main)
	await frames(35)
	for key in ["collapsed_house","rotten_bridge","ritual_yard"]:
		var definition:Dictionary=Catalog.templates()[key]
		main.run={"version":3,"seed":1,"start":0,"goal":0,"rooms":[{"id":0,"template":key,"links":[],"grid":[0,0],"decor_seed":1,"visited":false}]}
		main.change_room(0,-1)
		await frames(35)
		var player=main.player
		var previous_x:float=player.position.x
		var resets:=0
		Input.action_press("move_right")
		for tick in range(900):
			var jump_now:=false
			for gap in definition["gaps"]:
				if player.position.x>gap[0]-72 and player.position.x<gap[0]+gap[1]+28: jump_now=true
			for wall in definition["walls"]:
				if player.position.x>wall[0]-82 and player.position.x<wall[0]+wall[2]+28: jump_now=true
			if jump_now: Input.action_press("jump")
			else: Input.action_release("jump")
			await frames(1)
			if player.position.x<previous_x-100: resets+=1
			previous_x=player.position.x
		Input.action_release("move_right")
		Input.action_release("jump")
		await frames(60)
		if player.position.x<float(definition["width"])-110 or not player.is_on_floor() or resets>0:
			fail("Wall room cannot be traversed: "+key+" pos="+str(player.position))
			return
		print("PASS wall-room traversal ",key)
	print("All representative wall rooms remain traversable with the standard movement kit.")
	quit(0)
