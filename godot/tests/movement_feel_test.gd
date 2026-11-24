extends SceneTree

const Player = preload("res://scripts/player.gd")

func check(condition: bool, message: String) -> bool:
	if condition:
		print("PASS: ",message)
		return true
	push_error(message)
	quit(1)
	return false

func _initialize() -> void:
	var player:=Player.new()
	if not check(Player.SPEED==168.0 and Player.AIR_SPEED==210.0,"Air steering stays responsive without the former 280-speed jump snap"): return
	if not check(player.movement_acceleration(1.0,false)==Player.GROUND_ACCEL and player.movement_acceleration(0.0,false)==Player.GROUND_DECEL,"Ground acceleration and braking are tuned separately"): return
	if not check(player.movement_acceleration(1.0,true)==Player.AIR_ACCEL and player.movement_acceleration(0.0,true)==Player.AIR_DECEL,"Air steering and air braking are tuned separately"): return
	player.velocity.y=-450.0
	player.jump_hold_timer=Player.JUMP_HOLD_TIME
	if not check(player.jump_gravity(true)==Player.JUMP_HOLD_GRAVITY and player.jump_gravity(false)==Player.JUMP_RELEASE_GRAVITY,"Holding jump sustains height while release produces a short jump"): return
	player.velocity.y=1.0
	if not check(player.jump_gravity(true)==Player.FALL_GRAVITY,"Falling uses a firmer gravity than the held ascent"): return
	player.jump_hold_timer=.1
	player.start_dash(Vector2.RIGHT)
	if not check(player.jump_hold_timer==0.0,"Dash cleanly ends jump sustain"): return
	player.free()
	quit(0)
