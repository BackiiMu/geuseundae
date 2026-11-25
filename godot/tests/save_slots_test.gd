extends SceneTree
const SaveSlots=preload("res://scripts/save_slots.gd")

func check(value: bool,label: String) -> bool:
	if not value: push_error("FAIL: "+label); quit(1); return false
	print("PASS: "+label); return true

func _initialize() -> void:
	SaveSlots.use_test_directory("/tmp/geuseundae-save-slots-test")
	for slot in range(1,SaveSlots.TOTAL_SLOT_COUNT+1): SaveSlots.erase(slot)
	var title=load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title); await process_frame
	title.open_slots()
	if not check(title.slot_list.get_child_count()==3,"title screen presents exactly three save slots"): return
	title.open_test_slots()
	await process_frame
	if not check(title.test_slot_mode and title.slot_list.get_child_count()==3,"full equipment test presents three separate save slots"): return
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
	var test_world=load("res://scenes/village.tscn").instantiate()
	root.add_child(test_world); await process_frame
	test_world.active_save_slot=SaveSlots.TEST_SLOT_OFFSET+1
	test_world.start_full_test_run(); await process_frame; await process_frame
	if not check(test_world.in_village and test_world.full_test_run and test_world.wallet["bag"].size()==test_world.combat.DB.items().size(),"new full equipment save starts in the village with the complete item bag"): return
	if not check(SaveSlots.exists(SaveSlots.TEST_SLOT_OFFSET+1),"full equipment mode autosaves into its separate test slot"): return
	var test_saved:=SaveSlots.read(SaveSlots.TEST_SLOT_OFFSET+1)
	if not check(bool(test_saved.get("full_test_run",false)) and bool(test_saved.get("in_village",false)),"test-mode identity and village state are serialized"): return
	test_world.new_run(7070); await process_frame
	if not check(int(SaveSlots.read(SaveSlots.TEST_SLOT_OFFSET+1)["run"]["seed"])==7070,"test mode autosaves on room entry like normal play"): return
	if not check(test_world.Generator.validate(SaveSlots.read(SaveSlots.TEST_SLOT_OFFSET+1)["run"]),"serialized test run remains valid for resume"): return
	test_world.queue_free(); await process_frame
	set_meta("save_slot",SaveSlots.TEST_SLOT_OFFSET+1)
	var test_restored=load("res://scenes/village.tscn").instantiate()
	root.add_child(test_restored); await process_frame
	if not check(test_restored.full_test_run and not test_restored.in_village and int(test_restored.run.get("seed",-1))==7070,"test slot resumes its saved run instead of creating a fresh one: full=%s village=%s seed=%s slot=%s" % [test_restored.full_test_run,test_restored.in_village,test_restored.run.get("seed",-1),test_restored.active_save_slot]): return
	test_restored.combat_death(); await process_frame; await process_frame
	var test_death:=SaveSlots.read(SaveSlots.TEST_SLOT_OFFSET+1)
	if not check(test_death["in_village"] and test_death["equipment"]["heart"]=="" and test_death["wallet"]["bag"].size()==test_restored.combat.DB.items().size(),"test death returns to the village and preserves the full test inventory in autosave"): return
	SaveSlots.erase(SaveSlots.TEST_SLOT_OFFSET+1)
	quit()
