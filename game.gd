extends Node2D
class_name Game

const NUM_SAVED_INPUTS: = 30
const squad_scene: = preload("res://entities/footman_squad.tscn")

@onready var selection_rect: SelectionRect = $SelectionRect
@onready var pause_menu: Control = $PauseMenuLayer/PauseMenu
@onready var camera: Camera2D = $Camera

## The list of squads that are within the blue selection_rect. Updated every
## frame in _physics_process()
var selected_squads: Array[Squad] = []
## Integer between 0 and 5, inclusive, representing the team that the local
## player controls. This value is set once in _ready(), and doesn't change
var controlled_team: int = 0

## Maps from player_id (int) to list of last 30 inputs (Array[ClientInput])
var player_inputs: Dictionary = {}
## Maps from player_id (int) to the frame to rollback to (int),
## -1 if no rollback needed
var needs_rollback: Dictionary = {}

func _ready():
	if multiplayer.is_server():
		set_physics_process(false)
		return
	
	controlled_team = Client.team_number
	
	var pause_menu_resume_button: Button = $PauseMenuLayer/PauseMenu/Panel/VBoxContainer/Resume
	pause_menu_resume_button.pressed.connect(pause_menu.hide)
	
	for player_id in Client.lobby.player_ids:
		player_inputs[player_id] = []

## Spawns a few squads for each player
func _on_spawn_timer_timeout():
	var lobby: Lobby = Server.lobby if multiplayer.is_server() else Client.lobby
	for player_info in lobby.player_info_list:
		var team: int = player_info.team
		var spawn_location: Marker2D = $Map1.spawn_locations[team]
		
		var offsets: Array[Vector2] = [Vector2.ZERO, Vector2(40, 50), Vector2(-50, 40)]
		for i in offsets.size():
			var offset: = offsets[i]
			var squad: Squad = squad_scene.instantiate()
			squad.position = spawn_location.position + offset
			squad.team = team
			squad.name = "FS_%d_%d" % [team, i]
			$Squads.add_child(squad)

## Processes non-gameplay-related things, such as toggling the pause menu
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		pause_menu.visible = !pause_menu.visible
	camera.disable_pan = pause_menu.visible

## Updates the game state
func _physics_process(_delta):
	# Update selected_squads to be the squads overlapped by selection_rect
	_update_squads_selection()
	
	# Note that detecting inputs is not the same as handling them
	var input: ClientInput = _detect_input()
	if input:
		_add_input(input)
	else:
		# State index of -1 means that the input does nothing
		_add_input(ClientInput.new(Client.frame, -1, [], Vector2.ZERO))
	
	# Handles inputs from all players, including the local player
	_rollback_and_resimulate()
	
	# Send last 30 inputs to the server
	var inputs: Array = player_inputs[multiplayer.get_unique_id()]
	var serialized_inputs: = inputs.map(ClientInput.to_bytes)
	GameServer.receive_inputs.rpc_id(1, serialized_inputs)
	
	Client.frame += 1

@rpc("authority", "unreliable")
func receive_other_player_inputs(serialized_inputs: Dictionary) -> void:
	# Deserialize inputs
	var inputs: Dictionary = {}
	for player_id in Client.lobby.player_ids:
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
					needs_rollback[player_id] = input.frame
					break
		else:
			var latest_previous_input: ClientInput = previous_inputs[-1]
			if latest_new_input.frame > latest_previous_input.frame:
				player_inputs[player_id] = inputs[player_id]
				for input in inputs[player_id]:
					if input.frame > latest_previous_input.frame and input.state_index >= 0:
						needs_rollback[player_id] = input.frame
						break

func _update_squads_selection() -> void:
	if selection_rect.is_selecting:
		for selected_squad in selected_squads:
			selected_squad.selected = false
		selected_squads.clear()
		for body in selection_rect.get_overlapping_bodies():
			if body is Squad:
				if body.team == controlled_team:
					selected_squads.append(body)
					body.selected = true
			else:
				print("Selected body is not a squad: %s" % body)

func _detect_input() -> ClientInput:
	var selecting: = Input.is_action_pressed("select")
	if Input.is_action_pressed("primary") and not selecting:
		if selected_squads.size() == 0:
			return null
		
		var squad_names: Array[StringName] = []
		for squad in selected_squads:
			squad_names.append(squad.name)
		
		var mouse_pos: = get_global_mouse_position()
		var space_state = get_world_2d().direct_space_state
		var query: = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		query.collision_mask = 1 # Collide with squads
		
		var collisions: = space_state.intersect_point(query)
		
		if collisions.size() == 0:
			# Navigate to point (state_index of 1 refers to NavigatingState)
			return ClientInput.new(Client.frame, 1, squad_names, mouse_pos)
		
		# The enemy squad closest to the cursor
		var closest_enemy_squad: Squad
		var closest_dist_squared: = INF
		for collision in collisions:
			var collider: CollisionObject2D = collision.collider
			if collider is Squad and not collider.team == controlled_team:
				var enemy_squad: Squad = collider
				var dist_squared: = mouse_pos.distance_squared_to(enemy_squad.position)
				if dist_squared < closest_dist_squared:
					closest_enemy_squad = enemy_squad
					closest_dist_squared = dist_squared
		
		if closest_enemy_squad:
			# Chase enemy squad (state_index of 3 refers to ChasingState)
			var enemy_name: = closest_enemy_squad.name
			return ClientInput.new(Client.frame, 3, squad_names, Vector2.ZERO, enemy_name)
		else:
			# This will happen if all clicked squads are friendly
			# Navigate to point
			return ClientInput.new(Client.frame, 1, squad_names, mouse_pos)
	return null

## Loops through the needs_rollback dictionary, checking if any players need
## to rollback (i.e. they sent a new input that we need to simulate). If any
## players do, then we reset all squads back to the earliest rollback frame;
## otherwise, 
func _rollback_and_resimulate() -> void:
	var min_rollback_frame: int = Client.frame
	for player_id in needs_rollback.keys():
		if needs_rollback[player_id] >= 0:
			var rollback_frame: int = needs_rollback[player_id]
			min_rollback_frame = mini(min_rollback_frame, rollback_frame)
			needs_rollback[player_id] = -1
	
	# Rollback
	if min_rollback_frame < Client.frame:
		for squad in get_tree().get_nodes_in_group("squads"):
			squad.return_to_frame_state(min_rollback_frame)
	
	# Resimulate frames
	for frame in range(min_rollback_frame, Client.frame + 1):
		# Handle inputs from all players
		for player_id in Client.lobby.player_ids:
			var inputs: Array = player_inputs[player_id]
			for input in inputs:
				if input.frame == frame:
					_handle_input(input)
					break
		# Process squads. Note that for frame == Client.frame, the function
		# squad.update() will automatically be called during _physics_process
		if frame < Client.frame:
			for squad in get_tree().get_nodes_in_group("squads"):
				squad.update(frame, true)
	pass

func _add_input(input: ClientInput) -> void:
	var player_input_list: Array = player_inputs[multiplayer.get_unique_id()]
	player_input_list.append(input)
	if player_input_list.size() > NUM_SAVED_INPUTS:
		player_input_list[0] = null
		player_input_list.remove_at(0)

func _handle_input(input: ClientInput) -> void:
	var squads: Array[Squad] = []
	for squad_name in input.squads:
		var squad: Squad = $Squads.get_node_or_null(squad_name)
		if squad == null:
			print("Squad not found: %s" % squad_name)
			continue
		squads.append(squad)
	if input.state_index == 1:
		for squad in squads:
			squad.set_target_position(input.target)
			squad.state_machine.state = squad.state_machine.get_node("NavigatingState")
	elif input.state_index == 3:
		var target_squad: = $Squads.get_node_or_null(input.enemy_squad)
		for squad in squads:
			var current_state: = squad.state_machine.state
			if current_state is AttackingState and current_state.target_squad == target_squad:
				continue
			var chasing_state: = squad.state_machine.get_node("ChasingState")
			chasing_state.target_squad = target_squad
			squad.state_machine.state = chasing_state
