extends RefCounted
## 가방은 칸 위치가 고정된 배열이다. 빈 칸은 빈 Dictionary({})이고, 뒤쪽 빈 칸만 잘라 낸다.
## 새 장비·해제한 장비는 가장 앞의 빈 칸에 들어가고, 장착·파기해도 다른 칸은 밀리지 않는다.

static func is_empty_slot(bag: Array, index: int) -> bool:
	return index < 0 or index >= bag.size() or (bag[index] as Dictionary).is_empty()

static func first_empty(bag: Array) -> int:
	for i in bag.size():
		if (bag[i] as Dictionary).is_empty(): return i
	return bag.size()

static func add(bag: Array, item: Dictionary) -> int:
	var index := first_empty(bag)
	if index >= bag.size(): bag.append(item)
	else: bag[index] = item
	return index

static func clear_slot(bag: Array, index: int) -> void:
	if index < 0 or index >= bag.size(): return
	bag[index] = {}
	trim(bag)

static func trim(bag: Array) -> void:
	while not bag.is_empty() and (bag[bag.size() - 1] as Dictionary).is_empty():
		bag.pop_back()

static func count(bag: Array) -> int:
	var n := 0
	for item in bag:
		if not (item as Dictionary).is_empty(): n += 1
	return n

static func swap(bag: Array, a: int, b: int) -> void:
	var size := maxi(a, b) + 1
	while bag.size() < size: bag.append({})
	var tmp: Dictionary = bag[a]
	bag[a] = bag[b]
	bag[b] = tmp
	trim(bag)
