extends CharacterBody2D
const ActorSprite=preload("res://scripts/actor_sprite.gd")
const JANGSAN_FOG_TEXTURE=preload("res://assets/vfx/jangsan-transform-fog.png")
const JANGSAN_FOG_FRAME_SIZE:=Vector2(320,180)
const JANGSAN_FOG_PIVOT:=Vector2(160,170)
const JANGSAN_FOG_COLUMNS:=15
var visual: Node2D
var director: Node2D
var uid := 0
var kind := "warrior"
var hp := 30.0
var max_hp := 30.0
var attack := 8.0
var speed := 105.0
var state := "approach"
var timer := 1.0
var stun := 0.0
var confusion := 0.0
var facing := -1.0
var attack_direction := Vector2.LEFT
var pattern := 0
var phase_counter := 0
var training_dummy := false
var dead := false
var boss := false
var pull_remaining := 0.0
var pull_origin := Vector2.ZERO
var pull_target := Vector2.ZERO
var pull_duration := .7
var size_factor := 1.0
var flash := 0.0
var slow := 0.0
var vulnerable := 0.0
var knockback := 0.0
var thrown_velocity := Vector2.ZERO
var throw_remaining := 0.0
var throw_damage := 0.0
var throw_hits: Array = []
var charge_remaining := 0.0
var collision_shape: CollisionShape2D
var jangsan_phase := 0
var phase_transitioning := false
var phase_transition_time := 0.0
var phase_transition_target := 0
var phase_transition_swapped := false
var phase_fog_alpha := 0.0
const JANGSAN_PHASE_HP := [0.0,260.0,450.0,850.0]
# 몬스터별 공격 이펙트 시트(godot/assets/monster_vfx). 원점은 발이고 판정 범위에 맞춰 만들었다.
const ATTACK_VFX := {"monk":"monk-moktak","changgui-remnant":"changgui-claw","mountain-tiger":"tiger-claw","jangsan-shadow":"shadow-claw","mihokbul":"mihokbul-cast","hosikchong-wraith":"hosikchong-erupt"}

func windup_duration() -> float:
	if kind=="jangsanbeom" and jangsan_phase==1: return .78
	if kind=="jangsanbeom": return [.72,1.05,.64][pattern]
	if boss: return [.56,.92,.75][pattern]
	if kind=="mihokbul": return 1.15
	if kind=="hosikchong-wraith": return 1.0
	if kind in ["mountain-tiger","jangsan-shadow"]: return .7
	if kind=="monk": return .9
	if kind=="adept": return 1.1
	return .8

func recovery_duration() -> float:
	if kind=="jangsanbeom" and jangsan_phase==1: return 1.0
	if kind=="jangsanbeom": return [.68,.82,.6][pattern]
	if boss: return [.95,1.3,1.1][pattern]
	if kind=="mihokbul": return 1.35
	if kind=="hosikchong-wraith": return 1.4
	if kind in ["mountain-tiger","jangsan-shadow"]: return .9
	if kind=="monk": return 1.35
	if kind=="adept": return 1.5
	return 1.2

func begin_attack_vfx() -> void:
	var direction:=Vector2(facing,0)
	if kind=="jangsanbeom": pass
	elif boss:
		if pattern==0: director.vfx.emit_monster("captain-sweep",self,Vector2.ZERO,direction,1.5)
		elif pattern==1: director.vfx.emit_monster("captain-cleave",self,Vector2.ZERO,direction,1.5)
		else: director.vfx.emit_monster("captain-charge-fx",self,Vector2.ZERO,direction,1.5)
	# 부적 도사: 시전·명중 이펙트 없이 날아가는 부적만 쓴다.
	elif kind=="adept": pass
	elif ATTACK_VFX.has(kind): director.vfx.emit_monster(ATTACK_VFX[kind],self,Vector2.ZERO,direction)
	else: director.vfx.emit_monster("musa-slash",self,Vector2.ZERO,direction)
func _ready() -> void:
	boss = kind in ["boss","jangsanbeom"]
	size_factor = 2.0 if kind=="jangsanbeom" else 1.5 if boss else 1.25 if kind=="jangsan-shadow" else 1.0
	max_hp = {"boss":420.0,"jangsanbeom":260.0,"jangsan-shadow":150.0,"mountain-tiger":85.0,"changgui-remnant":70.0,"mihokbul":45.0,"hosikchong-wraith":100.0,"monk":60.0,"adept":20.0,"warrior":30.0}.get(kind,30.0)
	hp = max_hp if hp<0 else hp
	attack = {"boss":10.0,"jangsanbeom":14.0,"jangsan-shadow":11.0,"mountain-tiger":10.0,"changgui-remnant":9.0,"mihokbul":7.0,"hosikchong-wraith":11.0,"monk":12.0,"adept":6.0,"warrior":8.0}.get(kind,8.0)
	speed = {"boss":85.0,"jangsanbeom":120.0,"jangsan-shadow":145.0,"mountain-tiger":130.0,"changgui-remnant":92.0,"mihokbul":72.0,"hosikchong-wraith":0.0,"monk":65.0,"adept":80.0,"warrior":105.0}.get(kind,95.0)
	collision_layer = 4
	collision_mask = 1
	var c := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	var collision_size:Vector2={"jangsanbeom":Vector2(86,52),"jangsan-shadow":Vector2(64,42),"mountain-tiger":Vector2(54,36),"hosikchong-wraith":Vector2(58,34),"mihokbul":Vector2(32,40)}.get(kind,Vector2(28,46)*size_factor)
	box.size = collision_size
	c.position.y = -collision_size.y*.5
	c.shape=box
	collision_shape=c
	add_child(c)
	visual=ActorSprite.new()
	visual.actor=self
	visual.combat=director
	visual.role=kind
	visual.boss=boss
	add_child(visual)
	if kind=="jangsanbeom": configure_jangsan_phase(1)
	queue_redraw()

func set_collision_size(value: Vector2) -> void:
	if not is_instance_valid(collision_shape): return
	var box:=collision_shape.shape as RectangleShape2D
	box.size=value
	collision_shape.position.y=-value.y*.5

func configure_jangsan_phase(value: int) -> void:
	jangsan_phase=clampi(value,1,3)
	max_hp=JANGSAN_PHASE_HP[jangsan_phase]
	hp=max_hp
	state="approach"
	timer=1.0
	pattern=0
	phase_counter=0
	var role:="songaksi"
	if jangsan_phase==1 and is_instance_valid(director) and is_instance_valid(director.world.player):
		role=str(director.world.player.visual.role)
	elif jangsan_phase==2:
		role="jangsan-shadow"
	else:
		role="jangsanbeom"
	visual.set_role(role)
	visual.scale_override=1.0 if jangsan_phase==1 else .8 if jangsan_phase==2 else 1.62
	size_factor=1.0 if jangsan_phase==1 else 1.3 if jangsan_phase==2 else 3.0
	speed=105.0 if jangsan_phase==1 else 145.0 if jangsan_phase==2 else 120.0
	attack=9.0 if jangsan_phase==1 else 12.0 if jangsan_phase==2 else 14.0
	set_collision_size(Vector2(28,46) if jangsan_phase==1 else Vector2(58,38) if jangsan_phase==2 else Vector2(150,90))
	queue_redraw()

func start_jangsan_transition() -> void:
	phase_transitioning=true
	phase_transition_time=0.0
	phase_transition_target=jangsan_phase+1
	phase_transition_swapped=false
	phase_fog_alpha=0.0
	hp=0
	velocity=Vector2.ZERO
	collision_layer=0
	visual.modulate=Color.WHITE
	director.boss_transitioning=true
	director.hit_pause=maxf(director.hit_pause,.28)
	director.message(("닮은 모습이 무너집니다" if jangsan_phase==1 else "그림자가 안개 속으로 무너집니다")+" · 장산범이 모습을 바꿉니다")
	queue_redraw()

func _process(delta: float) -> void:
	if not phase_transitioning: return
	phase_transition_time+=delta
	var progress:=clampf(phase_transition_time/1.8,0.0,1.0)
	if progress<.42:
		phase_fog_alpha=progress/.42
		visual.modulate.a=1.0-phase_fog_alpha
	elif progress<.58:
		phase_fog_alpha=1.0
		visual.modulate.a=0.0
		if not phase_transition_swapped:
			phase_transition_swapped=true
			configure_jangsan_phase(phase_transition_target)
	else:
		phase_fog_alpha=1.0-(progress-.58)/.42
		visual.modulate.a=1.0-phase_fog_alpha
	queue_redraw()
	if progress>=1.0:
		phase_transitioning=false
		phase_fog_alpha=0.0
		visual.modulate=Color.WHITE
		collision_layer=4
		director.boss_transitioning=false
		director.message(("장산범의 그림자 · 2페이즈" if jangsan_phase==2 else "장산범 · 3페이즈"))
		queue_redraw()
func take_damage(amount: float) -> void:
	if dead: return
	if vulnerable>0:
		amount*=1.5
		vulnerable=0
	hp-=amount
	flash=.1
	if hp<=0:
		if kind=="jangsanbeom" and jangsan_phase<3:
			start_jangsan_transition()
			return
		director.vfx.enemy("enemy-spirit-death",global_position+Vector2(0,-8*size_factor),Vector2(facing,0),size_factor)
		dead=true
		hide()
		collision_layer=0
		director.enemy_killed(self)
	queue_redraw()
func pull_to(target: Vector2, duration := .7) -> void:
	if dead: return
	pull_origin=position
	pull_target=target
	pull_remaining=duration
	pull_duration=duration
	state="approach"
	timer=.5
	stun=0
func visible_to_player() -> bool:
	return director.visible_rect().grow(16).has_point(global_position+Vector2(0,-25))
func clear_shot(target: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position+Vector2(0,-30*size_factor),target,1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
func safe_step(direction: float) -> bool:
	var start := global_position+Vector2(direction*32,-16)
	var query := PhysicsRayQueryParameters2D.create(start,start+Vector2(0,60),1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()
func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(director) or director.paused: return
	slow=maxf(0,slow-delta)
	vulnerable=maxf(0,vulnerable-delta)
	if throw_remaining>0:
		throw_remaining=maxf(0,throw_remaining-delta)
		thrown_velocity.y+=1000*delta
		velocity=thrown_velocity
		move_and_slide()
		for other in director.living():
			if other!=self and not throw_hits.has(other.get_instance_id()) and other.position.distance_to(position)<48:
				throw_hits.append(other.get_instance_id())
				other.take_damage(throw_damage)
				take_damage(throw_damage)
		queue_redraw()
		return
	if absf(knockback)>10:
		velocity=Vector2(knockback,velocity.y+1700*delta)
		knockback=move_toward(knockback,0,650*delta)
		move_and_slide()
		return
	flash=maxf(0,flash-delta)
	confusion=maxf(0,confusion-delta)
	if pull_remaining>0:
		pull_remaining=maxf(0,pull_remaining-delta)
		var q:=1-pull_remaining/pull_duration
		position=pull_origin.lerp(pull_target,q*q*(3-2*q))-Vector2(0,sin(q*PI)*15)
		velocity=Vector2.ZERO
		if pull_remaining<=0: stun=.35
		queue_redraw()
		return
	stun=maxf(0,stun-delta)
	velocity.y=minf(1000,velocity.y+1700*delta)
	if stun>0:
		velocity.x=0
		move_and_slide()
		queue_redraw()
		return
	if training_dummy:
		velocity.x=0
		move_and_slide()
		queue_redraw()
		return
	if charge_remaining>0:
		charge_remaining=maxf(0,charge_remaining-delta)
		velocity.x=facing*430
		director.area_effect(global_position+Vector2(facing*34,-22),42,attack,self)
		move_and_slide()
		queue_redraw()
		return
	var target: Vector2 = director.enemy_target(self)
	var difference:=target-(global_position+Vector2(0,-23*size_factor))
	var distance:=difference.length()
	timer=maxf(0,timer-delta)
	if state=="windup":
		velocity.x=0
		if timer<=0:
			release_attack(target)
			state="recover"
			timer=recovery_duration()
	elif state=="recover":
		velocity.x=0
		if timer<=0: state="approach"
	else:
		facing=signf(difference.x) if absf(difference.x)>1 else facing
		var close := absf(difference.x)<(145 if kind=="jangsanbeom" else 95 if boss else 150 if kind in ["mountain-tiger","jangsan-shadow"] else 120 if kind=="hosikchong-wraith" else 80 if kind=="monk" else 52)
		var can_attack := visible_to_player() and clear_shot(target) and absf(difference.y)<120
		if boss: can_attack=visible_to_player() and clear_shot(target)
		if kind in ["adept","mihokbul"]: close=distance<380
		if timer<=0 and can_attack and (close or boss) and director.attack_permission(self):
			if boss:
				if kind=="jangsanbeom" and jangsan_phase==1:
					pattern=0
				else:
					pattern=phase_counter%3
					phase_counter+=1
					if hp<max_hp*.5: phase_counter+=1
					if pattern==0 and distance>150: pattern=1
			attack_direction=difference.normalized()
			state="windup"
			timer=windup_duration()
			begin_attack_vfx()
		else:
			var direction:=facing
			if kind in ["adept","mihokbul"] and distance<200: direction=-facing
			if kind in ["adept","mihokbul"] and distance>=220 and distance<=320: direction=0
			if kind=="hosikchong-wraith": direction=0
			velocity.x=direction*speed*(.45 if slow>0 else 1.0) if safe_step(direction) and absf(difference.y)<150 else 0
	move_and_slide()
	if position.y>810:
		position=director.safe_ground(position.x)
		velocity=Vector2.ZERO
	queue_redraw()
func release_attack(target: Vector2) -> void:
	var origin:=global_position+Vector2(0,-25*size_factor)
	if kind=="jangsanbeom" and jangsan_phase==1:
		director.area_effect(origin+Vector2(facing*34,4),46,attack,self)
	elif kind=="jangsanbeom" and pattern==2:
		charge_remaining=.38
		velocity.x=facing*430
	elif kind=="jangsanbeom" and pattern==1:
		for angle in [-.28,0.0,.28]: director.fire_projectile(origin,attack_direction.rotated(angle),9,false,"spirit",self)
	elif kind=="jangsanbeom":
		director.area_effect(origin+Vector2(facing*72,8),120,attack,self)
	elif boss and pattern==2:
		charge_remaining=.28
		velocity.x=facing*430
	elif boss and pattern==1:
		director.area_effect(origin+Vector2(facing*54,14),105,12,self)
	elif kind=="monk":
		director.area_effect(origin+Vector2(facing*40,0),55,attack,self)
	elif kind=="adept":
		for angle in ([-.3,0.0,.3] if boss else [0.0]):
			director.fire_projectile(origin,attack_direction.rotated(angle),6,false,"talisman",self)
	elif kind=="mihokbul":
		director.fire_projectile(origin,attack_direction,attack,false,"spirit",self)
	elif kind=="hosikchong-wraith":
		director.area_effect(global_position+Vector2(facing*30,-8),92,attack,self)
	elif kind in ["mountain-tiger","jangsan-shadow","changgui-remnant"]:
		charge_remaining=.24 if kind!="changgui-remnant" else .16
	else:
		director.area_effect(origin+Vector2(facing*(52 if boss else 28),0),70 if boss else 38,attack,self)
func _draw() -> void:
	if dead: return
	var s:=size_factor
	if phase_transitioning:
		# Pixelfx weather/fog: several horizontal banks cross at different depths.
		var fog_frame:=int(phase_transition_time*30.0)%360
		var fog_row:=floori(float(fog_frame)/float(JANGSAN_FOG_COLUMNS))
		var fog_source:=Rect2(Vector2(fog_frame%JANGSAN_FOG_COLUMNS,fog_row)*JANGSAN_FOG_FRAME_SIZE,JANGSAN_FOG_FRAME_SIZE)
		var fog_rect:=Rect2(-JANGSAN_FOG_PIVOT+Vector2(0,10),JANGSAN_FOG_FRAME_SIZE)
		draw_texture_rect_region(JANGSAN_FOG_TEXTURE,fog_rect,fog_source,Color(0.72,0.78,0.8,.25+.75*phase_fog_alpha))
		return
	if director.equipment_lab:
		var font=preload("res://assets/fonts/NotoSansKR-Semibold.ttf")
		draw_string(font,Vector2(-24,-84),{"warrior":"퇴마 무사","adept":"부적 도사","monk":"목탁 승려","changgui-remnant":"창귀 잔혼","mihokbul":"미혹불","hosikchong-wraith":"호식총 원귀","mountain-tiger":"산호랑이","jangsan-shadow":"장산범의 그림자","jangsanbeom":"장산범"}.get(kind,"선봉대장"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c7d0bc"))
	if state=="windup":
		draw_arc(Vector2(0,-30*s),42*s,0,TAU,24,Color("e5a86c"),2)
		if boss:
			var font=preload("res://assets/fonts/NotoSansKR-Semibold.ttf")
			var warning:Array=["할퀴기 · 뒤로 회피","목소리 흉내 · 탄막 틈 찾기","흰 번개 · 점프 회피"] if kind=="jangsanbeom" else ["넓은 베기 · 거리 벌리기","내려베기 · 뒤로 회피","돌진 · 점프 회피"]
			draw_string(font,Vector2(-48,-115),warning[pattern],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff0c4"))
		if boss and pattern==1: draw_line(Vector2(-110,0),Vector2(110,0),Color("d76b60"),3)
	if pull_remaining>0 or stun>0: draw_arc(Vector2(0,-28*s),20*s,0,TAU,24,Color("9dcbb8"),2)
	draw_rect(Rect2(-21*s,-69*s,42*s,4),Color("292f39"))
	draw_rect(Rect2(-21*s,-69*s,42*s*maxf(0,hp)/max_hp,4),Color("d68070"))
