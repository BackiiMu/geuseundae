extends SceneTree
const Generator = preload("res://scripts/run_generator.gd")
const Catalog = preload("res://scripts/room_catalog.gd")
func _initialize() -> void:
	call_deferred("run_checks")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
func require(ok: bool,message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
	return ok
func run_checks() -> void:
	if not require(Catalog.templates().size()==20,"Chapter 1 must provide exactly twenty room types"): return
	var signatures: Dictionary = {}
	var counts: Dictionary = {}
	for seed_value in range(200):
		var generated := Generator.generate(seed_value)
		if not require(Generator.validate(generated),"Invalid graph seed %s"%seed_value): return
		if not require(JSON.stringify(generated)==JSON.stringify(Generator.generate(seed_value)),"Non-deterministic seed"): return
		var selected_templates: Dictionary = {}
		for data in generated["rooms"]: selected_templates[data["template"]]=true
		if not require(selected_templates.size()==generated["rooms"].size(),"A floor must sample unique room types"): return
		if not require(generated["rooms"][generated["goal"]]["template"]=="sanctum","Boss room must reserve the sanctum"): return
		for data in generated["rooms"]:
			var n: int = data["links"].size()
			counts[n] = int(counts.get(n,0))+1
			if not require(n>=1 and n<=4,"Portal count outside 1..4"): return
		var cells: Array = []
		for data in generated["rooms"]:
			if not require(not cells.has(data["grid"]),"Overlapping map cells"): return
			cells.append(data["grid"])
		signatures[JSON.stringify(generated)] = true
	if not require(counts.size()==4,"Portal counts 1 to 4 must all occur"): return
	print("PASS: 200 deterministic connected graphs, portal counts: ",counts)
	var main = load("res://scenes/random_run.tscn").instantiate()
	main.combat_enabled=false
	root.add_child(main)
	await frames(40)
	for value in range(200):
		main.run = Generator.generate(value)
		for data in main.run["rooms"]:
			var points: Array[Vector2] = []
			for next in data["links"]:
				var point: Vector2 = main.portal_position(data["id"],next)
				for other in points:
					if not require(point.distance_to(other)>=320,"Portals too close in "+str(data["template"])+" seed "+str(value)+": "+str(point)+" / "+str(other)): return
				points.append(point)
	print("PASS: every portal pair separated by at least 320 pixels across 200 seeds")
	if not require(main.player.is_on_floor(),"Spawn settles on safe floor"): return
	for template in Catalog.templates():
		main.run = {"version":1,"seed":1103,"start":0,"goal":0,"rooms":[{"id":0,"template":template,"links":[],"grid":[0,1],"decor_seed":7,"visited":false}]}
		main.change_room(0,-1)
		await frames(35)
		if not require(not main.complete,"One-room stage must not complete at spawn"): return
		var p = main.player
		Input.action_press("move_right")
		var resets := 0
		var previous_x: float = p.position.x
		var gaps: Array = Catalog.templates()[template]["gaps"]
		for tick in range(480):
			var near_gap := false
			for gap in gaps:
				if p.position.x>gap[0]-72 and p.position.x<gap[0]+gap[1]+28:
					near_gap = true
			if near_gap: Input.action_press("jump")
			else: Input.action_release("jump")
			await frames(1)
			if p.position.x<previous_x-100: resets+=1
			previous_x = p.position.x
		Input.action_release("jump")
		Input.action_release("move_right")
		await frames(75)
		var width: int = Catalog.templates()[template]["width"]
		if not require(p.position.x>width-110 and p.is_on_floor() and resets==0,"Failed traversal "+template): return
		p.position=main.floor_exit_position
		await frames(2)
		Input.action_press("interact")
		await frames(2)
		Input.action_release("interact")
		if not require(main.complete,"Exit interaction did not complete stage"): return
		main.complete = false
		print("PASS: traversal + exit ",template)
	for seed_value in range(20):
		main.new_run(seed_value)
		for source in range(main.run["rooms"].size()):
			var links: Array = main.run["rooms"][source]["links"].duplicate()
			for destination in links:
				main.change_room(destination,source)
				await frames(35)
				if not require(main.player.is_on_floor(),"Unsafe reciprocal door spawn"): return
	print("PASS: safe bidirectional door spawns across 20 seeds")
	var examples := FileAccess.open("res://../docs/generated-run-examples.json",FileAccess.WRITE)
	examples.store_string(JSON.stringify([Generator.generate(1103),Generator.generate(1104),Generator.generate(1105)],"  "))
	var catalog := FileAccess.open("res://../docs/room-templates.json",FileAccess.WRITE)
	catalog.store_string(JSON.stringify(Catalog.templates(),"  "))
	print("Random room checks completed.")
	quit(0)
