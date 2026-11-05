extends SceneTree

const Generator=preload("res://scripts/run_generator.gd")

func _initialize() -> void:
	call_deferred("run_checks")

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
	await process_frame
	world.session_rng.seed=20261105
	var first:int=world.fresh_seed()
	var second:int=world.fresh_seed()
	if not check(first!=second,"Successive new-floor starts receive different seeds"): return
	world.session_rng.seed=20261105
	if not check(world.fresh_seed()==first,"Seed generation sequence is reproducible for verification"): return
	if not check(JSON.stringify(Generator.generate(first))==JSON.stringify(Generator.generate(first)),"The displayed seed reproduces the same room graph"): return
	if not check(JSON.stringify(Generator.generate(first))!=JSON.stringify(Generator.generate(second)),"Different session seeds produce different room graphs"): return
	quit(0)
