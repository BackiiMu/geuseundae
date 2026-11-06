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
var dash_trail_time := 0.0
var dash_trail_direction := Vector2.RIGHT
var was_dashing := false
var dash_fx_texture: Texture2D
var dash_fx_info: Dictionary = {}
var dash_fx_age := 1.0
var atlas := true
var scale_override := 1.0
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	load_role_texture()
	if role=="songaksi":
		var vfx_manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/vfx/manifest.json"))
		dash_fx_info=vfx_manifest.get("dash-2",{})
		if not dash_fx_info.is_empty(): dash_fx_texture=load(dash_fx_info["path"])
	var shader:=Shader.new()
	shader.code="shader_type canvas_item; uniform float flash=0.; uniform vec4 tint:source_color=vec4(1.); varying vec4 draw_color; void vertex(){draw_color=COLOR;} void fragment(){vec4 p=texture(TEXTURE,UV);if(p.a<0.02){discard;}COLOR=vec4(mix(p.rgb*tint.rgb,vec3(1.),flash),p.a*tint.a)*draw_color;}"
	shader_material=ShaderMaterial.new()
	shader_material.shader=shader
	material=shader_material

func set_role(value: String) -> void:
	role=value
	load_role_texture()
	queue_redraw()

func load_role_texture() -> void:
	var key: String="warrior" if role=="boss" else role
	var path: String="res://assets/actors/source/"+key+"-v1.png"
	atlas=ResourceLoader.exists(path)
	if atlas:
		if not texture_cache.has(key): texture_cache[key]=load(path)
		texture=texture_cache[key]
		return
	var fallback:String=str({"mongdal":"res://assets/actors/concepts/mongdal-ghost-game-v1.png", "changgui":"res://assets/actors/concepts/changwi-peasant-game-v2.png"}.get(role,""))
	texture=load(fallback) if not fallback.is_empty() and ResourceLoader.exists(fallback) else null
func play_attack(duration := .25,windup := false) -> void:
	action_duration=duration
	action_time=duration
	action_mode="windup" if windup else "attack"
func release_attack() -> void:
	action_duration=.2
	action_time=.2
	action_mode="release"

func is_player_actor() -> bool:
	return is_instance_valid(actor) and actor.has_method("start_dash")

func draw_size() -> Vector2:
	return {
		"mihokbul":Vector2(46,52),
		"hosikchong-wraith":Vector2(76,58),
		"mountain-tiger":Vector2(78,58),
		"jangsan-shadow":Vector2(92,66),
		"jangsanbeom":Vector2(138,100)
	}.get(role,Vector2(48,64))

func new_heart_frame_metrics(frame: int) -> Vector3:
	# Generated Mongdal/Changgui atlas cells have uneven opaque bounds. Normalize
	# their idle/run silhouettes and keep the visible body centred on the feet.
	# Vector3: opaque centre X, opaque bottom Y, scale correction.
	if role=="mongdal":
		var heights:=[216.0,174.0,187.0,173.0,185.0,184.0,224.0,198.0,173.0,160.0,177.0,147.0,140.0,141.0,157.0,165.0]
		var centres:=[94.5,106.0,108.5,109.0,121.5,122.5,95.5,110.0,94.5,105.0,90.0,101.5,96.0,101.5,94.0,108.5]
		var bottoms:=[242.0,243.0,243.0,243.0,243.0,243.0,242.0,242.0,241.0,241.0,241.0,239.0,235.0,235.0,241.0,242.0]
		var target_height:=185.0
		return Vector3(centres[frame],bottoms[frame],target_height/heights[frame])
	if role=="changgui":
		var heights:=[156.0,158.0,161.0,164.0,164.0,158.0,153.0,148.0,145.0,144.0,139.0,146.0,154.0,144.0,139.0,143.0]
		var centres:=[114.0,113.5,114.5,114.0,114.0,114.5,115.5,116.0,114.0,116.0,112.5,112.0,108.0,117.5,121.0,119.0]
		var bottoms:=[242.0,242.0,241.0,242.0,242.0,241.0,242.0,242.0,241.0,241.0,241.0,241.0,241.0,241.0,241.0,241.0]
		var target_height:=158.0
		return Vector3(centres[frame],bottoms[frame],target_height/heights[frame])
	return Vector3(96.0,243.0,1.0)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(actor): return
	if is_instance_valid(combat) and combat.paused:
		paused_last=true
		return
	paused_last=false
	clock+=delta
	action_time=maxf(0,action_time-delta)
	dash_trail_time=maxf(0,dash_trail_time-delta)
	dash_fx_age+=delta
	var dashing: bool=is_player_actor() and actor.dash_time>0
	if dashing and not was_dashing:
		dash_trail_time=.18
		dash_trail_direction=actor.dash_direction.normalized()
		dash_fx_age=.015
	was_dashing=dashing
	var tint:=Color.WHITE
	var flash:=0.0
	if is_player_actor():
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
			# A single tucked-leg silhouette keeps the jump readable and calm.
			animation="jump"
			frame_index=25
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
			var duration:float=actor.windup_duration()
			frame_index=16+clampi(int((1-actor.timer/duration)*4),0,3)
		elif actor.state=="recover":
			animation="recover"
			frame_index=20+clampi(int((1-actor.timer/actor.recovery_duration())*4),0,3)
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
	var scale_factor:=(1.5 if boss and role=="boss" else 1.0)*scale_override
	var direction:float=actor.facing
	var target_size:=draw_size()
	var target_rect:=Rect2(-target_size.x*.5,-target_size.y+2,target_size.x,target_size.y)
	if role=="mihokbul": target_rect.position.y-=28
	# The beast atlas has transparent pixels below its paws; place the visible paws on the floor.
	if role=="jangsanbeom": target_rect.position.y+=15
	var source_size:=Vector2(texture.get_width()/8.0,texture.get_height()/4.0) if atlas else texture.get_size()
	var source_row:=floori(float(frame_index)/8.0)
	var source:=Rect2(Vector2(frame_index%8,source_row)*source_size,source_size) if atlas else Rect2(Vector2.ZERO,source_size)
	var frame_offset:=Vector2.ZERO
	var frame_scale:=1.0
	if atlas and is_player_actor() and role in ["mongdal","changgui"] and frame_index<16:
		var metrics:=new_heart_frame_metrics(frame_index)
		frame_offset=Vector2(direction*(source_size.x*.5-metrics.x)*target_size.x/source_size.x,(243.0-metrics.y)*target_size.y/source_size.y)
		frame_scale=metrics.z
	if is_player_actor() and dash_fx_texture!=null and not dash_fx_info.is_empty():
		var dash_frames:int=int(dash_fx_info["frames"])
		var dash_fps:float=float(dash_fx_info["fps"])
		if dash_fx_age<float(dash_frames)/dash_fps:
			var dash_frame:=clampi(int(dash_fx_age*dash_fps),0,dash_frames-1)
			var dash_size:=Vector2(dash_fx_info["frameSize"][0],dash_fx_info["frameSize"][1])
			var dash_pivot:=Vector2(dash_fx_info["pivot"][0],dash_fx_info["pivot"][1])
			var dash_columns:=int(dash_fx_info["columns"])
			var dash_row:=floori(float(dash_frame)/float(dash_columns))
			var dash_source:=Rect2(Vector2(dash_frame%dash_columns,dash_row)*dash_size,dash_size)
			var dash_angle:=dash_trail_direction.angle()
			var dash_flip:=cos(dash_angle)<0
			var dash_rotation:=dash_angle-PI if dash_flip else dash_angle
			draw_set_transform(Vector2.ZERO,dash_rotation,Vector2(-.7 if dash_flip else .7,.7))
			draw_texture_rect_region(dash_fx_texture,Rect2(-dash_pivot,dash_size),dash_source,Color(0.72,0.84,0.8,.72))
	if is_player_actor() and dash_trail_time>0:
		var life:=dash_trail_time/.18
		var spread:=(1.0-life)*10.0
		for i in range(2,0,-1):
			var offset:=-dash_trail_direction*(float(i)*12.0+spread)
			var alpha:=life*(.07+float(3-i)*.055)
			draw_set_transform(offset.round(),0,Vector2(direction*scale_factor,scale_factor))
			draw_texture_rect_region(texture,target_rect,source,Color(0.18,0.36,0.4,alpha))
	draw_set_transform(frame_offset,0,Vector2(direction*scale_factor*frame_scale,scale_factor*frame_scale))
	draw_texture_rect_region(texture,target_rect,source)
	draw_set_transform(Vector2.ZERO)
