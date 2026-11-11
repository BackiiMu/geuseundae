extends RefCounted
# Runtime behaviors are independent of inventory presentation and stock generation.
var c: Node2D
var counters := {}
var combo := 0
var combo_time := 0.0
var spirits: Array = []
var swallowed := 0
var pending: Array = []
var clock := 0.0
var beam_time := 0.0
var beam_from := Vector2.ZERO
var beam_to := Vector2.ZERO
func reset_room() -> void:
	pending.clear()
	spirits.clear()
	swallowed=0
	combo=0
	combo_time=0
	beam_time=0
func targets(origin: Vector2,direction: Vector2,distance: float,cone := -1.0) -> Array:
	return c.living().filter(func(e):
		var v:Vector2=e.position+Vector2(0,-25*e.size_factor)-origin
		return v.length()<distance+20 and (cone<=-1 or v.length()<25 or v.normalized().dot(direction)>cone))
func mark(origin: Vector2,radius: float,color := Color("a6d4c0"),duration := .24) -> void:
	c.effects.append({"pos":origin,"radius":radius,"time":duration,"color":color})
func hit(enemy: Node,damage: float,id := "") -> float:
	if enemy.dead: return 0
	c.vfx.impact(enemy,c.DB.get_item(id) if id!="" else c.equipped("main"))
	var before:float=enemy.hp
	enemy.take_damage(damage)
	if id=="nails":
		combo=mini(15,combo+1)
		combo_time=1.2
	if id=="hair" and int(counters.get(id,0))%3==0: enemy.stun=maxf(enemy.stun,.4)
	if id=="water_hand": enemy.slow=2.0
	if id=="mirror" and not enemy.dead:
		enemy.vulnerable=4.0
		enemy.one_hit_vulnerable=true
	return maxf(0,before-enemy.hp)
func strike(origin: Vector2,direction: Vector2,reach: float,damage: float,id: String) -> Array:
	var struck:Array=targets(origin,direction,reach,.0)
	for enemy in struck: hit(enemy,damage,id)
	mark(origin+direction*reach*.55,reach*.55)
	return struck
func projectile(origin: Vector2,direction: Vector2,damage: float,kind: String,distance: float,id: String,homing := false) -> void:
	c.fire_projectile(origin,direction,damage,true,kind,null,homing)
	var p:Dictionary=c.projectiles[-1]
	p["life"]=distance/440.0
	p["weapon"]=id
	p["size"]=1.5 if c.has_passive("reach") else 1.0
	if kind in ["water","poison"]:
		p["velocity"]=direction*340+Vector2(0,-210)
		p["life"]=2.5
	if kind=="boomerang":
		p["life"]=2.4
		p["returning"]=false
	if kind=="tiger":
		p["velocity"]=direction*850
		p["life"]=1.15
		p["size"]=3.0
func attack(slot: String) -> void:
	var item:Dictionary=c.equipped(slot)
	if item.is_empty() or float(item.get("damage",0))<=0: return
	var id:String=item["id"]
	if id=="tooth" and c.tooth_reload>0: return
	var origin:Vector2=c.world.player.position+Vector2(0,-28)
	c.world.player.face_mouse_for_attack()
	var direction:Vector2=c.aim()
	if absf(direction.x)>.01:
		c.world.player.facing=signf(direction.x)
		c.world.player.queue_redraw()
	var reach:float=item["range"]
	if item["kind"]=="melee" and c.has_passive("reach"): reach*=1.5
	if id=="hair" and c.has_passive("hair_range"): reach*=1.2
	if is_instance_valid(c.world.player.visual): c.world.player.visual.play_attack(.3 if id=="fist" else .25,id=="fist")
	c.world.player.attack_pose=.18
	c.world.player.attack_lean=4*c.world.player.facing
	c.vfx.attack(item,origin,direction,reach)
	var damage:float=item["damage"]
	c.effects.append({"kind":id,"pos":origin,"direction":direction,"radius":reach,"time":.18,"color":Color("bfd7c7")})
	counters[id]=int(counters.get(id,0))+1
	if id=="tails" and counters[id]%9==0:
		damage*=3
		reach*=1.4
		for i in range(9): mark(origin+direction.rotated((i-4)*.16)*reach*.6,20,Color("deb79c"))
	if id=="shadow": reach*=1+minf(1,targets(origin,direction,280).size()*.18)
	if id=="fist":
		c.world.player.attack_pose=.3
		c.world.player.attack_lean=-4*c.world.player.facing
		pending.append({"kind":"fist","delay":.3,"direction":direction,"reach":reach,"damage":damage})
		mark(origin+direction*reach*.6,28,Color("dfbf84"),.3)
	elif id=="tiger_fang":
		# The pounce follows the actual aim vector instead of snapping sideways.
		c.world.player.velocity=direction*360
		pending.append({"kind":"bite","delay":.18,"direction":direction,"reach":reach,"damage":damage})
	elif id=="gaze":
		var query:=PhysicsRayQueryParameters2D.create(origin,origin+direction*reach,1)
		var wall:Dictionary=c.get_world_2d().direct_space_state.intersect_ray(query)
		beam_from=origin
		beam_to=wall.get("position",origin+direction*reach)
		beam_time=.16
		for enemy in c.living():
			var center:Vector2=enemy.position+Vector2(0,-25)
			if Geometry2D.get_closest_point_to_segment(center,beam_from,beam_to).distance_to(center)<22:
				hit(enemy,damage,id)
				enemy.slow=minf(3,enemy.slow+.35)
	elif id=="broom":
		var enemy=c.nearest_enemy(origin,reach+45)
		if enemy!=null:
			hit(enemy,damage,id)
			mark(enemy.position+Vector2(0,-22),28,Color("c7bf8a"))
	elif item["kind"]=="melee":
		var struck:=strike(origin,direction,reach,damage,id)
		if id=="belt" and not struck.is_empty(): throw_enemy(struck[0],direction,18)
		if id=="mouth":
			for enemy in struck:
				if enemy.dead: swallowed=mini(6,swallowed+1)
				elif not enemy.boss: enemy.pull_to(c.world.player.position+direction*35,.25)
	else:
		var kind:String={"goose":"boomerang","water_bucket":"water","plague":"poison","whistle":"whistle","pin":"pin","goblin_fire":"goblin"}.get(id,"shot")
		if id=="eggshell":
			for angle in [-.22,0.0,.22]: projectile(origin,direction.rotated(angle),damage,kind,reach,id)
		else: projectile(origin,direction,damage,kind,reach,id,id=="fox_bead")
		if id=="tooth":
			c.tooth_ammo-=1
			if c.tooth_ammo<=0:
				c.tooth_reload=1.2
				c.message("아귀의 이빨 · 재생 중")
	if slot=="main":
		for spirit in spirits:
			var enemy=c.nearest_enemy(origin+direction*90,180)
			if enemy!=null:
				hit(enemy,4,"spirit")
				mark(enemy.position+Vector2(0,-28),20,Color("a3c6d9"))
	c.attack_cd[slot]=float(item["interval"])/(1.15 if c.has_passive("frenzy") and c.frenzy>0 else 1.0)/(1+combo*.035 if id=="nails" else 1.0)
func throw_enemy(enemy: Node,direction: Vector2,damage: float) -> void:
	if enemy.dead: return
	if enemy.boss:
		enemy.stun=maxf(enemy.stun,.25)
		return
	enemy.thrown_velocity=direction*540
	enemy.throw_damage=damage
	enemy.throw_remaining=.65
	enemy.throw_hits=[]
func skill(slot: String) -> void:
	if float(c.skill_cd[slot])>0: return
	var item:Dictionary=c.equipped(slot)
	var name:String=item.get("skill","")
	if c.duo_set() and slot=="off": name="crush"
	if name.is_empty(): return
	var origin:Vector2=c.world.player.position+Vector2(0,-24)
	var direction:Vector2=c.aim()
	var zone_start:int=c.zones.size()
	var found:=targets(origin,direction,360,.35)
	if name=="pull":
		if found.is_empty(): return
		found[0].pull_to(c.world.player.position+direction*65,.5)
		mark(found[0].position,24)
	elif name in ["well","lure"]:
		c.zones.append({"kind":name,"pos":c.safe_ground(c.world.player.position.x+direction.x*(200 if name=="lure" else 90)),"life":3.0,"tick":0.0})
	elif name in ["fear","confuse","mass_fear"]:
		for enemy in targets(origin,direction,360 if name=="mass_fear" else 260,.8 if name=="mass_fear" else .35):
			if name=="mass_fear" and (not enemy.clear_shot(origin) or Geometry2D.get_closest_point_to_segment(enemy.position+Vector2(0,-25),origin,origin+direction*360).distance_to(enemy.position+Vector2(0,-25))>26): continue
			if name=="confuse": enemy.confusion=4
			else: enemy.stun=2
		mark(origin+direction*100,140,Color("c1a2d7"))
	elif name=="shotgun":
		for angle in [-.45,-.23,0.0,.23,.45]: projectile(origin,direction.rotated(angle),12,"shot",360,"mirror")
	elif name=="spit":
		if swallowed<=0:
			c.message("거구귀의 입 · 평타로 적을 처치해 먼저 삼키세요")
			return
		var count:=swallowed
		for i in range(count): projectile(origin,direction.rotated((i-(count-1)*.5)*.16),18,"spit",550,"mouth")
		swallowed=0
	elif name=="mines":
		for i in range(3): c.zones.append({"kind":"mine","pos":c.safe_ground(c.world.player.position.x+direction.x*(64+i*72)),"life":8.0,"tick":0.0})
	elif name=="decoy":
		c.zones.append({"kind":"decoy","pos":c.world.player.position,"life":5.0,"tick":0.0,"hp":18.0})
		var destination:Vector2=origin+direction*140
		var wall:Dictionary=c.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(origin,destination,1))
		if not wall.is_empty(): destination=wall["position"]-direction*25
		c.world.player.position=Vector2(destination.x,destination.y+24)
		c.hurt_timer=.3
	elif name=="rush":
		c.world.player.dash_direction=direction
		c.world.player.dash_time=.3
		c.zones.append({"kind":"rush","pos":origin,"life":.32,"tick":0.0,"hit":[],"direction":direction})
	elif name=="tiger": projectile(origin,direction,45,"tiger",850,"tiger_fang")
	elif name=="drain":
		if found.is_empty(): return
		var enemy=found[0]
		var dealt:=hit(enemy,18,"tongue")
		if not enemy.dead: enemy.pull_to(c.world.player.position+direction*60,.4)
		c.health=minf(60,c.health+dealt*.35)
		mark(enemy.position,30,Color("c08d96"))
	elif name=="slam":
		if found.is_empty(): return
		var enemy=found[0]
		var point:Vector2=enemy.position+Vector2(0,-18)
		enemy.stun=.8
		c.area_effect(point,100,35)
		mark(point,100,Color("dfb685"))
	elif name=="crush":
		for enemy in c.living():
			if c.visible_rect().has_point(enemy.position):
				c.vfx.emit("fist",4,enemy.position+Vector2(0,-65),Vector2.DOWN,1.0)
				hit(enemy,35,"fist")
				enemy.stun=.6
				mark(enemy.position+Vector2(0,-60),45,Color("dec18b"))
	for i in range(zone_start,c.zones.size()): c.zones[i]["weapon"]=item.get("id","fist")
	c.vfx.cast(item,origin,direction,name)
	c.skill_cd[slot]=float(c.DB.skill_cooldown(name))
func killed(_enemy: Node) -> void:
	if c.equipped("off").get("id","")=="tiger_soul": spirits.append(8.0)
	if spirits.size()>3: spirits.pop_front()
func tick(delta: float) -> void:
	clock+=delta
	beam_time=maxf(0,beam_time-delta)
	combo_time=maxf(0,combo_time-delta)
	if combo_time<=0: combo=0
	if c.tooth_reload<=0 and c.tooth_ammo<=0: c.tooth_ammo=8
	if c.equipped("off").get("id","")!="tiger_soul": spirits.clear()
	for i in range(spirits.size()-1,-1,-1):
		spirits[i]-=delta
		if spirits[i]<=0: spirits.remove_at(i)
	for i in range(pending.size()-1,-1,-1):
		var p:Dictionary=pending[i]
		p["delay"]-=delta
		if p["delay"]>0: continue
		var origin:Vector2=c.world.player.position+Vector2(0,-28)
		if is_instance_valid(c.world.player.visual): c.world.player.visual.release_attack()
		c.world.player.attack_pose=.16
		c.world.player.attack_lean=5*c.world.player.facing
		c.vfx.heavy(origin,p["direction"],p["kind"])
		var struck:=strike(origin,p["direction"],p["reach"],p["damage"],"fist" if p["kind"]=="fist" else "tiger_fang")
		if p["kind"]=="fist": c.effects.append({"kind":"fist_hit","pos":origin+p["direction"]*p["reach"]*.6,"radius":30.0,"time":.18,"color":Color("d2c7ae")})
		if p["kind"]=="fist" and not struck.is_empty():
			c.hit_pause=.07
			for enemy in struck:
				enemy.knockback=p["direction"].x*180
		pending.remove_at(i)
func draw() -> void:
	if not is_instance_valid(c.world.player): return
	var origin:Vector2=c.world.player.position+Vector2(0,-30)
	if c.equipped("main").get("id","")=="fox_bead":
		for i in range(3): c.draw_circle(origin+Vector2(cos(clock*3+i*TAU/3)*28,sin(clock*3+i*TAU/3)*16),5,Color("b6dbca"))
	for i in range(spirits.size()):
		var pos:=origin+Vector2(-c.world.player.facing*(30+i*20),sin(clock*4+i)*8-12)
		c.draw_circle(pos,9,Color(.59,.72,.8,.7))
		c.draw_line(pos+Vector2(-4,0),pos+Vector2(5,-5),Color("dce9e2"),2)
	if c.equipped("off").get("id","")=="broom":
		var pos:=origin+Vector2(cos(clock*2)*48,-16+sin(clock*3)*10)
		c.draw_line(pos-Vector2(0,18),pos+Vector2(0,15),Color("bda881"),3)
		for i in range(4): c.draw_line(pos+Vector2(i*3-5,7),pos+Vector2(i*4-7,20),Color("d1c89c"),2)
