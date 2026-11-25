extends SceneTree

const Generator=preload("res://scripts/run_generator.gd")
const Catalog=preload("res://scripts/room_catalog.gd")

func check(ok:bool,text:String) -> bool:
	if not ok:
		push_error(text)
		quit(1)
		return false
	print("PASS: ",text)
	return true

func _initialize() -> void:
	var variants:Dictionary={}
	var roles:Dictionary={}
	for seed in range(200):
		var run:=Generator.generate(seed)
		if not check(Generator.validate(run),"Seed %d validates with room roles and variants" % seed): return
		if not check(JSON.stringify(run)==JSON.stringify(Generator.generate(seed)),"Seed %d reproduces exactly" % seed): return
		for room in run["rooms"]:
			variants[int(room["variant"])]=true
			roles[str(room["role"])]=true
			var resolved:=Catalog.resolve(str(room["template"]),int(room["variant"]))
			if not check(resolved.has("sockets") and resolved["sockets"].size()==4,"Every resolved room has four directional sockets"): return
			if not check(not resolved["enemy_spawns"].is_empty(),"Every resolved room has lower or upper enemy pads"): return
	if not check(variants.size()==3,"Seeds use all three platform variants"): return
	if not check(roles.has("start") and roles.has("combat") and roles.has("shop") and roles.has("boss"),"Generation distinguishes start, combat, shop and boss roles"): return
	var base_count:int=Catalog.templates()["courtyard"]["platforms"].size()
	if not check(Catalog.resolve("courtyard",0)["platforms"].size()==base_count,"Variant zero preserves authored geometry"): return
	if not check(Catalog.resolve("courtyard",1)["platforms"].size()==base_count+1,"Upper perch variant adds one platform module"): return
	if not check(Catalog.resolve("courtyard",2)["platforms"].size()==base_count+2,"Split-step variant adds two platform modules"): return
	print("Room generation V7 checks completed.")
	quit()
