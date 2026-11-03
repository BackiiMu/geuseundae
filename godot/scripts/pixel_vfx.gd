extends Node2D
# Transparent pixelfx sheets; pivots and frame rate come from their exported manifest.
var combat: Node2D
var manifest: Dictionary
var textures := {}
var bursts: Array = []
var gates := {}
var clock := 0.0
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
func attack(item: Dictionary,pos: Vector2,direction: Vector2,reach: float) -> void:
	var id:String=item["id"]
	var tier:int=item["tier"]
	if id in ["fist","tiger_fang","gaze"]: return
	var tint:=item_tint(item)
	if item["kind"]=="melee":
		var size:=clampf(reach/105.0,.55,1.6)
		emit("slash",tier,pos+Vector2(0,28-size*20)+direction*reach*.35,direction,size,tint,1.6 if tier==1 else 1.35)
		if id=="claws": emit("slash",tier,pos+Vector2(0,16),direction.rotated(-.14),size*.85,tint,1.5)
	else:
		emit("impact",tier,pos+direction*12,direction,.22 if tier==1 else .3,tint,2.2)
func impact(enemy: Node,item: Dictionary) -> void:
	var tier:int=item.get("tier",1)
	var key:=str(enemy.get_instance_id())
	if float(gates.get(key,0))>0: return
	gates[key]=.09
	emit("impact",tier,enemy.position+Vector2(0,-28*enemy.size_factor),Vector2.RIGHT,.4+float(tier)*.1,item_tint(item),1.7)
func cast(item: Dictionary,pos: Vector2,direction: Vector2,skill: String) -> void:
	var tier:int=4 if skill=="crush" else int(item.get("tier",3))
	emit("seal",tier,pos,direction,.5+float(tier)*.1,item_tint(item),1.25)
	if skill in ["fear","mass_fear","confuse","shotgun","spit"]:
		emit("bloom",tier,pos+direction*65,direction,.7+float(tier)*.12,item_tint(item),1.2)
func heavy(pos: Vector2,direction: Vector2,kind: String) -> void:
	emit("fist" if kind=="fist" else "slash",4,pos+Vector2(0,28),direction,1.35 if kind=="fist" else 1.2,Color.WHITE,1.0)
func _physics_process(delta: float) -> void:
	if not is_instance_valid(combat) or combat.paused: return
	clock+=delta
	for key in gates: gates[key]=maxf(0,float(gates[key])-delta)
	for i in range(bursts.size()-1,-1,-1):
		bursts[i]["age"]+=delta*bursts[i]["speed"]
		if bursts[i]["age"]>=.72: bursts.remove_at(i)
	queue_redraw()
func sheet(key: String,pos: Vector2,age: float,size: float,tint: Color,angle := 0.0) -> void:
	if not manifest.has(key): return
	var info:Dictionary=manifest[key]
	var frame:=clampi(int(age*float(info["fps"])),0,int(info["frames"])-1)
	var frame_size:=Vector2(info["frameSize"][0],info["frameSize"][1])
	var pivot:=Vector2(info["pivot"][0],info["pivot"][1])
	var source:=Rect2(Vector2(frame%int(info["columns"]),frame/int(info["columns"]))*frame_size,frame_size)
	# Horizontal mirroring keeps a left swing's gravity and upright fist intact.
	var flip:=cos(angle)<0
	var rotation:=angle-PI if flip else angle
	draw_set_transform(pos.round(),rotation,Vector2(-size if flip else size,size))
	draw_texture_rect_region(textures[key],Rect2(-pivot-Vector2(info.get("anchor",[0,0])[0],info.get("anchor",[0,0])[1]),frame_size),source,tint)
	draw_set_transform(Vector2.ZERO)
func draw_projectile(p: Dictionary) -> void:
	var item:Dictionary=combat.DB.get_item(p.get("weapon",""))
	var tier:int=item.get("tier",1)
	var pos:Vector2=p["pos"]
	var velocity:Vector2=p["velocity"]
	var direction:=velocity.normalized()
	var color:Color=GRADE_COLORS[tier-1]*item_tint(item)
	var kind:String=p["kind"]
	if kind=="tiger":
		sheet("tiger-4",pos,.08+fmod(float(p["age"]),.3),1.2,Color.WHITE,velocity.angle())
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
	var info:Dictionary=manifest["beam-3"]
	var frame:=clampi(int(fmod(clock,.64)*25),0,17)
	var frame_size:=Vector2(info["frameSize"][0],info["frameSize"][1])
	var pivot:=Vector2(info["pivot"][0],info["pivot"][1])
	var source:=Rect2(Vector2(frame%int(info["columns"]),frame/int(info["columns"]))*frame_size,frame_size)
	draw_set_transform(from.round(),(to-from).angle(),Vector2(from.distance_to(to)/168.0,1))
	draw_texture_rect_region(textures["beam-3"],Rect2(-pivot-Vector2(15,-24),frame_size),source)
	draw_set_transform(Vector2.ZERO)
func _draw() -> void:
	for zone in combat.zones: draw_zone(zone)
	for p in combat.projectiles:
		if p["friendly"]: draw_projectile(p)
	for burst in bursts: sheet(burst["key"],burst["pos"],burst["age"],burst["size"],burst["tint"],burst["angle"])
	if combat.arsenal.beam_time>0: draw_beam(combat.arsenal.beam_from,combat.arsenal.beam_to)
