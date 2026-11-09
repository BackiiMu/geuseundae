extends RefCounted

const PATH := "res://assets/ui/layouts/inventory-layout.json"
static var cached: Dictionary = {}

static func data() -> Dictionary:
	if cached.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			cached = parsed
	return cached

static func profile_for(view_size: Vector2) -> Dictionary:
	var layout := data()
	var aspect := view_size.x / maxf(1.0, view_size.y)
	for profile in layout.get("profiles", []):
		var limits: Dictionary = profile.get("when", {})
		if limits.has("aspectMin") and aspect < float(limits["aspectMin"]):
			continue
		if limits.has("aspectMax") and aspect >= float(limits["aspectMax"]):
			continue
		return profile
	return layout.get("profiles", [{}])[0]

static func find_node(id: String, node: Dictionary = {}) -> Dictionary:
	if node.is_empty():
		node = data().get("root", {})
	if str(node.get("id", "")) == id:
		return node.duplicate(true)
	for child in node.get("children", []):
		var found := find_node(id, child)
		if not found.is_empty():
			return found
	return {}

static func node(id: String, view_size: Vector2 = Vector2(768, 432)) -> Dictionary:
	var result := find_node(id)
	var patch: Dictionary = profile_for(view_size).get("patch", {})
	if patch.has(id):
		result.merge(patch[id], true)
	return result

static func rect(id: String, view_size: Vector2 = Vector2(768, 432)) -> Rect2:
	var values: Array = node(id, view_size).get("rect", [0, 0, 0, 0])
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))

static func profile_id(view_size: Vector2) -> String:
	return str(profile_for(view_size).get("id", "landscape"))
