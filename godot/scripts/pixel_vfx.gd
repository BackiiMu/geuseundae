extends Node2D
# Transparent pixelfx sheets; pivots and frame rate come from their exported manifest.
var combat: Node2D
var manifest: Dictionary
var textures := {}
var bursts: Array = []
var gates := {}
var clock := 0.0
var provided_info := {}
var provided_textures := {}
var gear2_info := {}
var gear2_textures := {}
var gear3_info := {}
var gear3_textures := {}
var monster_info := {}
var monster_textures := {}
const PROVIDED_ATTACKS = {"hair":"hair-lash","pin":"rusted-hairpin","water_bucket":"water-gourd","fox_bead":"fox-bead","claws":"tiger-claw","goblin_fire":"dokkaebi-fire","plague":"plague-jar"}
# Songaksi Hand retains the original slash renderer below; every other entry
# here uses a supplied gear2 sheet.
const GEAR2_ATTACKS = {"ribbon":"broken-ribbon","mirror":"bloody-jokduri"}
const GEAR3_ATTACKS = {"nails":"mongdal-nail","goose":"wood-goose","mongdal_rush":"mongdal-han","call":"changgwi-call","tiger_soul":"bound-soul","water_hand":"drowned-grab","well_bucket":"well-bucket","fox_fire":"fox-fire","fox_mirror":"shape-mirror","club":"dokkaebi-club","broom":"old-broom","belt":"ssireum-sash","tooth":"agwi-teeth","tongue":"agwi-tongue","shadow":"murk-shadow","voice":"mimic-voice","whistle":"thin-whistle","mouth":"giant-mouth"}
const SIGNATURE_MELEE = {"songaksi_hand":"slash","mongdal_rush":"dash","tiger_soul":"seal","water_hand":"bloom","club":"fist","broom":"slash","belt":"fist","tongue":"beam","shadow":"seal","ribbon":"slash","fox_mirror":"seal"}
const GRADE_COLORS=[Color("c9d8bb"),Color("9bdbd0"),Color("d4a9dc"),Color("f3d294")]
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	z_index=6
	manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/vfx/manifest.json"))
	for key in manifest: textures[key]=load(manifest[key]["path"])
func clear() -> void:
	bursts.clear()
	gates.clear()
func item_tint(item: Dictionary) -> Color:
	return {"water":Color("a1ddeb"),"fox":Color("f4b9a3"),"songaksi":Color("d2e4d3"),"shadow":Color("bba4dd"),"plague":Color("b4d48d"),"agwi":Color("dfa4a4"),"changgui":Color("f1d0a2")}.get(item.get("set",""),Color.WHITE)
func emit(mode: String,tier: int,pos: Vector2,direction := Vector2.RIGHT,size := 1.0,tint := Color.WHITE,speed := 1.0) -> void:
	var key:=mode+"-"+str(clampi(tier,1,4))
	if not manifest.has(key): key="bloom-"+str(clampi(tier,1,4))
	if bursts.size()>=40: bursts.pop_front()
	bursts.append({"key":key,"pos":pos,"angle":direction.angle(),"size":size,"tint":tint,"age":.04,"speed":speed})

func attach_last_to_player() -> void:
	if bursts.is_empty() or not is_instance_valid(combat) or not is_instance_valid(combat.world.player): return
	bursts[-1]["follow_player"] = true
	bursts[-1]["player_offset"] = Vector2(bursts[-1]["pos"]) - combat.world.player.position
func attack(item: Dictionary,pos: Vector2,direction: Vector2,reach: float) -> void:
	var id:String=item["id"]
	var tier:int=item["tier"]
	if id=="jangsan_paw":
		# 원래 발톱 시트를 정수 3배로 키운다. 발톱이 그려지는 영역(시트 65..137, 55..131)의 오른쪽 끝이 가슴 기준 앞 180,
		# 세로 중심이 가슴보다 14 위에 오도록 피벗(34,128) 위치를 계산한 값 (-129, 91). 실제 판정 사거리는 150이다.
		var claw_local:=Vector2(-129.0,91.0)
		var claw_offset:=claw_local.rotated(direction.angle()) if direction.x>=0.0 else Vector2(-claw_local.x,claw_local.y).rotated(direction.angle()-PI)
		emit_gear3("jangsan-paw",pos+claw_offset,direction,3.0)
		attach_last_to_player()
		return
	if GEAR2_ATTACKS.has(id):
		emit_gear2(str(GEAR2_ATTACKS[id]),pos+Vector2(0,28),direction)
		if item["kind"]=="melee": attach_last_to_player()
		return
	if GEAR3_ATTACKS.has(id):
		var effect_pos:=pos+Vector2(0,28)
		var effect_size:=1.0
		if id=="water_hand":
			# The source sheet is only 64 px wide, while the grab's real melee
			# reach is 140 px. Centre the enlarged sheet across that forward
			# reach so the rising hands communicate the actual hit area.
			effect_size=maxf(1.0,reach/64.0)
			effect_pos+=direction*reach*.5
		emit_gear3(str(GEAR3_ATTACKS[id]),effect_pos,direction,effect_size)
		if item["kind"]=="melee": attach_last_to_player()
		return
	if id in ["fist","tiger_fang","gaze"]: return
	if id=="eggshell":
		emit_gear2("eggshell-cast",pos,direction)
		attach_last_to_player()
		return
	if PROVIDED_ATTACKS.has(id):
		emit_provided(str(PROVIDED_ATTACKS[id]), pos + Vector2(0, 28), direction)
		if item["kind"]=="melee": attach_last_to_player()
		return
	var tint:=item_tint(item)
	if item["kind"]=="melee":
		var size:=clampf(reach/105.0,.55,1.6)
		var signature := str(SIGNATURE_MELEE.get(id,"slash"))
		var effect_pos := pos+Vector2(0,28-size*20)+direction*reach*.35
		if signature=="dash":
			emit("dash",2,effect_pos,direction,size*.78,Color("b9d7ca"),1.8)
		elif signature=="fist":
			emit("fist",4,effect_pos,direction,size*.9,Color("d9c28b"),1.55)
		elif signature=="seal":
			emit("seal",tier,effect_pos,direction,size*.8,tint,1.7)
		elif signature=="bloom":
			emit("bloom",tier,effect_pos,direction,size*.72,Color("93d7e2"),1.9)
		elif signature=="beam":
			emit("beam",3,effect_pos,direction,size*.8,Color("d9898d"),1.85)
		else:
			emit("slash",tier,effect_pos,direction,size,tint,1.6 if tier==1 else 1.35)
		attach_last_to_player()
		if id=="claws": emit("slash",tier,pos+Vector2(0,16),direction.rotated(-.14),size*.85,tint,1.5)
		if id=="claws": attach_last_to_player()
	else:
		emit("impact",tier,pos+direction*12,direction,.22 if tier==1 else .3,tint,2.2)
func impact(enemy: Node,item: Dictionary) -> void:
	var tier:int=item.get("tier",1)
	var key:=str(enemy.get_instance_id())
	if float(gates.get(key,0))>0: return
	gates[key]=.09
	if item.get("id","")=="eggshell":
		emit_gear2("eggshell-hit",enemy.position+Vector2(0,-25*enemy.size_factor),Vector2.RIGHT)
		return
	if item.get("id","")=="mirror":
		emit_gear2("jokduri-hit",enemy.position+Vector2(0,-25*enemy.size_factor),Vector2.RIGHT)
		return
	emit("impact",tier,enemy.position+Vector2(0,-28*enemy.size_factor),Vector2.RIGHT,.4+float(tier)*.1,item_tint(item),1.7)
func cast(item: Dictionary,pos: Vector2,direction: Vector2,skill: String) -> void:
	var gear2_name: String = {"ribbon":"broken-ribbon","blank_face":"blank-face","mirror":"jokduri-cast"}.get(str(item.get("id","")),"")
	if not gear2_name.is_empty():
		var cast_pos := pos + (direction*14 if item.get("id","")=="mirror" else Vector2(0,24))
		emit_gear2(gear2_name,cast_pos,direction)
		attach_last_to_player()
		return
	var tier:int=4 if skill=="crush" else int(item.get("tier",3))
	emit("seal",tier,pos,direction,.5+float(tier)*.1,item_tint(item),1.25)
	if skill in ["fear","mass_fear","confuse","shotgun","spit"]:
		emit("bloom",tier,pos+direction*65,direction,.7+float(tier)*.12,item_tint(item),1.2)
func heavy(pos: Vector2,direction: Vector2,kind: String) -> void:
	emit("fist" if kind=="fist" else "slash",4,pos+Vector2(0,28),direction,1.35 if kind=="fist" else 1.2,Color.WHITE,1.0)
	attach_last_to_player()

# Chapter 1 enemies use dedicated Pixelfx sheets. Enemy art is kept on the
# same renderer as player VFX so timing, nearest filtering and cleanup match.
func enemy(name: String, pos: Vector2, direction := Vector2.RIGHT, size := 1.0) -> void:
	if not manifest.has(name):
		return
	if bursts.size() >= 40:
		bursts.pop_front()
	bursts.append({"key":name,"pos":pos,"angle":direction.angle(),"size":size,"tint":Color.WHITE,"age":0.0,"speed":1.0})

func changgui_soul_bind(owner: Node) -> void:
	const KEY := "changgui-soul-bind"
	if not manifest.has(KEY) or not is_instance_valid(owner): return
	var info:Dictionary=manifest[KEY]
	if bursts.size()>=40: bursts.pop_front()
	bursts.append({"key":KEY,"owner":owner,"offset":Vector2.ZERO,"pos":owner.position,"angle":0.0,"size":1.0,"tint":Color.WHITE,"age":0.0,"speed":1.0,"duration":float(info["frames"])/float(info["fps"])})

func load_monster(name: String) -> Dictionary:
	if not monster_info.has(name):
		var base := "res://assets/monster_vfx/"+name
		monster_info[name]=JSON.parse_string(FileAccess.get_file_as_string(base+".json"))["meta"]["pixelfx"]
		monster_textures[name]=load(base+".png")
	return monster_info[name]

func emit_monster(name: String, owner: Node, offset := Vector2.ZERO, direction := Vector2.RIGHT, size := 1.0) -> void:
	var info:=load_monster(name)
	if bursts.size()>=40: bursts.pop_front()
	bursts.append({"monster":name,"owner":owner,"offset":offset,"pos":owner.position+offset,"angle":direction.angle(),"size":size,"age":0.0,"speed":1.0,"duration":float(info["frames"])/float(info["fps"])})

func monster_impact(name: String,pos: Vector2,direction := Vector2.RIGHT,size := 1.0) -> void:
	var info:=load_monster(name)
	bursts.append({"monster":name,"pos":pos,"angle":direction.angle(),"size":size,"age":0.0,"speed":1.0,"duration":float(info["frames"])/float(info["fps"]),"rotate":true})
func _physics_process(delta: float) -> void:
	if not is_instance_valid(combat) or combat.paused: return
	clock+=delta
	for key in gates: gates[key]=maxf(0,float(gates[key])-delta)
	for i in range(bursts.size()-1,-1,-1):
		if bursts[i].get("follow_player",false) and is_instance_valid(combat.world.player):
			bursts[i]["pos"] = combat.world.player.position + Vector2(bursts[i]["player_offset"])
		if bursts[i].has("owner"):
			if is_instance_valid(bursts[i]["owner"]): bursts[i]["pos"]=bursts[i]["owner"].position+Vector2(bursts[i]["offset"])
			else: bursts[i].erase("owner")
		bursts[i]["age"]+=delta*bursts[i]["speed"]
		if bursts[i]["age"]>=float(bursts[i].get("duration",.72)): bursts.remove_at(i)
	queue_redraw()

func emit_provided(name: String, pos: Vector2, direction: Vector2) -> void:
	if not provided_info.has(name):
		var base := "res://assets/provided_vfx/attacks/" + name
		provided_info[name] = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))["meta"]["pixelfx"]
		provided_textures[name] = load(base + ".png")
	var info: Dictionary = provided_info[name]
	bursts.append({"provided":name,"pos":pos,"angle":direction.angle(),"size":1.0,"tint":Color.WHITE,"age":0.0,"speed":1.0,"duration":float(info["frames"])/float(info["fps"])})

func load_gear2(name: String) -> Dictionary:
	if not gear2_info.has(name):
		var base := "res://assets/gear2/fx/" + name
		gear2_info[name] = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))["meta"]["pixelfx"]
		gear2_textures[name] = load(base + ".png")
	return gear2_info[name]

func emit_gear2(name: String, pos: Vector2, direction: Vector2) -> void:
	var info := load_gear2(name)
	bursts.append({"gear2":name,"pos":pos,"angle":direction.angle(),"size":1.0,"tint":Color.WHITE,"age":0.0,"speed":1.0,"duration":float(info["frames"])/float(info["fps"])})

func emit_gear3(name: String,pos: Vector2,direction: Vector2,size := 1.0) -> void:
	if not gear3_info.has(name):
		var base := "res://assets/gear3/fx/"+name
		gear3_info[name] = JSON.parse_string(FileAccess.get_file_as_string(base+".json"))["meta"]["pixelfx"]
		gear3_textures[name] = load(base+".png")
	var info: Dictionary = gear3_info[name]
	bursts.append({"gear3":name,"pos":pos,"angle":direction.angle(),"size":size,"age":0.0,"speed":1.0,"duration":float(info["frames"])/float(info["fps"])})

func gear3_sheet(name: String,pos: Vector2,age: float,angle: float,size := 1.0) -> void:
	var info: Dictionary = gear3_info[name]
	var frame := mini(int(age*float(info["fps"])),int(info["frames"])-1)
	var frame_size := Vector2(info["frameSize"][0],info["frameSize"][1])
	var pivot := Vector2(info["pivot"][0],info["pivot"][1])
	var columns:=int(info["columns"])
	var row:=floori(float(frame)/float(columns))
	var source := Rect2(Vector2(frame%columns,row)*frame_size,frame_size)
	# The supplied claw sprite faces right.  Flip the left half, then rotate it so
	# mouse aim and the eight keyboard aim directions share the same attack arc.
	var flip := cos(angle)<0
	var rotation := angle-PI if flip else angle
	draw_set_transform(pos.round(),rotation,Vector2(-size if flip else size,size))
	draw_texture_rect_region(gear3_textures[name],Rect2(-pivot,frame_size),source)
	draw_set_transform(Vector2.ZERO)

func gear2_sheet(name: String,pos: Vector2,age: float,angle: float,size := 1.0,loop := false) -> void:
	var info := load_gear2(name)
	var frame := int(age*float(info["fps"]))
	frame = posmod(frame,int(info["frames"])) if loop else mini(frame,int(info["frames"])-1)
	var frame_size:=Vector2(info["frameSize"][0],info["frameSize"][1])
	var pivot:=Vector2(info["pivot"][0],info["pivot"][1])
	var columns:=int(info["columns"])
	var row:=floori(float(frame)/float(columns))
	var source:=Rect2(Vector2(frame%columns,row)*frame_size,frame_size)
	var flip:=cos(angle)<0
	var rotation:=angle-PI if flip else angle
	draw_set_transform(pos.round(),rotation,Vector2(-size if flip else size,size))
	draw_texture_rect_region(gear2_textures[name],Rect2(-pivot,frame_size),source)
	draw_set_transform(Vector2.ZERO)

func provided_sheet(name: String, pos: Vector2, age: float, angle: float) -> void:
	var info: Dictionary = provided_info[name]
	var frame := mini(int(age * float(info["fps"])), int(info["frames"]) - 1)
	var frame_size := Vector2(info["frameSize"][0], info["frameSize"][1])
	var pivot := Vector2(info["pivot"][0], info["pivot"][1])
	var columns := int(info["columns"])
	var row := floori(float(frame)/float(columns))
	var source := Rect2(Vector2(frame % columns, row) * frame_size, frame_size)
	var flip := cos(angle) < 0
	var rotation := angle-PI if flip else angle
	draw_set_transform(pos.round(), rotation, Vector2(-1 if flip else 1, 1))
	draw_texture_rect_region(provided_textures[name], Rect2(-pivot, frame_size), source)
	draw_set_transform(Vector2.ZERO)

func monster_sheet(name: String,pos: Vector2,age: float,angle: float,size := 1.0,loop := false,rotate := false) -> void:
	var info:=load_monster(name)
	var frame:=int(age*float(info["fps"]))
	frame=posmod(frame,int(info["frames"])) if loop else mini(frame,int(info["frames"])-1)
	var frame_size:=Vector2(info["frameSize"][0],info["frameSize"][1])
	var pivot:=Vector2(info["pivot"][0],info["pivot"][1])
	var columns:=int(info["columns"])
	var row:=floori(float(frame)/float(columns))
	var source:=Rect2(Vector2(frame%columns,row)*frame_size,frame_size)
	var flip:=cos(angle)<0
	var rotation:float=(angle-PI if flip else angle) if rotate else 0.0
	draw_set_transform(pos.round(),rotation,Vector2(-size if flip else size,size))
	draw_texture_rect_region(monster_textures[name],Rect2(-pivot,frame_size),source)
	draw_set_transform(Vector2.ZERO)
func sheet(key: String,pos: Vector2,age: float,size: float,tint: Color,angle := 0.0) -> void:
	if not manifest.has(key): return
	var info:Dictionary=manifest[key]
	var frame:=clampi(int(age*float(info["fps"])),0,int(info["frames"])-1)
	var frame_size:=Vector2(info["frameSize"][0],info["frameSize"][1])
	var pivot:=Vector2(info["pivot"][0],info["pivot"][1])
	var columns:=int(info["columns"])
	var row:=floori(float(frame)/float(columns))
	var source:=Rect2(Vector2(frame%columns,row)*frame_size,frame_size)
	# Horizontal mirroring keeps a left swing's gravity and upright fist intact.
	var flip:=cos(angle)<0
	var rotation:=angle-PI if flip else angle
	draw_set_transform(pos.round(),rotation,Vector2(-size if flip else size,size))
	draw_texture_rect_region(textures[key],Rect2(-pivot-Vector2(info.get("anchor",[0,0])[0],info.get("anchor",[0,0])[1]),frame_size),source,tint)
	draw_set_transform(Vector2.ZERO)
func draw_projectile(p: Dictionary) -> void:
	if not p["friendly"]:
		if p["kind"]=="talisman": monster_sheet("talisman-shot",p["pos"],float(p["age"]),Vector2(p["velocity"]).angle(),1.0,true,true)
		return
	var item:Dictionary=combat.DB.get_item(p.get("weapon",""))
	if PROVIDED_ATTACKS.has(str(item.get("id", ""))): return
	var tier:int=item.get("tier",1)
	var pos:Vector2=p["pos"]
	var velocity:Vector2=p["velocity"]
	var direction:=velocity.normalized()
	var color:Color=GRADE_COLORS[tier-1]*item_tint(item)
	var kind:String=p["kind"]
	if item.get("id","")=="eggshell":
		gear2_sheet("eggshell-shot",pos,float(p["age"]),velocity.angle(),float(p.get("size",1)),true)
		return
	if item.get("id","")=="mirror":
		gear2_sheet("jokduri-shot",pos,float(p["age"]),velocity.angle(),float(p.get("size",1)),true)
		return
	if kind=="tiger":
		# 푸른 영혼 호랑이 머리(제공 이미지 v2 기반 12프레임 반복). 80×51 도트를 3배로 그린다.
		sheet("tiger-spirit",pos,fmod(float(p["age"]),.6),3.0,Color.WHITE,velocity.angle())
	elif kind in ["pin","spit","boomerang","whistle"]:
		draw_line((pos-direction*15).round(),pos.round(),color,3*float(p.get("size",1)))
		if kind=="pin": draw_line(pos.round(),(pos-direction*5+direction.orthogonal()*4).round(),Color("f1ebd6"),2)
		if kind=="boomerang":
			draw_circle(pos.round(),4,color)
			draw_line(pos.round(),(pos+Vector2(sin(clock*18)*12,cos(clock*18)*8)).round(),color,3)
		if kind=="whistle":
			for n in range(3): draw_arc(pos-direction*n*10,8+n*2,-1.1+velocity.angle(),1.1+velocity.angle(),12,color,1)
	else:
		sheet("orb-"+str(tier),pos,.04+fmod(float(p["age"]),.56),float(p.get("size",1)),item_tint(item),velocity.angle())
func draw_zone(zone: Dictionary) -> void:
	var pos:Vector2=zone["pos"]
	var kind:String=zone["kind"]
	var item:Dictionary=combat.DB.get_item(zone.get("weapon",""))
	var tier:int=item.get("tier",2)
	var color:Color=GRADE_COLORS[tier-1]*item_tint(item)
	if kind=="decoy": return
	var radius:=55.0 if kind in ["well","lure"] else 36.0
	for layer in range(1 if tier<3 else 2):
		var points:=PackedVector2Array()
		for n in range(25):
			var a:=n*TAU/24
			var r:=radius-layer*8+sin(a*5+clock*4)*2
			points.append((pos+Vector2(cos(a)*r,sin(a)*r*.2)).round())
		draw_polyline(points,Color(color,.7),2)
	if kind in ["mine","poison","well","lure"]:
		for i in range(3 if tier<3 else 7):
			var phase:=fmod(clock*.7+i*.19,1)
			var point:=pos+Vector2(sin(i*2.4+clock)*radius*.65,-phase*24)
			draw_rect(Rect2(point.round(),Vector2(2,3)),Color(color,1-phase))
	if kind=="pin":
		for i in range(3): draw_line(pos+Vector2(i*3,-40),pos+Vector2(-10+i*5,16),Color(color,.8),1)
func draw_beam(from: Vector2,to: Vector2) -> void:
	var info:Dictionary=load_gear2("hollow-gaze-beam")
	var frame:=int(clock*float(info["fps"]))%int(info["frames"])
	var frame_size:=Vector2(info["frameSize"][0],info["frameSize"][1])
	var pivot:=Vector2(info["pivot"][0],info["pivot"][1])
	var columns:=int(info["columns"])
	var row:=floori(float(frame)/float(columns))
	var source:=Rect2(Vector2(frame%columns,row)*frame_size,frame_size)
	draw_set_transform(from.round(),(to-from).angle(),Vector2(from.distance_to(to)/96.0,1))
	draw_texture_rect_region(gear2_textures["hollow-gaze-beam"],Rect2(-pivot,frame_size),source)
	draw_set_transform(Vector2.ZERO)
func _draw() -> void:
	for zone in combat.zones: draw_zone(zone)
	for p in combat.projectiles:
		draw_projectile(p)
	for burst in bursts:
		if burst.has("monster"): monster_sheet(burst["monster"],burst["pos"],burst["age"],burst["angle"],burst["size"],false,bool(burst.get("rotate",false)))
		elif burst.has("gear3"): gear3_sheet(burst["gear3"],burst["pos"],burst["age"],burst["angle"],burst["size"])
		elif burst.has("gear2"): gear2_sheet(burst["gear2"],burst["pos"],burst["age"],burst["angle"])
		elif burst.has("provided"): provided_sheet(burst["provided"],burst["pos"],burst["age"],burst["angle"])
		else: sheet(burst["key"],burst["pos"],burst["age"],burst["size"],burst["tint"],burst["angle"])
	if combat.arsenal.beam_time>0: draw_beam(combat.arsenal.beam_from,combat.arsenal.beam_to)
