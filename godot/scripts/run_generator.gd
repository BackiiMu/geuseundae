extends RefCounted
const Catalog = preload("res://scripts/room_catalog.gd")
const VERSION := 5
const DEFAULT_ROOM_COUNT := 9
const MIN_PORTALS := 1
const MAX_PORTALS := 4

static func generate(run_seed: int, room_count: int = DEFAULT_ROOM_COUNT) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	var count := maxi(2,room_count)
	var bag: Array = ["gate","courtyard","well","hall","gallery","forest","store","shrine","sanctum"]
	for i in range(bag.size()-1,0,-1):
		var j := rng.randi_range(0,i)
		var temp = bag[i]
		bag[i] = bag[j]
		bag[j] = temp
	var rooms: Array = []
	var occupied: Dictionary = {Vector2i.ZERO:0}
	rooms.append({"id":0,"template":bag[0],"links":[],"grid":[0,0],"decor_seed":rng.randi(),"visited":false})
	var directions := [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]
	while rooms.size()<count:
		var candidates: Array = []
		for room in rooms:
			var at := Vector2i(room["grid"][0],room["grid"][1])
			for direction in directions:
				var cell: Vector2i = at+direction
				if not occupied.has(cell):
					candidates.append([room["id"],cell])
		var selected: Array = candidates[rng.randi_range(0,candidates.size()-1)]
		var cell: Vector2i = selected[1]
		var id := rooms.size()
		occupied[cell] = id
		rooms.append({"id":id,"template":bag[id%bag.size()],"links":[],"grid":[cell.x,cell.y],"decor_seed":rng.randi(),"visited":false})
		connect_rooms(rooms,selected[0],id)
	# Choose a remote leaf for the stage exit; do not add cycles through it.
	var distances: Dictionary = {0:0}
	var pending: Array = [0]
	var goal := 0
	while not pending.is_empty():
		var id: int = pending.pop_front()
		if rooms[id]["links"].size()==1 and distances[id]>distances[goal]:
			goal = id
		for next in rooms[id]["links"]:
			if not distances.has(next):
				distances[next] = distances[id]+1
				pending.append(next)
	# Seeded optional loops between neighboring cells, one portal per direction.
	for room in rooms:
		var at := Vector2i(room["grid"][0],room["grid"][1])
		for direction in [Vector2i.RIGHT,Vector2i.DOWN]:
			var neighbor: Vector2i = at+direction
			if occupied.has(neighbor):
				var other: int = occupied[neighbor]
				if room["id"]!=goal and other!=goal and not room["links"].has(other) and rng.randf()<.45:
					connect_rooms(rooms,room["id"],other)
	var shop_rng := RandomNumberGenerator.new()
	shop_rng.seed = run_seed ^ 0x53484f50
	var shop_candidates: Array = []
	for room in rooms:
		if room["id"]!=goal and room["id"]!=0: shop_candidates.append(room["id"])
	if shop_candidates.is_empty(): shop_candidates.append(0)
	var shop_id: int = shop_candidates[shop_rng.randi_range(0,shop_candidates.size()-1)]
	for room in rooms:
		room["peaceful"] = room["id"]==shop_id
	return {"version":VERSION,"seed":run_seed,"rooms":rooms,"start":0,"goal":goal,"shop_room":shop_id}

static func connect_rooms(rooms: Array,a: int,b: int) -> void:
	rooms[a]["links"].append(b)
	rooms[b]["links"].append(a)

static func validate(run: Dictionary) -> bool:
	var rooms: Array = run["rooms"]
	if rooms.size()<2:
		return false
	var seen: Array = [run["start"]]
	var queue: Array = seen.duplicate()
	while not queue.is_empty():
		var id: int = queue.pop_front()
		var room: Dictionary = rooms[id]
		if room["links"].size()<MIN_PORTALS or room["links"].size()>MAX_PORTALS:
			return false
		if not Catalog.templates().has(room["template"]):
			return false
		for next in room["links"]:
			if next<0 or next>=rooms.size() or next==id or not rooms[next]["links"].has(id):
				return false
			if not seen.has(next):
				seen.append(next)
				queue.append(next)
	var peaceful_count := 0
	for room in rooms:
		if bool(room.get("peaceful",false)): peaceful_count+=1
	return seen.size()==rooms.size() and seen.has(run["goal"]) and peaceful_count==1
