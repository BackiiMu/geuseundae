extends Node2D
# Generated raster atlases: 8 columns, 4 rows; all poses share a feet pivot.
static var texture_cache: Dictionary = {}
var actor: CharacterBody2D
var combat: Node2D
var role := "songaksi"
var boss := false
var texture: Texture2D
var clock := 0.0
var frame_index := 0
var action_time := 0.0
var action_duration := .25
var action_mode := "attack"
var shader_material: ShaderMaterial
var animation := "idle"
var paused_last := false
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var key: String="warrior" if role=="boss" else role
	var path: String="res://assets/actors/source/"+key+"-v1.png"
	if not texture_cache.has(key) and ResourceLoader.exists(path): texture_cache[key]=load(path)
	texture=texture_cache.get(key)
	var shader:=Shader.new()
	shader.code="shader_type canvas_item; uniform float flash=0.; uniform vec4 tint:source_color=vec4(1.); void fragment(){vec4 p=texture(TEXTURE,UV);if(p.a<0.02){discard;}COLOR=vec4(mix(p.rgb*tint.rgb,vec3(1.),flash),p.a*tint.a);}"
	shader_material=ShaderMaterial.new()
	shader_material.shader=shader
	material=shader_material
func play_attack(duration := .25,windup := false) -> void:
	action_duration=duration
	action_time=duration
	action_mode="windup" if windup else "attack"
func release_attack() -> void:
	action_duration=.2
	action_time=.2
	action_mode="release"
func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor): return
	if is_instance_valid(combat) and combat.paused:
		paused_last=true
		return
	paused_last=false
	clock+=delta
	action_time=maxf(0,action_time-delta)
	var tint:=Color.WHITE
	var flash:=0.0
	if role=="songaksi":
		var hurt:float=combat.hurt_timer if is_instance_valid(combat) else 0.0
		if hurt>.48:
			animation="hurt"
			frame_index=30+int(clock*12)%2
		elif actor.dash_time>0:
			animation="dash"
			frame_index=28+int(clock*18)%2
		elif action_time>0:
			animation=action_mode
			var phase:=1-action_time/action_duration
			frame_index=16+(mini(1,int(phase*2)) if action_mode=="windup" else 2+mini(5,int(phase*6)) if action_mode=="release" else mini(7,int(phase*8)))
		elif not actor.is_on_floor():
			animation="jump" if actor.velocity.y<0 else "fall"
			frame_index=(24 if actor.velocity.y<0 else 26)+int(clock*8)%2
		elif absf(actor.velocity.x)>15:
			animation="run"
			frame_index=8+int(clock*12)%8
		else:
			animation="idle"
			frame_index=int(clock*7)%8
		if hurt>0:
			flash=1.0 if hurt>.57 else 0.0
			tint.a=.45 if int(clock*20)%2==0 else 1.0
	else:
		flash=1.0 if actor.flash>.055 else 0.0
		if actor.slow>0: tint=Color("a2cdda")
		if actor.vulnerable>0: tint=Color("e2acc4")
		if actor.flash>0:
			animation="hurt"
			frame_index=24+int(clock*16)%4
		elif actor.pull_remaining>0 or actor.throw_remaining>0 or actor.stun>0 or absf(actor.knockback)>10:
			animation="stagger"
			frame_index=28+int(clock*10)%4
		elif actor.state=="windup":
			animation="windup"
			var duration:float=1.2 if actor.boss else .9 if actor.kind=="monk" else .7 if actor.kind=="adept" else .45
			frame_index=16+clampi(int((1-actor.timer/duration)*4),0,3)
		elif actor.state=="recover":
			animation="recover"
			frame_index=20+clampi(int((1-actor.timer/(1.0 if actor.kind=="monk" else .9 if actor.boss else .6))*4),0,3)
		elif absf(actor.velocity.x)>8:
			animation="run"
			frame_index=8+int(clock*(8 if role=="monk" else 11))%8
		else:
			animation="idle"
			frame_index=int(clock*6)%8
	shader_material.set_shader_parameter("flash",flash)
	shader_material.set_shader_parameter("tint",tint)
	queue_redraw()
func _draw() -> void:
	if texture==null or not is_instance_valid(actor): return
	var scale_factor:=1.5 if boss else 1.0
	var direction:float=actor.facing
	var source_size:=Vector2(texture.get_width()/8.0,texture.get_height()/4.0)
	var source:=Rect2(Vector2(frame_index%8,frame_index/8)*source_size,source_size)
	draw_set_transform(Vector2.ZERO,0,Vector2(direction*scale_factor,scale_factor))
	draw_texture_rect_region(texture,Rect2(-24,-62,48,64),source)
	draw_set_transform(Vector2.ZERO)
