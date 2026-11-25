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
var dying := false
var death_time := 0.0
var boss := false
var pull_remaining := 0.0
var pull_origin := Vector2.ZERO
var pull_target := Vector2.ZERO
var pull_duration := .7
var size_factor := 1.0
var flash := 0.0
var slow := 0.0
var vulnerable := 0.0
var one_hit_vulnerable := false
var burn := 0.0
var burn_tick := 0.0
var burn_damage := 1.0
var burn_interval := .5
var shock := 0.0   # 감전 상태이상 본체는 따로 구현. 여기서는 걸린 시간만 기록한다.
var frozen := 0.0
var frozen_then_slow := 0.0
var knockback := 0.0
var thrown_velocity := Vector2.ZERO
var throw_remaining := 0.0
var throw_damage := 0.0
var throw_hits: Array = []
var charge_remaining := 0.0
var special_cooldown := 12.0
var collision_shape: CollisionShape2D
var jangsan_phase := 0
var phase_transitioning := false
var phase_transition_time := 0.0
var phase_transition_target := 0
var phase_transition_swapped := false
var phase_fog_alpha := 0.0
var slam_pending := false
var slam_horizontal := 0.0
var hawk_dive_remaining := 0.0
var hawk_hit := false
var hawk_hover_origin := Vector2.ZERO
var chain_pull_remaining := 0.0
var chain_pull_origin := Vector2.ZERO
var chain_pull_target := Vector2.ZERO
var hound_hit := false
var soul_barrier_hp := 0.0
var soul_barrier_layers := 0
var reflect_window := 0.0
var dongja_rampage := false
const JANGSAN_PHASE_HP := [0.0,260.0,450.0,850.0]
# 몬스터별 공격 이펙트 시트(godot/assets/monster_vfx). 원점은 발이고 판정 범위에 맞춰 만들었다.
const ATTACK_VFX := {"warrior":"musa-slash","monk":"monk-moktak","changgui-remnant":"changgui-claw","mountain-tiger":"tiger-claw","jangsan-shadow":"shadow-claw","mihokbul":"mihokbul-cast","hosikchong-wraith":"hosikchong-erupt"}

func windup_duration() -> float:
	if kind=="grand-exorcist": return [.75,1.15,1.0][pattern]
	if kind=="royal-exorcist-captain": return [.68,1.0,.82][pattern]
	if kind in ["wall-archer","crossbow-exorcist","ward-reader","record-scribe","moving-ward-reader","greater-lantern-keeper"]: return 1.05
	if kind in ["banner-bearer","high-shaman"]: return .95
	if kind in ["royal-shield","iron-executioner"]: return .78
	if kind=="prison-shaman": return [.72,1.0,.85][pattern]
	if kind=="chain-constable": return .9
	if kind=="shield-guard": return .72
	if kind=="brazier-ritualist": return .95
	if kind=="sealed-lantern-keeper": return 1.05
	if kind=="tracking-hound": return .55
	if kind=="hunting-hawk": return .62
	if kind=="exorcist-spearman": return .72
	if kind=="exorcist-archer": return .92
	if kind=="bell-exorcist": return 1.05
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
	if kind=="grand-exorcist": return [1.05,1.55,1.35][pattern]
	if kind=="royal-exorcist-captain": return [1.0,1.4,1.2][pattern]
	if kind in ["wall-archer","crossbow-exorcist","ward-reader","record-scribe","moving-ward-reader","greater-lantern-keeper"]: return 1.55
	if kind in ["banner-bearer","high-shaman"]: return 1.4
	if kind in ["royal-shield","iron-executioner"]: return 1.2
	if kind=="prison-shaman": return [.95,1.45,1.1][pattern]
	if kind=="chain-constable": return 1.45
	if kind=="shield-guard": return 1.15
	if kind=="brazier-ritualist": return 1.8
	if kind=="sealed-lantern-keeper": return 1.65
	if kind=="tracking-hound": return 1.25
	if kind=="hunting-hawk": return 1.0
	if kind=="exorcist-spearman": return 1.05
	if kind=="exorcist-archer": return 1.5
	if kind=="bell-exorcist": return 1.75
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
	elif kind in ["warrior","adept","exorcist-archer","bell-exorcist","hunting-hawk","exorcist-spearman","chain-constable","shield-guard","brazier-ritualist","sealed-lantern-keeper","tracking-hound","royal-shield","wall-archer","crossbow-exorcist","banner-bearer","ward-reader","elite-hawk","high-shaman","record-scribe","moving-ward-reader","iron-executioner","greater-lantern-keeper"]: pass
	elif ATTACK_VFX.has(kind): director.vfx.emit_monster(ATTACK_VFX[kind],self,Vector2.ZERO,direction)
	else: director.vfx.emit_monster("musa-slash",self,Vector2.ZERO,direction)
func _ready() -> void:
	boss = kind in ["boss","jangsanbeom","soul-warden","prison-shaman","royal-exorcist-captain","grand-exorcist"]
	size_factor = 2.0 if kind=="jangsanbeom" else 1.7 if kind=="soul-warden" else 1.5 if boss else 1.25 if kind=="jangsan-shadow" else 1.0
	max_hp = {"grand-exorcist":980.0,"royal-exorcist-captain":720.0,"royal-shield":180.0,"wall-archer":82.0,"crossbow-exorcist":105.0,"banner-bearer":125.0,"ward-reader":95.0,"elite-hawk":52.0,"high-shaman":135.0,"record-scribe":100.0,"moving-ward-reader":115.0,"iron-executioner":210.0,"greater-lantern-keeper":145.0,"boss":420.0,"prison-shaman":280.0,"soul-warden":760.0,"jangsanbeom":260.0,"jangsan-shadow":150.0,"mountain-tiger":85.0,"changgui-remnant":70.0,"mihokbul":45.0,"hosikchong-wraith":100.0,"monk":60.0,"adept":20.0,"warrior":30.0,"exorcist-spearman":95.0,"exorcist-archer":70.0,"bell-exorcist":80.0,"hunting-hawk":32.0,"chain-constable":105.0,"shield-guard":150.0,"brazier-ritualist":75.0,"sealed-lantern-keeper":85.0,"tracking-hound":48.0}.get(kind,30.0)
	hp = max_hp if hp<0 else hp
	attack = {"grand-exorcist":18.0,"royal-exorcist-captain":16.0,"royal-shield":15.0,"wall-archer":12.0,"crossbow-exorcist":15.0,"banner-bearer":11.0,"ward-reader":12.0,"elite-hawk":10.0,"high-shaman":14.0,"record-scribe":13.0,"moving-ward-reader":14.0,"iron-executioner":18.0,"greater-lantern-keeper":15.0,"boss":10.0,"prison-shaman":12.0,"soul-warden":12.0,"jangsanbeom":14.0,"jangsan-shadow":11.0,"mountain-tiger":10.0,"changgui-remnant":9.0,"mihokbul":7.0,"hosikchong-wraith":11.0,"monk":12.0,"adept":6.0,"warrior":8.0,"exorcist-spearman":14.0,"exorcist-archer":11.0,"bell-exorcist":7.0,"hunting-hawk":8.0,"chain-constable":12.0,"shield-guard":14.0,"brazier-ritualist":8.0,"sealed-lantern-keeper":10.0,"tracking-hound":8.0}.get(kind,8.0)
	speed = {"grand-exorcist":76.0,"royal-exorcist-captain":82.0,"royal-shield":52.0,"wall-archer":68.0,"crossbow-exorcist":60.0,"banner-bearer":64.0,"ward-reader":58.0,"elite-hawk":130.0,"high-shaman":60.0,"record-scribe":56.0,"moving-ward-reader":72.0,"iron-executioner":62.0,"greater-lantern-keeper":50.0,"boss":85.0,"soul-warden":72.0,"jangsanbeom":120.0,"jangsan-shadow":145.0,"mountain-tiger":130.0,"changgui-remnant":92.0,"mihokbul":72.0,"hosikchong-wraith":0.0,"monk":65.0,"adept":80.0,"warrior":105.0,"exorcist-spearman":72.0,"exorcist-archer":78.0,"bell-exorcist":52.0,"hunting-hawk":115.0,"chain-constable":68.0,"shield-guard":55.0,"brazier-ritualist":58.0,"sealed-lantern-keeper":52.0,"tracking-hound":145.0}.get(kind,95.0)
	collision_layer = 4
	collision_mask = 1
	var c := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	var collision_size:Vector2={"soul-warden":Vector2(42,74),"jangsanbeom":Vector2(86,52),"jangsan-shadow":Vector2(64,42),"mountain-tiger":Vector2(54,36),"hosikchong-wraith":Vector2(58,34),"mihokbul":Vector2(32,40),"exorcist-spearman":Vector2(34,52),"exorcist-archer":Vector2(28,48),"bell-exorcist":Vector2(32,54),"hunting-hawk":Vector2(42,26),"chain-constable":Vector2(32,52),"shield-guard":Vector2(38,52),"brazier-ritualist":Vector2(30,54),"sealed-lantern-keeper":Vector2(32,52),"tracking-hound":Vector2(48,28)}.get(kind,Vector2(28,46)*size_factor)
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
	if kind in ["hunting-hawk","elite-hawk"]: hawk_hover_origin=position
	if kind=="soul-warden": special_cooldown=director.rng.randf_range(10.0,15.0)
	if kind=="jangsanbeom": configure_jangsan_phase(1)
	if kind=="prison-shaman":
		soul_barrier_hp=240.0
		soul_barrier_layers=3
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
func take_damage(amount: float, ignore_vulnerability := false, number_color := Color("f3e6c8"), critical := false) -> void:
	if dead or dying: return
	if kind=="prison-shaman" and soul_barrier_hp>0 and not ignore_vulnerability:
		if reflect_window>0:
			var reflected:Vector2=(director.world.player.global_position-global_position).normalized()
			director.fire_projectile(global_position+Vector2(0,-62),reflected,minf(18.0,amount*.65),false,"spirit",self)
			return
		var old_layers:=soul_barrier_layers
		soul_barrier_hp=maxf(0.0,soul_barrier_hp-amount)
		soul_barrier_layers=ceili(soul_barrier_hp/80.0)
		director.show_damage_number(global_position+Vector2(0,-92),amount,Color("7da6b5"),critical)
		flash=.1
		if soul_barrier_layers<old_layers:
			stun=1.5
			if soul_barrier_layers==0:
				dongja_rampage=true
				visual.set_role("dongja-possession")
				speed=90.0
			director.message("창귀 해방 · "+("동자귀가 귀문옥주를 삼켰습니다" if soul_barrier_layers==0 else "방벽이 한 겹 무너졌습니다"))
		queue_redraw()
		return
	if kind in ["shield-guard","royal-shield"] and not ignore_vulnerability and is_instance_valid(director) and is_instance_valid(director.world.player):
		var player_side:=signf(director.world.player.global_position.x-global_position.x)
		# 방패가 향한 정면에서 들어온 공격만 크게 줄고, 뒤잡기는 그대로 들어간다.
		if player_side==facing:
			amount*=.2
			number_color=Color("8d9aa0")
	if one_hit_vulnerable and not ignore_vulnerability:
		amount*=1.5
		one_hit_vulnerable=false
		vulnerable=0.0
	elif vulnerable>0 and not ignore_vulnerability:
		amount*=1.5
	if is_instance_valid(director): director.show_damage_number(global_position+Vector2(0,-55*size_factor),amount,number_color,critical)
	hp-=amount
	flash=.1
	if hp<=0:
		if kind=="jangsanbeom" and jangsan_phase<3:
			start_jangsan_transition()
			return
		if kind=="soul-warden":
			dying=true
			death_time=0.0
			velocity=Vector2.ZERO
			collision_layer=0
			state="death"
			queue_redraw()
			return
		director.vfx.enemy("enemy-spirit-death",global_position+Vector2(0,-8*size_factor),Vector2(facing,0),size_factor)
		dead=true
		hide()
		collision_layer=0
		director.enemy_killed(self)
	queue_redraw()
func apply_burn(duration := 3.0, damage := 1.0, interval := .5) -> void:
	if dead or dying: return
	if burn<=0: burn_tick=interval
	burn=maxf(burn,duration)
	burn_damage=damage
	burn_interval=interval
func tick_burn(delta: float) -> void:
	if burn<=0 or dead or dying: return
	burn=maxf(0.0,burn-delta)
	burn_tick-=delta
	if burn_tick<=0:
		burn_tick+=burn_interval
		take_damage(burn_damage*director.weather.burn_scale(),true,Color("e27a32"),false)
		flash=0.0
func apply_shock(duration := 2.0) -> void:
	if dead or dying: return
	shock=maxf(shock,duration)
# 짧은 빙결(행동 불가) 뒤 둔화가 이어진다. 보스는 호출하는 쪽에서 제외한다.
func apply_freeze(duration := .8, slow_after := 3.0) -> void:
	if dead or dying: return
	frozen=maxf(frozen,duration)
	frozen_then_slow=maxf(frozen_then_slow,slow_after)
	stun=maxf(stun,duration)
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
	if dying:
		death_time+=delta
		velocity=Vector2.ZERO
		queue_redraw()
		if death_time>=.95:
			dead=true
			hide()
			director.vfx.enemy("enemy-spirit-death",global_position+Vector2(0,-8*size_factor),Vector2(facing,0),size_factor)
			director.enemy_killed(self)
		return
	tick_burn(delta)
	if dead: return
	slow=maxf(0,slow-delta*director.weather.slow_decay())
	shock=maxf(0,shock-delta)
	if frozen>0:
		frozen=maxf(0,frozen-delta)
		if frozen<=0:
			slow=maxf(slow,frozen_then_slow)
			frozen_then_slow=0.0
	vulnerable=maxf(0,vulnerable-delta)
	if throw_remaining>0:
		throw_remaining=maxf(0,throw_remaining-delta)
		thrown_velocity.y+=1000*delta
		velocity=thrown_velocity
		move_and_slide()
		for other in director.living():
			if other!=self and not throw_hits.has(other.get_instance_id()) and other.position.distance_to(position)<48:
				throw_hits.append(other.get_instance_id())
				director.damage_enemy(other,throw_damage)
				director.damage_enemy(self,throw_damage)
		queue_redraw()
		return
	if absf(knockback)>10:
		velocity=Vector2(knockback,velocity.y+1700*delta)
		knockback=move_toward(knockback,0,650*delta)
		move_and_slide()
		return
	flash=maxf(0,flash-delta)
	reflect_window=maxf(0.0,reflect_window-delta)
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
	if chain_pull_remaining>0:
		chain_pull_remaining=maxf(0.0,chain_pull_remaining-delta)
		var duration:=.32
		var q:=1.0-chain_pull_remaining/duration
		director.world.player.position=chain_pull_origin.lerp(chain_pull_target,q*q*(3.0-2.0*q))
	if kind=="soul-warden":
		if director.warden_pattern_active:
			if director.warden_pattern in ["capture","heart"]:
				velocity=Vector2.ZERO
				queue_redraw()
				return
		else:
			if stun<=0: special_cooldown=maxf(0.0,special_cooldown-delta)
			if special_cooldown<=0 and state=="approach" and director.start_random_warden_pattern(self):
				velocity=Vector2.ZERO
				queue_redraw()
				return
	if kind in ["hunting-hawk","elite-hawk"]:
		tick_hunting_hawk(delta)
		return
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
		velocity.x=facing*(360 if kind=="tracking-hound" else 430)
		director.area_effect(global_position+Vector2(facing*34,-22),42,attack,self)
		if kind=="tracking-hound" and not hound_hit and director.world.player.position.distance_to(global_position)<54:
			hound_hit=true
			director.world.player.velocity.x=facing*170
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
		velocity.x=slam_horizontal if kind=="exorcist-spearman" and slam_pending and not is_on_floor() else 0
		if timer<=0: state="approach"
	else:
		facing=signf(difference.x) if absf(difference.x)>1 else facing
		var close := absf(difference.x)<(145 if kind=="jangsanbeom" else 95 if boss else 150 if kind in ["mountain-tiger","jangsan-shadow"] else 300 if kind=="chain-constable" else 390 if kind in ["brazier-ritualist","sealed-lantern-keeper"] else 105 if kind=="tracking-hound" else 72 if kind=="shield-guard" else 120 if kind=="hosikchong-wraith" else 80 if kind=="monk" else 52)
		var can_attack := visible_to_player() and clear_shot(target) and absf(difference.y)<120
		if boss: can_attack=visible_to_player() and clear_shot(target)
		if kind in ["adept","mihokbul","exorcist-archer","bell-exorcist","brazier-ritualist","sealed-lantern-keeper","wall-archer","crossbow-exorcist","banner-bearer","ward-reader","high-shaman","record-scribe","moving-ward-reader","greater-lantern-keeper"]: close=distance<440
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
			if kind in ["adept","mihokbul","exorcist-archer","bell-exorcist","brazier-ritualist","sealed-lantern-keeper","wall-archer","crossbow-exorcist","banner-bearer","ward-reader","high-shaman","record-scribe","moving-ward-reader","greater-lantern-keeper"] and distance<200: direction=-facing
			if kind in ["adept","mihokbul","exorcist-archer","bell-exorcist","brazier-ritualist","sealed-lantern-keeper","wall-archer","crossbow-exorcist","banner-bearer","ward-reader","high-shaman","record-scribe","moving-ward-reader","greater-lantern-keeper"] and distance>=220 and distance<=340: direction=0
			if kind=="hosikchong-wraith": direction=0
			velocity.x=direction*speed*(.45 if slow>0 else 1.0) if safe_step(direction) and absf(difference.y)<150 else 0
	move_and_slide()
	if kind=="exorcist-spearman" and slam_pending and is_on_floor():
		slam_pending=false
		slam_horizontal=0
		director.area_effect(global_position+Vector2(0,-8),58,attack,self)
	if position.y>810:
		position=director.safe_ground(position.x)
		velocity=Vector2.ZERO
	queue_redraw()

func tick_hunting_hawk(delta: float) -> void:
	flash=maxf(0,flash-delta)
	if training_dummy:
		velocity=Vector2.ZERO
		queue_redraw()
		return
	var target:Vector2=director.enemy_target(self)
	var center:=global_position+Vector2(0,-12)
	var difference:=target-center
	facing=signf(difference.x) if absf(difference.x)>1 else facing
	timer=maxf(0,timer-delta)
	if hawk_dive_remaining>0:
		hawk_dive_remaining=maxf(0,hawk_dive_remaining-delta)
		position+=velocity*delta
		if not hawk_hit and (global_position+Vector2(0,-10)).distance_to(target)<38:
			hawk_hit=true
			director.hurt(attack)
		if hawk_dive_remaining<=0:
			state="recover"
			timer=recovery_duration()
			velocity=Vector2.ZERO
	elif state=="windup":
		velocity=Vector2.ZERO
		if timer<=0:
			release_attack(target)
	elif state=="recover":
		var recover_target:=target+Vector2(-facing*120,-145)
		position=position.move_toward(recover_target,150*delta)
		if timer<=0: state="approach"
	else:
		var hover_target:=target+Vector2(-facing*135,-135+sin(Time.get_ticks_msec()*.004+uid)*18)
		position=position.move_toward(hover_target,speed*delta)
		if timer<=0 and visible_to_player() and director.attack_permission(self):
			attack_direction=difference.normalized()
			state="windup"
			timer=windup_duration()
			begin_attack_vfx()
	queue_redraw()

func release_attack(target: Vector2) -> void:
	var origin:=global_position+Vector2(0,-25*size_factor)
	if kind=="prison-shaman":
		if pattern==1:
			reflect_window=1.2
		elif pattern==2:
			for angle in [-.34,0.0,.34]: director.fire_projectile(origin,attack_direction.rotated(angle),attack,false,"spirit",self)
		else:
			director.area_effect(origin+Vector2(facing*62,5),82,attack,self)
	elif kind=="grand-exorcist":
		if pattern==0:
			director.area_effect(origin+Vector2(facing*72,4),125,attack,self)
		elif pattern==1:
			for angle in [-.5,-.25,0.0,.25,.5]: director.fire_projectile(origin,attack_direction.rotated(angle),attack,false,"talisman",self)
		else:
			for offset in [-110.0,0.0,110.0]: director.queue_enemy_strike("enemy-seal",target+Vector2(offset,0),.85+absf(offset)*.002,attack,self)
	elif kind=="royal-exorcist-captain":
		if pattern==0:
			director.area_effect(origin+Vector2(facing*65,4),90,attack,self)
		elif pattern==1:
			for offset in [-88.0,0.0,88.0]: director.queue_enemy_strike("enemy-arrow-rain",target+Vector2(offset,0),.7+absf(offset)*.002,attack,self)
		else:
			charge_remaining=.34
			velocity.x=facing*430
	elif kind=="jangsanbeom" and jangsan_phase==1:
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
		# 희미한 먼지 끝이 아니라 목탁 충격의 짙은 핵심부에만 판정을 둔다.
		director.area_effect(origin+Vector2(facing*2,0),45,attack,self)
	elif kind=="adept":
		for angle in ([-.3,0.0,.3] if boss else [0.0]):
			director.fire_projectile(origin,attack_direction.rotated(angle),6,false,"talisman",self)
	elif kind=="warrior":
		# The blade trail begins only when the sword comes down, not during the wind-up.
		director.vfx.emit_monster("musa-slash",self,Vector2(facing*25,-21),Vector2(facing,0),1.24)
		director.area_effect(origin+Vector2(facing*28,0),38,attack,self)
	elif kind=="mihokbul":
		director.fire_projectile(origin,attack_direction,attack,false,"spirit",self)
	elif kind=="hosikchong-wraith":
		director.area_effect(global_position+Vector2(facing*30,-8),92,attack,self)
	elif kind in ["hunting-hawk","elite-hawk"]:
		hawk_hit=false
		hawk_dive_remaining=.46
		velocity=(target-(global_position+Vector2(0,-12))).normalized()*420
		state="dive"
	elif kind=="exorcist-spearman":
		slam_pending=true
		slam_horizontal=clampf(target.x-global_position.x,-180.0,180.0)*1.7
		velocity=Vector2(slam_horizontal,-430)
	elif kind=="exorcist-archer":
		for offset in [-62.0,0.0,62.0]: director.queue_enemy_strike("enemy-arrow-rain",target+Vector2(offset,0),.72+absf(offset)*.003,attack,self)
	elif kind=="bell-exorcist":
		director.queue_enemy_strike("enemy-seal",target,.85,attack,self)
	elif kind=="chain-constable":
		if global_position.distance_to(target)<330 and clear_shot(target):
			chain_pull_origin=director.world.player.position
			chain_pull_target=director.safe_ground(global_position.x+facing*48)
			chain_pull_remaining=.32
		else:
			director.area_effect(origin+Vector2(facing*38,0),52,attack,self)
	elif kind=="shield-guard":
		director.area_effect(origin+Vector2(facing*42,4),56,attack,self)
	elif kind=="brazier-ritualist":
		director.queue_enemy_strike("enemy-brazier-fire",target,.75,attack,self)
	elif kind=="sealed-lantern-keeper":
		director.queue_enemy_strike("enemy-lantern-burst",target,1.4,attack,self)
	elif kind=="tracking-hound":
		hound_hit=false
		charge_remaining=.34
	elif kind in ["royal-shield","iron-executioner"]:
		director.area_effect(origin+Vector2(facing*48,2),64 if kind=="royal-shield" else 78,attack,self)
	elif kind=="wall-archer":
		for offset in [-54.0,0.0,54.0]: director.queue_enemy_strike("enemy-arrow-rain",target+Vector2(offset,0),.72+absf(offset)*.003,attack,self)
	elif kind=="crossbow-exorcist":
		director.fire_projectile(origin,attack_direction,attack,false,"wave",self)
	elif kind in ["ward-reader","record-scribe","moving-ward-reader"]:
		director.queue_enemy_strike("enemy-seal",target,.8,attack,self)
	elif kind=="banner-bearer":
		director.queue_enemy_strike("enemy-brazier-fire",target,.75,attack,self)
	elif kind=="high-shaman":
		for angle in [-.28,0.0,.28]: director.fire_projectile(origin,attack_direction.rotated(angle),attack,false,"spirit",self)
	elif kind=="greater-lantern-keeper":
		director.queue_enemy_strike("enemy-lantern-burst",target,1.2,attack,self)
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
		draw_string(font,Vector2(-24,-84),{"warrior":"퇴마 무사","adept":"부적 도사","monk":"목탁 승려","changgui-remnant":"창귀 잔혼","mihokbul":"미혹불","hosikchong-wraith":"호식총 원귀","mountain-tiger":"산호랑이","jangsan-shadow":"장산범의 그림자","jangsanbeom":"장산범","exorcist-spearman":"퇴마 창수","exorcist-archer":"퇴마 궁수","bell-exorcist":"방울 술사","hunting-hawk":"사냥매","chain-constable":"쇠사슬 포졸","shield-guard":"방패 군졸","brazier-ritualist":"화로 술사","sealed-lantern-keeper":"봉인등 지기","tracking-hound":"추적견"}.get(kind,"선봉대장"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("c7d0bc"))
	if state=="windup":
		draw_arc(Vector2(0,-30*s),42*s,0,TAU,24,Color("e5a86c"),2)
		if kind=="chain-constable": draw_line(Vector2(0,-34),Vector2(facing*300,-34),Color(0.66,0.46,0.35,.58),2)
		elif kind=="tracking-hound": draw_line(Vector2(0,-10),Vector2(facing*150,-10),Color(0.72,0.3,0.2,.55),3)
		if boss:
			var font=preload("res://assets/fonts/NotoSansKR-Semibold.ttf")
			var warning:Array=["창귀 후려치기 · 뒤로 회피","동자 흉내 · 공격 중지 또는 뒤잡기","원혼 방출 · 탄막 틈 찾기"] if kind=="prison-shaman" else ["할퀴기 · 뒤로 회피","목소리 흉내 · 탄막 틈 찾기","흰 번개 · 점프 회피"] if kind=="jangsanbeom" else ["넓은 베기 · 거리 벌리기","내려베기 · 뒤로 회피","돌진 · 점프 회피"]
			draw_string(font,Vector2(-48,-115),warning[pattern],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("fff0c4"))
		if boss and pattern==1: draw_line(Vector2(-110,0),Vector2(110,0),Color("d76b60"),3)
	if pull_remaining>0 or stun>0: draw_arc(Vector2(0,-28*s),20*s,0,TAU,24,Color("9dcbb8"),2)
	if kind=="prison-shaman" and soul_barrier_hp>0:
		for layer in range(soul_barrier_layers):
			draw_arc(Vector2(0,-48),52+layer*9,PI*.15,PI*1.85,36,Color(0.32,0.52,0.62,.9 if reflect_window>0 else .55),3)
	draw_rect(Rect2(-21*s,-69*s,42*s,4),Color("292f39"))
	draw_rect(Rect2(-21*s,-69*s,42*s*maxf(0,hp)/max_hp,4),Color("d68070"))
