extends SceneTree
const BagUtil=preload("res://scripts/bag_util.gd")
const DB=preload("res://scripts/equipment_db.gd")
func _initialize() -> void: call_deferred("run_checks")
func frames(n:int) -> void:
	for i in range(n): await process_frame
func check(ok:bool,text:String) -> bool:
	if ok:
		print("PASS: ",text);return true
	push_error(text);quit(1);return false
func ids(bag:Array) -> Array:
	return bag.map(func(x):return x.get("id","-"))
func run_checks() -> void:
	var world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(8)
	var c=world.combat
	var bag:Array=world.wallet["bag"]
	bag.clear()
	for id in ["nails","goose","call","tongue","club"]: BagUtil.add(bag,DB.get_item(id))
	# 1) 장착해도 뒤 칸이 밀리지 않고, 교체된 장비는 비운 칸에 들어간다
	c.equipment["main"]=""
	c.equip_bag(1)   # goose(main) 장착
	if not check(ids(bag)==["nails","-","call","tongue","club"] and c.equipment["main"]=="goose","Equipping leaves an empty slot and shifts nothing"): return
	c.equip_bag(0)   # nails(main) 장착 → goose가 0번 칸으로
	if not check(ids(bag)==["goose","-","call","tongue","club"] and c.equipment["main"]=="nails","Replaced weapon returns to the slot just freed"): return
	# 2) 해제한 장비·새 장비는 가장 앞의 빈 칸으로
	c.unequip("main")
	if not check(ids(bag)==["goose","nails","call","tongue","club"],"Unequipped weapon takes the first empty slot"): return
	BagUtil.clear_slot(bag,2)
	BagUtil.add(bag,DB.get_item("whistle"))
	if not check(ids(bag)==["goose","nails","whistle","tongue","club"],"New items fill the first empty slot"): return
	# 3) 파기해도 칸이 밀리지 않는다. 뒤쪽 빈 칸만 잘린다
	c.pending_destroy=4
	c.destroy_confirmed()
	if not check(bag.size()==4 and ids(bag)[3]=="tongue","Destroying the last item trims only trailing empties"): return
	c.pending_destroy=0
	c.destroy_confirmed()
	if not check(bag[0].is_empty() and ids(bag)[1]=="nails" and BagUtil.count(bag)==3,"Destroying keeps other items in place"): return
	# 4) 끌어서 칸 교환·빈 칸 이동
	if not check(c.handle_drop({"bag":0},{"bag":1},false) and ids(bag)[0]=="nails" and bag[1].is_empty(),"Dragging into an empty slot moves the item"): return
	if not check(c.handle_drop({"bag":2},{"bag":0},false) and ids(bag)[0]=="whistle" and ids(bag)[2]=="nails","Dragging onto an item swaps the two slots"): return
	# 5) 끌어서 장착 / 잘못된 칸은 거부
	if not check(not c.handle_drop({"equip":"off"},{"bag":0},true),"A main-hand weapon is refused by the off-hand slot"): return
	var off_index:=-1
	for i in range(bag.size()):
		if str(bag[i].get("id",""))=="tongue": off_index=i
	if not check(off_index>=0 and c.handle_drop({"equip":"off"},{"bag":off_index},false) and c.equipment["off"]=="tongue" and BagUtil.is_empty_slot(bag,off_index),"Dragging a weapon onto its slot equips it and empties the source slot"): return
	# 6) 장착한 장비를 가방의 원하는 칸에 놓기
	if not check(c.handle_drop({"bag":6},{"equip":"off"},false) and c.equipment["off"]=="" and ids(bag)[6]=="tongue","Dragging an equipped item into a chosen bag slot"): return
	# 7) 스크롤 위치 유지
	c.toggle_inventory()
	await frames(4)
	for i in range(34): BagUtil.add(bag,DB.get_item("fox_fire"))
	c.refresh_inventory()
	await frames(4)
	c.bag_scroll.scroll_vertical=80
	await frames(2)
	c.select_inventory(20)
	await frames(4)
	if not check(c.bag_scroll.scroll_vertical>=60,"Selecting an item keeps the bag scroll position"): return
	if not check(c.bag_scroll.get_v_scroll_bar().custom_minimum_size.x>=12,"Bag scrollbar is wide enough to grab"): return
	print("Bag behavior checks completed.")
	quit(0)
