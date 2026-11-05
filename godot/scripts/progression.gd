extends RefCounted

# Run inventory is disposable; this small profile survives runs and records
# permanent boss discoveries.
const SAVE_PATH := "user://geuseundae_progression.json"
static var profile: Dictionary = {}

static func load_profile() -> Dictionary:
	if not profile.is_empty(): return profile
	profile = {"unlocked_hearts":["songaksi"],"unlocked_sets":[]}
	if FileAccess.file_exists(SAVE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary: profile.merge(parsed, true)
	return profile

static func unlock_changgui_and_jangsan() -> bool:
	load_profile()
	var changed := false
	if not profile["unlocked_hearts"].has("changgui"):
		profile["unlocked_hearts"].append("changgui")
		changed = true
	if not profile["unlocked_sets"].has("jangsan"):
		profile["unlocked_sets"].append("jangsan")
		changed = true
	if changed:
		var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(profile))
	return changed
