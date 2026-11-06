extends RefCounted

# Central heart identity data. Balance can be tuned here without duplicating
# values across village selection, combat HUD and inventory presentation.
const HEARTS := {
	"songaksi": {"name":"손각시", "heart_name":"손각시의 심장", "hp":60.0, "starter":"songaksi_hand", "skill_name":"이리 오너라", "cooldown":30.0, "dash_charges":1, "npc_art":"", "role":"songaksi"},
	"mongdal": {"name":"몽달귀신", "heart_name":"몽달귀신의 심장", "hp":90.0, "starter":"nails", "skill_name":"", "cooldown":0.0, "dash_charges":3, "npc_art":"res://assets/actors/concepts/mongdal-ghost-game-v1.png", "role":"mongdal"},
	"changgui": {"name":"창귀", "heart_name":"창귀의 심장", "hp":70.0, "starter":"claws", "skill_name":"창귀원혼", "cooldown":30.0, "dash_charges":1, "npc_art":"res://assets/actors/concepts/changwi-peasant-game-v2.png", "role":"changgui"}
}

static func get_heart(id: String) -> Dictionary:
	return HEARTS.get(id, {}).duplicate(true)

static func max_hp(id: String) -> float:
	return float(HEARTS.get(id, {}).get("hp", 1.0))

static func display_name(id: String) -> String:
	return str(HEARTS.get(id, {}).get("name", "이름 없는 귀신"))

static func unlocked(id: String, profile: Dictionary) -> bool:
	return profile.get("unlocked_hearts", []).has(id)
