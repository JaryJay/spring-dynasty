extends Level

enum { START_PHASE, WAIT_PHASE, END_PHASE }

var game_ended: = false
var current_phase: = START_PHASE

func _ready() -> void:
	Server.lobby.player_ids.append(1)
	Server.lobby.player_info_list.append({ "team": 0 })
	Server.lobby.player_names.append("spongebob")
	
	super()
	set_physics_process(true)
	
	rebake_navigation_mesh()
	
	# Focus camera on squad
	camera.position = $Entities/F_0_0.global_position
	
	camera.target_zoom = Vector2(1.1, 1.1)
	
	$DebugLayer.visible = enable_debug_overlay

func _process(delta) -> void:
	super._process(delta)
	$UI/Timer.text = "0:%02d" % %InvadeTimer.time_left

func _physics_process(delta) -> void:
	super._physics_process(delta)
	if current_phase == START_PHASE:
		if $Entities/Camp.team != controlled_team: return
		
		# When player conquers the camp:
		current_phase = WAIT_PHASE
		%InvadeTimer.start()
		$CampaignMap1/Label2.show()
		var tw: = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC)
		tw.tween_property($CampaignMap1/Label, "self_modulate", Color.TRANSPARENT, 0.5)
		tw.tween_property($CampaignMap1/Label2, "self_modulate", Color("31313146"), 0.5)
		tw.tween_property($CampaignMap1/Label3, "self_modulate", Color("31313146"), 0.5)
		tw.tween_property($UI/Timer, "modulate", Color.WHITE, 0.5)
	if current_phase == END_PHASE and not game_ended:
		check_win_loss_condition()
	
	# If any squads are idle, then make them chase the base
	for squad: Squad in get_tree().get_nodes_in_group("squads"):
		if squad.is_friendly() or not squad.is_alive():
			continue
		if squad.state_machine.state is IdleState:
			var chasing_state: ChasingState = squad.state_machine.get_node("AiChasingState")
			chasing_state.target = $Entities/Base
			squad.state_machine.state = chasing_state

func check_win_loss_condition() -> void:
	var has_living_enemy_squads: = false
	for squad: Squad in get_tree().get_nodes_in_group("squads"):
		if not squad.is_alive():
			continue
		elif squad.team != controlled_team:
			has_living_enemy_squads = true
	
	if $Entities/Base.team != 0:
		Global.console.print("Game Over!")
		var tween: = create_tween()
		tween.tween_property(self, "modulate", Color.BLACK, 2.0).set_delay(0.75).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(get_tree().change_scene_to_file.bind("res://levels/campaign/level_2.tscn")).set_delay(1)
		game_ended = true
	elif not has_living_enemy_squads:
		Global.console.print("Victory!")
		var tween: = create_tween()
		tween.tween_property(self, "modulate", Color.BLACK, 2.0).set_delay(0.75).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(get_tree().change_scene_to_file.bind("res://ui/level_selection_menu.tscn")).set_delay(1)
		game_ended = true

func _on_invade_timer_timeout():
	current_phase = END_PHASE
	$Special/Boundary1.queue_free()
	$Special/Boundary2.queue_free()
	spawn_enemies_at(%SpawnPoint1)
	spawn_enemies_at(%SpawnPoint2)
	rebake_navigation_mesh.call_deferred()
	
	var tw: = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property($UI/Timer, "modulate", Color.TRANSPARENT, 0.5)
	tw.tween_property($CampaignMap1/Label2, "self_modulate", Color.TRANSPARENT, 0.5)
	tw.tween_property($CampaignMap1/Label3, "self_modulate", Color.TRANSPARENT, 0.5)

func spawn_enemies_at(marker: Marker2D) -> void:
	var ai_footman_scene: = preload("res://entities/squads/ai/footman_squad.tscn")
	var ai_archer_scene: = preload("res://entities/squads/ai/archer_squad.tscn")
	
	for i in 1:
		var f: Squad = ai_footman_scene.instantiate()
		$Entities.add_child(f)
		f.team = 1
		f.global_position = marker.get_child(i).global_position
	for i in 1:
		var f: Squad = ai_archer_scene.instantiate()
		$Entities.add_child(f)
		f.team = 1
		f.global_position = marker.get_child(2).global_position
