extends Node2D
class_name Game

const NUM_SAVED_INPUTS: = 30
const footman_squad_scene: = preload("res://entities/footman_squad.tscn")
const archer_squad_scene: = preload("res://entities/archer_squad.tscn")
const base_scene: = preload("res://entities/buildings/base.tscn")
const farm_scene: = preload("res://entities/buildings/farm.tscn")

@export var enable_debug_overlay: bool

@onready var debug_overlay: = $DebugLayer/DebugOverlay
@onready var selection_rect: SelectionRect = $SelectionRect
@onready var pause_menu: Control = $PauseMenuLayer/PauseMenu
@onready var camera: Camera2D = $Camera
@onready var map: NavigationRegion2D = $Map1

## The current frame number in the game
var frame: int = 0

## The list of squads that are within the blue selection_rect. Updated every
## frame in _physics_process()
var selected_squads: Array[Squad] = []
## Integer between 0 and 5, inclusive, representing the team that the local
## player controls. This value is set once in _ready(), and doesn't change
var controlled_team: int = 0

## Maps from player_id (int) to list of last 30 inputs (Array[ClientInput])
var player_inputs: Dictionary = {}
## Equal to frame + 1 if no frames are desynced
var earliest_desynced_frame: int = 1

func _ready():
	Client.game = self
	set_physics_process(false)
	
	
	if multiplayer.is_server():
		for player_id in Server.lobby.player_ids:
			player_inputs[player_id] = []
		return
	
	for player_id in Server.lobby.player_ids:
		player_inputs[player_id] = []
	
	controlled_team = Client.team_number
	
	var pause_menu_resume_button: Button = $PauseMenuLayer/PauseMenu/Panel/VBoxContainer/Resume
	pause_menu_resume_button.pressed.connect(pause_menu.hide)

## Spawns a few squads for each player
func _on_start_timer_timeout():
	var lobby: Lobby = Server.lobby
	
	var buildings: Array[StaticBody2D] = []
	
	# Spawn bases and squads
	for player_info in lobby.player_info_list:
		var team: int = player_info.team
		var spawn_location: Marker2D = $Map1.spawn_locations[team]
		
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
	for building in buildings:
		var obstacle: NavigationObstacle2D = building.get_node("NavigationObstacle2D")
		var polygon_transform: Transform2D = obstacle.get_global_transform()
		var polygon: PackedVector2Array = obstacle.vertices

		var new_collision_outline: PackedVector2Array = polygon_transform * polygon

		nav_polygon.add_outline(new_collision_outline)
	nav_polygon.make_polygons_from_outlines()
	map.navigation_polygon = nav_polygon
	
	debug_overlay.initialize(self)
	$DebugLayer.visible = enable_debug_overlay
	
	if not multiplayer.is_server():
		set_physics_process(true)

## Processes non-gameplay-related things, such as toggling the pause menu
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		pause_menu.visible = !pause_menu.visible
	camera.disable_pan = pause_menu.visible

## Updates the game state
func _physics_process(_delta):
	frame += 1
	
	# Update selected_squads to be the squads overlapped by selection_rect
	_update_squads_selection()
	
	# Note that detecting inputs is not the same as handling them
	var input: ClientInput = _detect_input()
	_add_input(input)
	
	# Handles inputs from all players, including the local player
	_rollback_and_resimulate()
	
	# Send last 30 inputs to the server
	var inputs: Array = player_inputs[multiplayer.get_unique_id()]
	var serialized_inputs: = inputs.map(ClientInput.to_bytes)
	GameServer.receive_inputs.rpc_id(1, serialized_inputs)

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
				if input.state_index >= 0:
					earliest_desynced_frame = mini(earliest_desynced_frame, input.frame)
					break
		else:
			var latest_previous_input: ClientInput = previous_inputs[-1]
			if latest_new_input.frame > latest_previous_input.frame:
				player_inputs[player_id] = inputs[player_id]
				for input in inputs[player_id]:
					if input.frame > latest_previous_input.frame and input.state_index >= 0:
						earliest_desynced_frame = mini(earliest_desynced_frame, input.frame)
						break

## Receive game frame state from the server for a given frame
@rpc("authority", "unreliable")
func receive_game_frame_state(game_frame_state_bytes: PackedByteArray) -> void:
	var game_frame_state = GameFrameState.create_from(game_frame_state_bytes)
	var state_frame: int = game_frame_state.frame
	
	#print("%d: Received game frame state. frame=%d, state_frame=%d" % [multiplayer.get_unique_id(), frame, state_frame])
	#print(str(game_frame_state))
	
	if frame < state_frame or frame > state_frame + 5:
		# We are too far behind or ahead of the server
		frame = state_frame + 1
	
	for i in game_frame_state.squad_names.size():
		var squad_name: String = game_frame_state.squad_names[i]
		var squad_frame_state: SquadFrameState = game_frame_state.squad_frame_states[i]
		var squad: Squad = $Entities.get_node_or_null(squad_name)
		if not squad:
			printerr("Could not find squad %s" % squad_name)
			continue
		
		for j in range(squad.frame_states.size() - 1, -1, -1):
			if squad.frame_states[j].frame == state_frame:
				squad.frame_states[j] = squad_frame_state
				earliest_desynced_frame = mini(earliest_desynced_frame, state_frame + 1)
				break

func _update_squads_selection() -> void:
	if selection_rect.is_selecting:
		for selected_squad in selected_squads:
			if is_instance_valid(selected_squad):
				selected_squad.selected = false
		selected_squads.clear()
		for body in selection_rect.get_overlapping_bodies():
			if body is Squad:
				if body.team == controlled_team and \
				not body.state_machine.state is DyingState:
					selected_squads.append(body)
					body.selected = true
			else:
				printerr("Selected body is not a squad: %s" % body)

func _detect_input() -> ClientInput:
	var selecting: = Input.is_action_pressed("select")
	if Input.is_action_pressed("primary") and not selecting:
		if selected_squads.size() == 0:
			# Do nothing
			return ClientInput.new(frame, -1, [], Vector2.ZERO)
		
		var squad_names: Array[StringName] = []
		for squad in selected_squads:
			if is_instance_valid(squad) and not squad.state_machine.state is DyingState:
				squad_names.append(squad.name)
		
		var mouse_pos: = get_global_mouse_position().round()
		var space_state = get_world_2d().direct_space_state
		var query: = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		query.collision_mask = 0b11 # Collide with squads and buildings
		
		var collisions: = space_state.intersect_point(query)
		
		if collisions.size() == 0:
			# Navigate to point (state_index of 1 refers to NavigatingState)
			return ClientInput.new(frame, 1, squad_names, mouse_pos)
		
		# The target closest to the cursor
		var closest_target: Node2D
		var closest_dist_squared: = INF
		for collision in collisions:
			var collider: CollisionObject2D = collision.collider
			if not (collider is Squad or collider is Building):
				continue
			if not collider.team == controlled_team:
				var target: Node2D = collider
				var dist_squared: = mouse_pos.distance_squared_to(target.position)
				if dist_squared < closest_dist_squared:
					closest_target = target
					closest_dist_squared = dist_squared
		
		if closest_target:
			# Chase target (state_index of 2 refers to ChasingState)
			var closest_target_name: = closest_target.name
			return ClientInput.new(frame, 2, squad_names, Vector2.ZERO, closest_target_name)
		else:
			# This will happen if all clicked targets are friendly
			# Navigate to point
			return ClientInput.new(frame, 1, squad_names, mouse_pos)
	
	# State index of -1 means that the input does nothing
	return ClientInput.new(frame, -1, [], Vector2.ZERO)

## Resets the game state back to the earliest desynced frame, then resimulates
## those desynced frames.
## Sets the earliest desynced frame to frame + 1.
func _rollback_and_resimulate(_as_server: bool = false) -> void:
	# Rollback
	if earliest_desynced_frame < frame:
		for squad in get_tree().get_nodes_in_group("squads"):
			squad.return_to_frame_state(earliest_desynced_frame - 1)
	
	# Handle inputs
	for f in range(earliest_desynced_frame, frame + 1):
		# Handle inputs from all players
		for player_id in Server.lobby.player_ids:
			var inputs: Array = player_inputs[player_id]
			for input in inputs:
				if input.frame == f:
					_handle_input(input)
					break
		# Update squads.
		for squad in get_tree().get_nodes_in_group("squads"):
			squad.update(f, true)
		for squad in get_tree().get_nodes_in_group("squads"):
			# Post update checks if the squad is dead, and it also creates
			# a frame_state for the squad at that frame
			squad.post_update(f)
	
	earliest_desynced_frame = frame + 1

func _add_input(input: ClientInput) -> void:
	var player_input_list: Array = player_inputs[multiplayer.get_unique_id()]
	player_input_list.append(input)
	if player_input_list.size() > NUM_SAVED_INPUTS:
		player_input_list[0] = null
		player_input_list.remove_at(0)

func _handle_input(input: ClientInput) -> void:
	var squads: Array[Squad] = []
	for squad_name in input.squads:
		var squad: Squad = $Entities.get_node_or_null(squad_name)
		if squad == null:
			print("Squad not found: %s" % squad_name)
			continue
		squads.append(squad)
	if input.state_index == 1:
		var avg_squad_pos: = Vector2.ZERO
		for squad in squads:
			avg_squad_pos += squad.position
		avg_squad_pos /= squads.size()
		
		for squad in squads:
			if squads.size() == 1:
				squad.set_target_position(input.target_position)
			else:
				var adjusted_target: = input.target_position + avg_squad_pos.direction_to(squad.position) * 28
				squad.set_target_position(adjusted_target)
			squad.state_machine.state = squad.state_machine.get_node("NavigatingState")
	elif input.state_index == 2:
		var target: Node2D = $Entities.get_node_or_null(input.target_name)
		for squad in squads:
			var current_state: = squad.state_machine.state
			if current_state is AttackingState and current_state.target == target:
				continue
			var chasing_state: = squad.state_machine.get_node("ChasingState")
			chasing_state.target = target
			squad.state_machine.state = chasing_state
