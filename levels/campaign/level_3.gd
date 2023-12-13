extends Level

var game_ended: = false

func _ready() -> void:
	Server.lobby.player_ids.append(1)
	Server.lobby.player_info_list.append({ "team": 0 })
	Server.lobby.player_names.append("spongebob")
	
	super()
	set_physics_process(true)
	
	rebake_navigation_mesh()
	
	# Focus camera on squad
	camera.position = $Entities/F_0_2.global_position
	camera.target_zoom = Vector2(1.1, 1.1)
	
	$DebugLayer.visible = enable_debug_overlay

func _physics_process(delta) -> void:
	super._physics_process(delta)
	if not game_ended:
		check_win_loss_condition()
	#for squad: Squad in get_tree().get_nodes_in_group("squads"):
		#if squad.is_friendly() or not squad.is_alive(): continue
		#
		#var state: = squad.state_machine.state
		#if not state is IdleState or squad.get_closest_enemy_squad(): continue
		#state.state_machine.state = squad.state_machine.get_node("AiNavigatingState")
		#squad.set_target_position($Entities/Base.global_position)

func check_win_loss_condition() -> void:
	var has_living_friendly_squads: = false
	for squad: Squad in get_tree().get_nodes_in_group("squads"):
		if not squad.is_alive():
			continue
		elif squad.team == controlled_team:
			has_living_friendly_squads = true
	
	if $Entities/Base.team == 0:
		Global.console.print("Victory!")
		var tween: = create_tween()
		tween.tween_property(self, "modulate", Color.BLACK, 2.0).set_delay(0.75).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(get_tree().change_scene_to_file.bind("res://ui/level_selection_menu.tscn")).set_delay(1)
		game_ended = true
	elif not has_living_friendly_squads:
		Global.console.print("Game Over!")
		var tween: = create_tween()
		tween.tween_property(self, "modulate", Color.BLACK, 2.0).set_delay(0.75).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(get_tree().change_scene_to_file.bind("res://levels/campaign/level_3.tscn")).set_delay(1)
		game_ended = true

func _on_trigger_area_body_entered(body):
	if body is Squad:
		if not body.is_friendly(): return
		$Special/TriggerArea.queue_free()
		$Entities/Camp.team = 1
