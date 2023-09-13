extends Node2D
class_name Game

const NUM_SAVED_INPUTS: = 30
const squad_scene: = preload("res://entities/footman_squad.tscn")

@onready var selection_rect: SelectionRect = $SelectionRect
@onready var pause_menu: Control = $PauseMenuLayer/PauseMenu

var frame: int = 0

var selected_squads: Array[Squad] = []
var controlled_team: int = 0

## Maps from player_id (int) to list of last 30 inputs (Array[Dictionary])
var player_inputs: Dictionary = {}
## Maps from player_id (int) to whether that player needs a rollback (bool)
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
			squad.name = "FootmanSquad_%d_%d" % [team, i]
			$Squads.add_child(squad)

func _physics_process(_delta):
	_rollback_and_resimulate()
	
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
	
	var created_input: = handle_inputs()
	if not created_input:
		_add_input({ "f": frame })
	
	var inputs: Array = player_inputs[multiplayer.get_unique_id()]
	GameServer.receive_inputs.rpc_id(1, inputs)
	
	frame += 1

@rpc("authority", "unreliable")
func receive_other_player_inputs(inputs: Dictionary) -> void:
	for player_id in inputs.keys():
		if inputs[player_id].is_empty():
			continue
		
		var previous_inputs: Array = player_inputs[player_id]
		var latest_new_input: Dictionary = inputs[player_id][-1]
		if previous_inputs.size() == 0:
			player_inputs[player_id] = inputs[player_id]
			needs_rollback[player_id] = true
		else:
			var latest_previous_input: Dictionary = previous_inputs[-1]
			if latest_new_input.f > latest_previous_input.f:
				player_inputs[player_id] = inputs[player_id]
				needs_rollback[player_id] = true

func _rollback_and_resimulate() -> void:
	# TODO: implement this
	
	for player_id in needs_rollback.keys():
		if needs_rollback[player_id]:
			pass
	pass

func handle_inputs() -> bool:
	if Input.is_action_pressed("ui_cancel"):
		pause_menu.visible = !pause_menu.visible
	
	var selecting: = Input.is_action_pressed("select")
	if Input.is_action_pressed("primary") and not selecting:
		if selected_squads.size() == 0:
			return false
		
		var mouse_pos: = get_global_mouse_position()
		var space_state = get_world_2d().direct_space_state
		var query: = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		query.collision_mask = 1 # Collide with squads
		
		var collisions: = space_state.intersect_point(query)
		
		if collisions.size() == 0:
			_navigate_squads_to_point(mouse_pos)
			return false
		
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
			_navigate_squads_to_enemy(closest_enemy_squad)
		else:
			# This will happen if all clicked squads are friendly
			_navigate_squads_to_point(mouse_pos)
		return true
	return false

func _navigate_squads_to_enemy(enemy_squad: Squad) -> void:
	for squad in selected_squads:
		var chasing_state: = squad.state_machine.get_node("ChasingState")
		chasing_state.chased_squad = enemy_squad
		squad.state_machine.state = chasing_state
	
	var squad_names: Array[StringName] = []
	for squad in selected_squads:
		squad_names.append(squad.name)
	_add_input({
		"f": frame,
		"state": "C",
		"squads": squad_names,
		"enemy_squad": enemy_squad.name,
	})

func _navigate_squads_to_point(point: Vector2) -> void:
	for squad in selected_squads:
		squad.set_target_position(point)
		squad.state_machine.state = squad.state_machine.get_node("NavigatingState")
	
	var squad_names: Array[StringName] = []
	for squad in selected_squads:
		squad_names.append(squad.name)
	_add_input({
		"f": frame,
		"state": "N",
		"squads": squad_names,
		"target": point,
	})

func _add_input(input: Dictionary) -> void:
	var player_input_list: Array = player_inputs[multiplayer.get_unique_id()]
	player_input_list.append(input)
	if player_input_list.size() > NUM_SAVED_INPUTS:
		player_input_list.remove_at(0)
