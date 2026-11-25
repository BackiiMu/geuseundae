extends RefCounted

const VERSION := 1
const SLOT_COUNT := 3
const TEST_SLOT_OFFSET := SLOT_COUNT
const TOTAL_SLOT_COUNT := SLOT_COUNT * 2
static var test_base_dir := ""

static func use_test_directory(directory: String) -> void:
	test_base_dir=directory
	if not directory.is_empty(): DirAccess.make_dir_recursive_absolute(directory)

static func path(slot: int) -> String:
	var filename:="geuseundae_slot_%d.json" % clampi(slot,1,TOTAL_SLOT_COUNT)
	return test_base_dir.path_join(filename) if not test_base_dir.is_empty() else "user://"+filename

static func backup_path(slot: int) -> String:
	return path(slot)+".bak"

static func absolute(file_path: String) -> String:
	return ProjectSettings.globalize_path(file_path) if file_path.begins_with("user://") or file_path.begins_with("res://") else file_path

static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot)) or FileAccess.file_exists(backup_path(slot))

static func read(slot: int) -> Dictionary:
	if not exists(slot): return {}
	var source:=path(slot) if FileAccess.file_exists(path(slot)) else backup_path(slot)
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(source))
	if (parsed is not Dictionary or int(parsed.get("version",0))>VERSION) and source!=backup_path(slot) and FileAccess.file_exists(backup_path(slot)):
		parsed=JSON.parse_string(FileAccess.get_file_as_string(backup_path(slot)))
	if parsed is not Dictionary or int(parsed.get("version",0))>VERSION: return {}
	return parsed

static func write(slot: int,data: Dictionary) -> bool:
	var payload:=data.duplicate(true)
	payload["version"]=VERSION
	payload["slot"]=clampi(slot,1,TOTAL_SLOT_COUNT)
	payload["saved_at"]=int(Time.get_unix_time_from_system())
	var destination:=path(slot)
	var temporary:=destination+".tmp"
	var backup:=backup_path(slot)
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file=null
	var destination_abs:=absolute(destination)
	var temporary_abs:=absolute(temporary)
	var backup_abs:=absolute(backup)
	if FileAccess.file_exists(backup): DirAccess.remove_absolute(backup_abs)
	if FileAccess.file_exists(destination) and DirAccess.rename_absolute(destination_abs,backup_abs)!=OK: return false
	if DirAccess.rename_absolute(temporary_abs,destination_abs)!=OK:
		if FileAccess.file_exists(backup): DirAccess.rename_absolute(backup_abs,destination_abs)
		return false
	if FileAccess.file_exists(backup): DirAccess.remove_absolute(backup_abs)
	return true

static func erase(slot: int) -> bool:
	var result:=true
	for candidate in [path(slot),backup_path(slot),path(slot)+".tmp"]:
		if FileAccess.file_exists(candidate): result=DirAccess.remove_absolute(absolute(candidate))==OK and result
	return result

static func summary(slot: int) -> Dictionary:
	var data:=read(slot)
	if data.is_empty(): return {"empty":true,"slot":slot}
	return {
		"empty":false,
		"slot":slot,
		"floor":int(data.get("floor",1)),
		"souls":int(data.get("wallet",{}).get("souls",0)),
		"heart":str(data.get("equipment",{}).get("heart","")),
		"saved_at":int(data.get("saved_at",0)),
		"in_village":bool(data.get("in_village",true))
	}
