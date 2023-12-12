extends Level
class_name MultiplayerLevel

func _ready():
	Client.level = self
	set_physics_process(false)
	
	var lobby: = Server.lobby
	for i in lobby.player_ids.size():
		var player_id: = lobby.player_ids[i]
		var team: int = lobby.player_info_list[i].team
		player_inputs[player_id] = []
		var player_node: = Player.new()
		player_node.id = player_id
		player_node.team = team
		player_node.gold = 100
		player_node.name = str(player_id)
		$Players.add_child(player_node)
	
	if multiplayer.is_server():
		return
	
	controlled_team = Client.team_number

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if is_spectator:
		return
	
	# Send last 30 inputs to the server
	var inputs: Array = player_inputs[multiplayer.get_unique_id()]
	var serialized_inputs: = inputs.map(ClientInput.to_bytes)
	GameServer.receive_inputs.rpc_id(1, serialized_inputs)

## Spawns a few squads and buildings for each player, then starts
## physics processing.
func _on_start_timer_timeout():
	var lobby: Lobby = Server.lobby
	
	var buildings: Array[StaticBody2D] = []
	
	# Spawn bases and squads
	for player_info in lobby.player_info_list:
		var team: int = player_info.team
		var spawn_location: Marker2D = map.spawn_locations[team]
		
		var base: = base_scene.instantiate()
		base.position = spawn_location.global_position
		base.team = team
		base.name = "B_%d" % team
		buildings.append(base)
		$Entities.add_child(base)
		
		var farm_spawn: Marker2D = spawn_location.get_node("Farm")
		var farm: = farm_scene.instantiate()
		farm.position = farm_spawn.global_position
		farm.team = team
		farm.name = "F_%d_0" % team
		buildings.append(farm)
		$Entities.add_child(farm)
		
		var squad_types: Array[PackedScene] = [footman_squad_scene, footman_squad_scene, archer_squad_scene]
		var offsets: Array[Vector2] = [Vector2(60, -45), Vector2(40, 50), Vector2(-50, 40)]
		for i in squad_types.size():
		#for i in 1: # Uncomment this to only spawn 1 squad per player
			var offset: = offsets[i]
			var squad: Squad = squad_types[i].instantiate()
			squad.position = spawn_location.position + offset
			squad.team = team
			squad.name = "S_%d_%d" % [team, i]
			$Entities.add_child(squad)
	# Remake navigation region
	var nav_polygon: = map.navigation_polygon
	var source_geometry_data: = NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(nav_polygon, source_geometry_data, self)
	NavigationServer2D.bake_from_source_geometry_data(nav_polygon, source_geometry_data)
	map.navigation_polygon = nav_polygon
	
	debug_overlay.initialize(self)
	$DebugLayer.visible = enable_debug_overlay
	
	if not multiplayer.is_server():
		set_physics_process(true)
		
		var base: Node2D = $Entities.get_node("B_%d" % controlled_team)
		camera.position = base.position

@rpc("authority", "unreliable")
func receive_other_player_inputs(serialized_inputs: Dictionary) -> void:
	# Deserialize inputs
	var inputs: Dictionary = {}
	for player_id in Server.lobby.player_ids:
		var serialized_input_list: Array = serialized_inputs[player_id]
		inputs[player_id] = serialized_input_list.map(ClientInput.create_from)

	for player_id in inputs.keys():
		if inputs[player_id].is_empty():
			continue
		elif player_id == multiplayer.get_unique_id():
			continue
		
		var previous_inputs: Array = player_inputs[player_id]
		var latest_new_input: ClientInput = inputs[player_id][-1]
		if previous_inputs.size() == 0:
			player_inputs[player_id] = inputs[player_id]
			for input in inputs[player_id]:
				if input.input_type == 0:
					continue
				earliest_desynced_frame = mini(earliest_desynced_frame, input.frame)
				break
		else:
			var latest_previous_input: ClientInput = previous_inputs[-1]
			if latest_new_input.frame > latest_previous_input.frame:
				player_inputs[player_id] = inputs[player_id]
				for input in inputs[player_id]:
					if input.frame > latest_previous_input.frame and input.input_type != 0:
						earliest_desynced_frame = mini(earliest_desynced_frame, input.frame)
						break

## Receive game frame state from the server for a given frame.
@rpc("authority", "unreliable")
func receive_game_frame_state(game_frame_state_bytes: PackedByteArray) -> void:
	var game_frame_state = GameFrameState.create_from(game_frame_state_bytes)
	var state_frame: int = game_frame_state.frame
	
	#print("%d: Received game frame state. frame=%d, state_frame=%d" % [multiplayer.get_unique_id(), frame, state_frame])
	#print(str(game_frame_state))
	
	if frame < state_frame:
		# We are too far behind the server
		earliest_desynced_frame = frame + 1
		frame = state_frame
		rollback_and_resimulate()
	elif frame > state_frame + 3:
		# We are too far ahead of the server
		earliest_desynced_frame = state_frame + 1
		frame = state_frame
		rollback_and_resimulate()
	
	earliest_desynced_frame = mini(earliest_desynced_frame, state_frame + 1)
	
	for i in game_frame_state.squad_names.size():
		var squad_name: String = game_frame_state.squad_names[i]
		var squad_frame_state: SquadFrameState = game_frame_state.squad_frame_states[i]
		var squad: Squad = $Entities.get_node_or_null(squad_name)
		if not squad:
			# TODO: Instantiate new squad based on squad type
			printerr("Could not find squad %s" % squad_name)
			continue
		
		if squad.frame_states[-1].frame < state_frame:
			printerr("Oh no. %d, %d" % [squad.frame_states[-1].frame, state_frame])
			continue
		
		for j in range(squad.frame_states.size() - 1, -1, -1):
			if squad.frame_states[j].frame == state_frame:
				squad.frame_states[j] = squad_frame_state
				squad.return_to_frame_state(state_frame)
				break
	
	for i in game_frame_state.building_names.size():
		var building_name: String = game_frame_state.building_names[i]
		var building_frame_state: BuildingFrameState = game_frame_state.building_frame_states[i]
		var building: Building = $Entities.get_node_or_null(building_name)
		if not building:
			printerr("Could not find building %s" % building_name)
			continue
		
		for j in range(building.frame_states.size() - 1, -1, -1):
			if building.frame_states[j].frame == state_frame:
				if building.frame_states[j].ability_cooldown != building_frame_state.ability_cooldown:
					Global.console.print("Ability cooldown desynced for %s" % building.name)
					Global.console.print("Frame = %d" % state_frame)
					Global.console.print("Local = %d, auth = %d" % [building.frame_states[j].ability_cooldown, building_frame_state.ability_cooldown])
				building.frame_states[j] = building_frame_state
				building.return_to_frame_state(state_frame)
				break

## Lose the game, and enables spectator mode.
## Called by the server when the player controls 0 bases, or when another
## loss condition is satisfied
@rpc("authority", "reliable")
func lose_game(stats_bytes: PackedByteArray, killer_bytes: PackedByteArray) -> void:
	$Players.get_node(str(multiplayer.get_unique_id())).queue_free()
	Global.console.print("You lost the game!")
	is_spectator = true
	
	var game_over_scene: PackedScene = load("res://ui/game_over_overlay.tscn")
	var canvas_layer: = CanvasLayer.new()
	var game_over_overlay: GameOverOverlay = game_over_scene.instantiate()
	# TODO: set game over overlay stats
	game_over_overlay.time_survived = frame
	game_over_overlay.total_score = frame / Engine.physics_ticks_per_second
	
	canvas_layer.add_child(game_over_overlay)
	add_child(canvas_layer)

@rpc("authority", "reliable")
func end_game(winning_player_id: int, team: int) -> void:
	# TODO make this more fancy
	var n: = Server.lobby.get_player_name(winning_player_id)
	Global.console.print("%s has won." % winning_player_id)
	is_spectator = true
	#set_physics_process(false)
	
	if winning_player_id == multiplayer.get_unique_id():
		Global.console.print("You won!")
		var game_over_scene: PackedScene = load("res://ui/game_over_overlay.tscn")
		var canvas_layer: = CanvasLayer.new()
		var game_over_overlay: GameOverOverlay = game_over_scene.instantiate()
		# TODO: set game over overlay stats
		game_over_overlay.victory = true
		game_over_overlay.time_survived = frame
		game_over_overlay.total_score = frame / Engine.physics_ticks_per_second
		
		canvas_layer.add_child(game_over_overlay)
		add_child(canvas_layer)
