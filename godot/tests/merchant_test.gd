extends SceneTree
const Stock = preload("res://scripts/merchant_stock.gd")
const Generator = preload("res://scripts/run_generator.gd")
func _initialize() -> void: call_deferred("run_checks")
func require(ok: bool, message: String) -> bool:
	if not ok:
		push_error(message)
		quit(1)
	return ok
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run_checks() -> void:
	for value in range(200):
		var stock := Stock.roll(value,1,true)
		if not require(stock.size()==4,"Village needs four items"): return
		for item in stock:
			if not require(item["tier"]<=2,"Village tier exceeded two"): return
		var generated := Generator.generate(value)
		var safe := 0
		for data in generated["rooms"]:
			if data.get("peaceful",false): safe+=1
		if not require(safe==1,"Each floor needs exactly one peace room"): return
		if not require(JSON.stringify(Stock.roll(value,8))==JSON.stringify(Stock.roll(value,8)),"Floor stock must be deterministic"): return
	for floor_id in range(1,30):
		var low := Stock.weights(floor_id)
		var high := Stock.weights(floor_id+1)
		if not require(high[2]+high[3]>=low[2]+low[3],"High-tier probability fell at higher floor"): return
	print("PASS: 200 seeds, village four tier-1/2 items; exactly one peace room; reproducible floor stock; rising high-tier weights")
	var stock := Stock.roll(1103,1,true)
	var wallet := {"souls":0,"bag":[]}
	Stock.buy(stock,0,wallet)
	if not require(not stock[0]["sold"] and wallet["bag"].is_empty(),"Insufficient currency purchase must fail"): return
	wallet["souls"]=100
	var price: int = stock[0]["price"]
	Stock.buy(stock,0,wallet)
	Stock.buy(stock,0,wallet)
	if not require(wallet["souls"]==100-price and wallet["bag"].size()==1,"Purchase must debit once and deliver to bag once"): return
	var main = load("res://scenes/village.tscn").instantiate()
	main.combat_enabled=false
	root.add_child(main)
	await frames(40)
	if not require(main.in_village and is_instance_valid(main.merchant) and not main.is_combat_room(),"Village merchant not placed"): return
	var village_before := JSON.stringify(main.merchant.stock)
	main.merchant.toggle()
	await frames(2)
	main.merchant.toggle()
	main.show_village()
	await frames(2)
	if not require(JSON.stringify(main.merchant.stock)==village_before,"Village scene revisit must not reroll in same session"): return
	main.new_run(1103)
	var shop_id: int = main.run["shop_room"]
	main.change_room(shop_id,-1)
	await frames(3)
	if not require(not main.is_combat_room() and is_instance_valid(main.merchant),"Floor shop not peaceful"): return
	main.wallet["souls"]=100
	Stock.buy(main.merchant.stock,0,main.wallet)
	main.change_room(main.run["goal"],-1)
	await frames(2)
	main.change_room(shop_id,-1)
	await frames(2)
	if not require(main.merchant.stock[0]["sold"],"Room revisit must keep sold state"): return
	print("PASS: purchases, no duplicate buy, village refresh scope, floor merchant placement and sold state on revisit")
	quit(0)
