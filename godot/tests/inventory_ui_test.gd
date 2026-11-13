extends SceneTree
const InventoryLayout=preload("res://scripts/inventory_layout.gd")

func _initialize() -> void: call_deferred("run_checks")
func frames(count:int) -> void:
	for i in range(count): await process_frame
func check(ok:bool,message:String) -> bool:
	if ok:
		print("PASS: ",message)
		return true
	push_error(message)
	quit(1)
	return false
func run_checks() -> void:
	if not check(InventoryLayout.data().get("schema","")=="geuseundae.ui.layout/1","Inventory reads the supplied JSON layout schema"): return
	if not check(InventoryLayout.profile_id(Vector2(768,432))=="landscape" and InventoryLayout.profile_id(Vector2(640,480))=="compact" and InventoryLayout.profile_id(Vector2(432,768))=="portrait","Inventory JSON selects landscape, compact and portrait profiles by aspect ratio"): return
	if not check(ProjectSettings.get_setting("display/window/stretch/mode")=="canvas_items","UI scales with the window instead of using raw screen pixels"): return
	if not check(ProjectSettings.get_setting("display/window/stretch/aspect")=="keep","Window and phone aspect changes preserve the 16:9 UI composition"): return
	var world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(8)
	world.combat.toggle_inventory()
	await frames(8)
	var combat=world.combat
	var frame:=InventoryLayout.rect("frame",combat.inventory.size)
	if not check(combat.inventory.visible and combat.inventory.size==Vector2(768,432) and frame.position.x>=384 and frame.end.x<=768,"Inventory keeps a stable design surface while the visible panel occupies only the right half"): return
	var expected_accessories:int=combat.equipment.keys().filter(func(key):return str(key).begins_with("a")).size()
	if not check(get_nodes_in_group("inventory_accessory_slot").size()==expected_accessories,"Accessory rail derives its square slots from the equipment model"): return
	combat.equipment.erase("a2")
	combat.equipment.erase("a3")
	combat.refresh_inventory()
	await frames(2)
	if not check(get_nodes_in_group("inventory_accessory_slot").size()==2,"Accessory rail contracts when slots are removed"): return
	for key in ["a2","a3","a4","a5"]: combat.equipment[key]=""
	combat.refresh_inventory()
	await frames(2)
	var six_slots:=get_nodes_in_group("inventory_accessory_slot")
	if not check(six_slots.size()==6,"Accessory rail expands when slots are added"): return
	var rail:Control=six_slots[0].get_parent().get_parent()
	var left_margin:float=six_slots[0].global_position.x-rail.global_position.x
	var right_margin:float=rail.global_position.x+rail.size.x-(six_slots[-1].global_position.x+six_slots[-1].size.x)
	if not check(absf(left_margin-right_margin)<2.0,"Variable accessory slots stay centered in their rail"): return
	if not check(get_nodes_in_group("inventory_bag_slot").size()>=30 and int(InventoryLayout.node("bag_grid",combat.inventory.size).get("columns",0))==4,"Half-screen bag keeps the full item capacity in a four-column scroll grid"): return
	if not check(combat.inv_rows.size.y<=combat.inventory.size.y,"Inventory content stays inside the visible panel"): return
	for control in get_nodes_in_group("inventory_bounded_control"):
		var local_rect:=Rect2(control.global_position-combat.inventory.global_position,control.size)
		if not check(frame.encloses(local_rect),"Inventory control stays inside frame: "+control.get_class()+" · "+str(control.get("text"))+" · "+str(local_rect)): return
	combat.equipment["heart"]="songaksi"
	combat.refresh_inventory()
	await frames(2)
	var heart_slot:Button=get_nodes_in_group("inventory_heart_slot")[0]
	if not check(heart_slot.get_child_count()>0 and "손각시의 심장" in heart_slot.tooltip_text,"Borrowed heart state renders its dedicated inventory icon and details"): return
	combat.select_inventory(1)
	await frames(2)
	if not check(combat.inventory_fx.playing,"Selecting a bag item plays the restrained pixelfx confirmation ring"): return
	if DisplayServer.get_name()!="headless":
		await frames(2)
		var image:=root.get_texture().get_image()
		image.save_png("/tmp/geuseundae-inventory-ui.png")
		print("PASS: Inventory reference screenshot saved")
	quit(0)
