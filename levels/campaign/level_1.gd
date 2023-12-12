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
	camera.position = $Entities/F_0_0.position
	
	# Select squad
	selected_squads = [$Entities/F_0_0]
	camera.target_zoom = Vector2(1.4, 1.4)
	$Entities/F_0_0.selected = true
	
	$DebugLayer.visible = enable_debug_overlay

func _physics_process(delta) -> void:
	super._physics_process(delta)
	if not game_ended:
		check_win_loss_condition()

func check_win_loss_condition() -> void:
	var has_living_friendly_squads: = false
	var has_living_enemy_squads: = false
	for squad: Squad in get_tree().get_nodes_in_group("squads"):
		if not squad.is_alive():
			continue
		if squad.team == controlled_team:
			has_living_friendly_squads = true
		else:
			has_living_enemy_squads = true
	
	# If all friendly squads are dead or the farm was destroyed
	if not has_living_friendly_squads or $Entities/B_0.team != controlled_team:
		Global.console.print("Game Over!")
		var tween: = create_tween()
		tween.tween_property(self, "modulate", Color.BLACK, 2.0).set_delay(0.75).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(get_tree().change_scene_to_file.bind("res://levels/campaign/level_1.tscn")).set_delay(1)
		game_ended = true
	elif not has_living_enemy_squads:
		Global.console.print("Victory!")
		var tween: = create_tween()
		tween.tween_property(self, "modulate", Color.BLACK, 2.0).set_delay(0.75).set_trans(Tween.TRANS_CUBIC)
		tween.tween_callback(get_tree().change_scene_to_file.bind("res://ui/level_selection_menu.tscn")).set_delay(1)
		game_ended = true

func _on_trigger_area_2_body_entered(_body) -> void:
	$Special/TriggerArea2.queue_free()
	$Entities/B_0.sight_range = 180
	$Entities/B_0/PointLight2D.texture_scale = 1.0 * 180 / 32
	$CampaignMap1/Label3.show()
	$CampaignMap1/Label4.show()
	
	# Focus camera on farm
	camera.follow_mode_enabled = false
	var tw: = create_tween()
	tw.tween_property(camera, "position", $Entities/B_0.position, 0.4).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(1.6)
	tw.tween_property(camera, "follow_mode_enabled", true, 0)
	
	var enemies: = [$Entities/F_1_0, $Entities/F_1_1]
	for enemy: Squad in enemies:
		var chasing_state: ChasingState = enemy.state_machine.get_node("AiChasingState")
		chasing_state.target = $Entities/B_0
		enemy.state_machine.state = chasing_state
