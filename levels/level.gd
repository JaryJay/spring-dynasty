extends Node2D
class_name Level

const NUM_SAVED_INPUTS: = 30
const footman_squad_scene: = preload("res://entities/squads/controllable/footman_squad.tscn")
const archer_squad_scene: = preload("res://entities/squads/controllable/archer_squad.tscn")
const base_scene: = preload("res://entities/buildings/base.tscn")
const farm_scene: = preload("res://entities/buildings/farm.tscn")
var navigate_command_vfx_scene: = load("res://vfx/navigate_command_vfx.tscn")

@export var enable_debug_overlay: bool

@onready var debug_overlay: = $DebugLayer/DebugOverlay
@onready var selection_rect: SelectionRect = $SelectionRect
@onready var pause_menu: Control = $PauseMenuLayer/PauseMenu
@onready var camera: Camera2D = $Camera

@export var map: NavigationRegion2D

## The current frame number in the game.
var frame: int = 0
## Equal to frame + 1 if no frames are desynced.
var earliest_desynced_frame: int = 1

#region Player-only variables

## Integer between 0 and 5, inclusive, representing the team that the local
## player controls. This value is set once in _ready(), and doesn't change.
var controlled_team: int = 0
## The list of squads that are within the blue selection_rect. Updated every
## frame in [method _physics_process].
var selected_squads: Array[Squad] = []

var current_ui_wheel: UIWheel
## Maps from player_id (int) to list of last 30 inputs (Array[ClientInput]).
var player_inputs: Dictionary = {}

var is_spectator: = false
#endregion

func _ready():
	Client.level = self
	
	player_inputs[1] = []
	
	var player_node: = Player.new()
	# Starting gold
	player_node.gold = 100
	player_node.team = controlled_team
	player_node.name = "P_%d" % controlled_team
	$Players.add_child(player_node)

## Processes non-gameplay-related things, such as toggling the pause menu.
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		pause_menu.visible = !pause_menu.visible
	camera.disable_pan = pause_menu.visible
	camera.follow_targets = selected_squads

## Updates the frame count, handles client input, and calls
## [method rollback_and_resimulate].
func _physics_process(_delta):
	frame += 1
	
	if not is_spectator:
		# Update selected_squads to be the squads overlapped by selection_rect
		_update_squads_selection()
		
		#_handle_impactless_inputs()
		# Note that detecting inputs is not the same as handling them
		var input: ClientInput = _detect_input()
		_create_input_vfx(input)
		_add_input(input)
	
	# Handle inputs from all players, including the local player
	rollback_and_resimulate()

func _update_squads_selection() -> void:
	if selection_rect.is_selecting:
		for selected_squad in selected_squads:
			if is_instance_valid(selected_squad):
				selected_squad.selected = false
		selected_squads.clear()
		for body in selection_rect.get_overlapping_bodies():
			if body is Squad:
				if body.team == controlled_team and body.is_alive():
					selected_squads.append(body)
					body.selected = true
			else:
				printerr("Selected body is not a squad: %s" % body)

func _handle_impactless_inputs() -> void:
	var mouse_pos: = get_global_mouse_position()
	var params: = PhysicsPointQueryParameters2D.new()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.position = mouse_pos
	if Input.is_action_just_pressed("interact"):
		params.collision_mask = 0b10000000 # interactable
		var colls: = get_world_2d().direct_space_state.intersect_point(params)
		if colls.is_empty():
			if current_ui_wheel:
				current_ui_wheel.hide()
			current_ui_wheel = null
			return
		get_viewport().set_input_as_handled()
		# Find closest ui wheel
		var closest_dist: = INF
		var closest_node: Node2D = null
		for collision: Dictionary in colls:
			var collider: Node2D = collision.collider
			if mouse_pos.distance_squared_to(collider.position) < closest_dist:
				closest_dist = mouse_pos.distance_squared_to(collider.position)
				closest_node = collider
		if current_ui_wheel == closest_node:
			return
		if current_ui_wheel:
			current_ui_wheel.hide()
		closest_node.show()
		current_ui_wheel = closest_node
	elif Input.is_action_just_pressed("primary"):
		params.collision_mask = 0b1000000 # primary_interactable
		
		var colls: = get_world_2d().direct_space_state.intersect_point(params)
		if colls.is_empty():
			if current_ui_wheel:
				current_ui_wheel.visible = false
			current_ui_wheel = null
			return
		get_viewport().set_input_as_handled()
		# Find closest primary_interactable area
		var closest_dist: = INF
		var closest_node: Node2D = null
		for collision: Dictionary in colls:
			var collider: Node2D = collision.collider
			if not collider.is_visible_in_tree(): continue
			if mouse_pos.distance_squared_to(collider.position) < closest_dist:
				closest_dist = mouse_pos.distance_squared_to(collider.position)
				closest_node = collider
		
		#closest_node.visible = true

func _detect_input() -> ClientInput:
	var selecting: = Input.is_action_pressed("select")
	if selecting or not Input.is_action_just_pressed("primary"):
		return ClientInput.new(frame, -1, [], Vector2.ZERO)
	
	# Now check for navigation/attacking
	var squad_names: Array[StringName] = []
	for squad in selected_squads:
		if is_instance_valid(squad) and squad.is_alive():
			squad_names.append(squad.name)
	
	var space_state = get_world_2d().direct_space_state
	var mouse_pos: = get_global_mouse_position().round()
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

func _create_input_vfx(input: ClientInput) -> void:
	if input.state_index == 1 or input.state_index == 2:
		var vfx: Node2D = navigate_command_vfx_scene.instantiate()
		vfx.global_position = get_global_mouse_position()
		get_tree().root.add_child(vfx)

## Resets the game state back to the earliest desynced frame, then resimulates
## those desynced frames.
## Sets [member earliest_desynced_frame] to [code]frame + 1[/code].
func rollback_and_resimulate(_as_server: bool = false) -> void:
	# Rollback
	if earliest_desynced_frame < frame:
		# NOTE: Always remember to add a few lines here every time we add a new
		# type of game object that needs rollbacking
		for building: Building in get_tree().get_nodes_in_group("buildings"):
			building.return_to_frame_state(earliest_desynced_frame - 1)
		for squad: Squad in get_tree().get_nodes_in_group("squads"):
			squad.return_to_frame_state(earliest_desynced_frame - 1)
		for player: Player in get_tree().get_nodes_in_group("players"):
			player.return_to_frame_state(earliest_desynced_frame - 1)
	
	# Handle inputs
	for f in range(earliest_desynced_frame, frame + 1):
		# Handle inputs from all players
		for player_id in Server.lobby.player_ids:
			for input in player_inputs[player_id]:
				if input.frame == f:
					_handle_input(input)
					break
		
		# Update everything
		get_tree().call_group("buildings", "update", f)
		get_tree().call_group("squads", "update", f)
		get_tree().call_group("players", "update", f)
		
		# Post update everything
		get_tree().call_group("buildings", "post_update", f)
		get_tree().call_group("squads", "post_update", f)
		get_tree().call_group("players", "post_update", f)
	
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
