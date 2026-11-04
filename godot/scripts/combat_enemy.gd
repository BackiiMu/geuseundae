extends CharacterBody2D
const ActorSprite=preload("res://scripts/actor_sprite.gd")
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

func windup_duration() -> float:
	if boss: return [0.85,1.05,1.2][pattern]
	if kind=="monk": return .9
	if kind=="adept": return 1.1
	return .45

func recovery_duration() -> float:
	if boss and pattern==2: return 1.3
	if kind=="monk": return 1.0
	if boss: return .9
	if kind=="adept": return 1.5
	return .6
func _ready() -> void:
	boss = kind=="boss"
	size_factor = 1.5 if boss else 1.0
	max_hp = 420 if boss else 60 if kind=="monk" else 20 if kind=="adept" else 30
	hp = max_hp if hp<0 else hp
	attack = 10 if boss else 12 if kind=="monk" else 6 if kind=="adept" else 8
	speed = 85 if boss else 65 if kind=="monk" else 80 if kind=="adept" else 105
	collision_layer = 4
	collision_mask = 1
	var c := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(28,46)*size_factor
	c.position.y = -23*size_factor
	c.shape=box
	add_child(c)
	visual=ActorSprite.new()
	visual.actor=self
	visual.combat=director
	visual.role=kind
	visual.boss=boss
	add_child(visual)
	queue_redraw()
func take_damage(amount: float) -> void:
	if dead: return
	if vulnerable>0:
		amount*=1.5
		vulnerable=0
	hp-=amount
	flash=.1
	if hp<=0:
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
		var close := absf(difference.x)<(95 if boss else 80 if kind=="monk" else 52)
		var can_attack := visible_to_player() and clear_shot(target) and absf(difference.y)<120
		if boss: can_attack=visible_to_player() and clear_shot(target)
		if kind=="adept": close=distance<380
		if timer<=0 and can_attack and (close or boss) and director.attack_permission(self):
			if boss:
				pattern=phase_counter%3
				phase_counter+=1
				if hp<max_hp*.5: phase_counter+=1
				if pattern==0 and distance>150: pattern=1
			attack_direction=difference.normalized()
			state="windup"
			timer=windup_duration()
		else:
			var direction:=facing
			if kind=="adept" and distance<200: direction=-facing
			if kind=="adept" and distance>=220 and distance<=320: direction=0
			velocity.x=direction*speed*(.45 if slow>0 else 1.0) if safe_step(direction) and absf(difference.y)<150 else 0
	move_and_slide()
	if position.y>810:
		position=director.safe_ground(position.x)
		velocity=Vector2.ZERO
	queue_redraw()
func release_attack(target: Vector2) -> void:
	var origin:=global_position+Vector2(0,-25*size_factor)
	if boss and pattern==2:
		director.area_effect(global_position+Vector2(0,-12),110,12,self)
		director.fire_projectile(origin,Vector2.LEFT,12,false,"wave",self)
		director.fire_projectile(origin,Vector2.RIGHT,12,false,"wave",self)
	elif kind=="monk":
		director.area_effect(origin+Vector2(facing*40,0),55,attack,self)
	elif kind=="adept" or (boss and pattern==1):
		for angle in ([-.3,0.0,.3] if boss else [0.0]):
			director.fire_projectile(origin,attack_direction.rotated(angle),6,false,"talisman",self)
	else:
		director.area_effect(origin+Vector2(facing*(52 if boss else 28),0),70 if boss else 38,attack,self)
func _draw() -> void:
	if dead: return
	var s:=size_factor
	if director.equipment_lab:
		var font=preload("res://assets/fonts/NotoSansKR-Semibold.ttf")
		draw_string(font,Vector2(-24,-84),{"warrior":"퇴마 무사","adept":"부적 도사","monk":"목탁 승려"}.get(kind,"선봉대장"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c7d0bc"))
	if state=="windup":
		draw_arc(Vector2(0,-30*s),42*s,0,TAU,24,Color("e5a86c"),2)
		if boss:
			var font=preload("res://assets/fonts/NotoSansKR-Semibold.ttf")
			draw_string(font,Vector2(-48,-115),["베기 · 거리 벌리기","부적 · 점프 회피","충격파 · 점프 회피"][pattern],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff0c4"))
		if boss and pattern==2: draw_line(Vector2(-110,0),Vector2(110,0),Color("d76b60"),3)
	if pull_remaining>0 or stun>0: draw_arc(Vector2(0,-28*s),20*s,0,TAU,24,Color("9dcbb8"),2)
	draw_rect(Rect2(-21*s,-69*s,42*s,4),Color("292f39"))
	draw_rect(Rect2(-21*s,-69*s,42*s*maxf(0,hp)/max_hp,4),Color("d68070"))
