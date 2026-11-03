extends RefCounted
# Item effects/prices remain prototype proposals; tiers 1/2 match village constraints.
const DB = preload("res://scripts/equipment_db.gd")
static func weights(floor_number: int) -> Array:
	var t := clampf((floor_number-1)/14.0,0,1)
	return [60.0-50*t,30.0+5*t,9.0+26*t,1.0+19*t]
static func roll(seed_value: int, floor_number: int, village := false) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var stock: Array = []
	var used: Array = []
	for i in range(4):
		var weights_now: Array = [70.0,30.0,0.0,0.0] if village else weights(floor_number)
		var draw := rng.randf()*100
		var tier := 1
		for weight in weights_now:
			draw -= weight
			if draw<0: break
			tier+=1
		tier = mini(4,tier)
		var pool: Array = []
		for item in DB.items():
			if item["tier"]==tier and not used.has(item["id"]): pool.append(item)
		if pool.is_empty():
			for item in DB.items():
				if item["tier"]==tier: pool.append(item)
		var chosen: Dictionary = pool[rng.randi_range(0,pool.size()-1)].duplicate(true)
		chosen["sold"] = false
		used.append(chosen["id"])
		stock.append(chosen)
	return stock
static func buy(stock: Array, index: int, wallet: Dictionary) -> String:
	if index<0 or index>=stock.size(): return "없는 상품입니다."
	var item: Dictionary = stock[index]
	if item["sold"]: return "이미 판매된 상품입니다."
	if int(wallet["souls"])<item["price"]: return "영혼조각이 부족합니다."
	wallet["souls"] -= item["price"]
	wallet["bag"].append(item.duplicate(true))
	item["sold"] = true
	return "가방에 넣었습니다: "+str(item["name"])
