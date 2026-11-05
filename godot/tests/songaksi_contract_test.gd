extends SceneTree
const SummonEffect=preload("res://scripts/summon_effect.gd")
func _initialize() -> void: call_deferred("run_checks")
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool,message: String) -> bool:
	if ok:
		print("PASS: ",message)
		return true
	push_error(message)
	quit(1)
	return false
func finish_summon(world) -> void:
	for child in world.get_children():
		if child is SummonEffect:
			child.finished.emit()
			child.queue_free()
func run_checks() -> void:
	var world=load("res://scenes/village.tscn").instantiate()
	root.add_child(world)
	await frames(5)
	if not check(world.in_village and world.combat.equipment["heart"]=="","Game starts in the village without a heart"): return
	if not check(world.summon_in_progress and not world.player.visual.visible,"Spawn uses the supplied summon sheet before revealing the body"): return
	var summon:Node=world.get_children().filter(func(child): return child is SummonEffect)[0]
	if not check(summon.position.is_equal_approx(world.player.position),"Spawn effect is anchored to the player's floor point"): return
	if not check(summon.self_modulate==SummonEffect.SHADOW_TINT,"Spawn and transformation effect use the black shadow tint"): return
	if not check(SummonEffect.PLAYBACK_SPEED>=3.5,"Spawn and transformation play at the shortened speed"): return
	finish_summon(world)
	await frames(2)
	if not check(not world.summon_in_progress and world.player.visual.visible and world.player.visual.modulate.r<.1,"Spawn ends as the black humanoid form"): return
	if not check(is_instance_valid(world.songaksi_npc),"Songaksi NPC is present in the village"): return
	world.open_songaksi_dialog()
	if not check(world.songaksi_dialog.visible and world.songaksi_dialog.dialog_text=="내 심장을 가져갈래?","Songaksi asks for an explicit yes/no choice"): return
	world.songaksi_dialog.hide()
	world.accept_songaksi_heart()
	await frames(2)
	finish_summon(world)
	await frames(2)
	if not check(world.combat.equipment["heart"]=="songaksi" and world.combat.equipment["main"]=="songaksi_hand","Accepting equips Songaksi heart and grants Songaksi Hand"): return
	if not check(world.player.visual.modulate==Color.WHITE and world.has_heart(),"Contract transforms the black body into Songaksi and permits departure"): return
	world.enter_heartless_form(false)
	if not check(not world.has_heart(),"Death/village reset removes the borrowed heart again"): return
	print("Songaksi contract flow completed.")
	quit(0)
