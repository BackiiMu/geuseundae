extends SceneTree
const SaveSlots=preload("res://scripts/save_slots.gd")

func check(value: bool,label: String) -> bool:
	if not value: push_error("FAIL: "+label); quit(1); return false
	print("PASS: "+label); return true

func _initialize() -> void:
	SaveSlots.use_test_directory("/tmp/geuseundae-save-slots-test")
	for slot in range(1,SaveSlots.SLOT_COUNT+1): SaveSlots.erase(slot)
	var title=load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title); await process_frame
	title.open_slots()
	if not check(title.slot_list.get_child_count()==3,"title screen presents exactly three save slots"): return
	title.queue_free(); await process_frame
	var world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.active_save_slot=2
	world.wallet={"souls":37,"bag":[{"id":"goose"}]}
	world.combat.equipment["head"]="wig"
	world.combat.health=.75
	if not check(world.autosave(),"slot 2 writes an autosave snapshot"): return
	if not check(not SaveSlots.exists(1) and SaveSlots.exists(2) and not SaveSlots.exists(3),"three save paths remain independent"): return
	var raw:=SaveSlots.read(2)
	if not check(raw["wallet"]["souls"]==37 and raw["equipment"]["head"]=="wig","wallet and equipment are serialized"): return
	DirAccess.rename_absolute(SaveSlots.absolute(SaveSlots.path(2)),SaveSlots.absolute(SaveSlots.backup_path(2)))
	if not check(int(SaveSlots.read(2)["wallet"]["souls"])==37,"mobile save recovers from the previous backup if the main file is interrupted"): return
	DirAccess.rename_absolute(SaveSlots.absolute(SaveSlots.backup_path(2)),SaveSlots.absolute(SaveSlots.path(2)))
	world.queue_free(); await process_frame
	set_meta("save_slot",2)
	var restored=load("res://scenes/village.tscn").instantiate()
	root.add_child(restored); await process_frame
	if not check(restored.active_save_slot==2,"selected existing slot loads automatically"): return
	if not check(restored.wallet["souls"]==37 and restored.combat.equipment["head"]=="wig" and is_equal_approx(restored.combat.health,.75),"saved progression and combat state restore"): return
	restored.new_run(4242); await process_frame
	var room_save:=SaveSlots.read(2)
	if not check(int(room_save["run"]["seed"])==4242 and not room_save["in_village"],"entering a newly generated room autosaves immediately"): return
	restored.combat.equipment["heart"]="songaksi"
	restored.combat.equipment["main"]="songaksi_hand"
	restored.combat.health=0
	restored.combat_death(); await process_frame; await process_frame
	var death_save:=SaveSlots.read(2)
	if not check(death_save["in_village"] and death_save["equipment"]["heart"]=="" and float(death_save["health"])==1.0,"death autosaves the heartless village state"): return
	SaveSlots.erase(2)
	if not check(SaveSlots.summary(2)["empty"],"slot deletion returns it to new game"): return
	quit()
