extends Level

func _ready() -> void:
	Server.lobby.player_ids.append(1)
	Server.lobby.player_info_list.append({ "team": 0 })
	Server.lobby.player_names.append("spongebob")
	
	super()
	set_physics_process(true)
	
	# Remake navigation region
	var nav_polygon: = map.navigation_polygon
	var source_geometry_data: = NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(nav_polygon, source_geometry_data, self)
	NavigationServer2D.bake_from_source_geometry_data(nav_polygon, source_geometry_data)
	map.navigation_polygon = nav_polygon
	
	# Focus camera on squad
	camera.position = $Entities/F_0_0.position
	
	# Select squad
	selected_squads = [$Entities/F_0_0]
	camera.target_zoom = Vector2(1.4, 1.4)
	$Entities/F_0_0.selected = true

func _physics_process(_delta) -> void:
	frame += 1
	
	# Update selected_squads to be the squads overlapped by selection_rect
	_update_squads_selection()
	
	# Note that detecting inputs is not the same as handling them
	var input: ClientInput = _detect_input()
	_add_input(input)
	
	# Handle inputs from all players, including the local player
	rollback_and_resimulate()
	
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
		Global.console.print("You lose!")
		set_physics_process(false)
	elif not has_living_enemy_squads:
		Global.console.print("You win!")
		set_physics_process(false)

func _on_trigger_area_2_body_entered(_body) -> void:
	Global.console.print("Entered Triggered area!")
	$Special/TriggerArea2.queue_free()
	
	# Focus camera on farm
	camera.follow_mode_enabled = false
	var tw: = create_tween()
	tw.tween_property(camera, "position", $Entities/B_0.position, 0.5).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(1.6)
	tw.tween_property(camera, "follow_mode_enabled", true, 0)
	
	var enemies: = [$Entities/F_1_0, $Entities/F_1_1]
	for enemy: Squad in enemies:
		var chasing_state: ChasingState = enemy.state_machine.get_node("AiChasingState")
		chasing_state.target = $Entities/B_0
		enemy.state_machine.state = chasing_state
