extends Node

## Autoload named GameServer

@onready var sync_interval: int = Engine.physics_ticks_per_second * .5

var started: bool = false
var game: Game

@onready var sync_state_timer: = sync_interval

func _ready() -> void:
	set_physics_process(false)

func start() -> void:
	started = true
	set_physics_process(true)
	
	var set_sync_interval_command = \
	ConsoleCommand.new("setsyncinterval", 1, func(args):
		var val: = float(args[0])
		if is_zero_approx(val) or val < 1.0 / Engine.physics_ticks_per_second:
			Global.console.print("Invalid sync interval")
			return
		sync_interval = int(val * Engine.physics_ticks_per_second)
		Global.console.print("Sync interval set to %d frames." % sync_interval)
	)
	Global.console.commands.append(set_sync_interval_command)

func _physics_process(_delta) -> void:
	game.frame += 1
	game.rollback_and_resimulate()
	_send_inputs()
	_check_game_end_condition()
	_send_game_frame_state()

func _send_inputs() -> void:
	# Serialize player_inputs
	var serialized_inputs: Dictionary = {}
	for player_id in Server.lobby.player_ids:
		var serialized_input_list: Array = game.player_inputs[player_id].map(ClientInput.to_bytes)
		serialized_inputs[player_id] = serialized_input_list
	
	for player_id in Server.lobby.player_ids:
		game.receive_other_player_inputs.rpc_id(player_id, serialized_inputs)

@rpc("any_peer", "unreliable")
func receive_inputs(serialized_input_list: Array) -> void:
	if not multiplayer.is_server():
		printerr("game_server.gd: This is not supposed to happen!")
		return
	if not started:
		return
	
	# Deserialize inputs
	var inputs: Array = serialized_input_list.map(ClientInput.create_from)
	var player_id: int = multiplayer.get_remote_sender_id()
	
	if inputs.size() > Game.NUM_SAVED_INPUTS:
		printerr("Received > %d inputs from %d" % [Game.NUM_SAVED_INPUTS, player_id])
		return
	if inputs.size() == 0:
		printerr("Received 0 inputs from %d" % player_id)
		return
	
	var previous_inputs: Array = game.player_inputs[player_id]
	var latest_new_input: ClientInput = inputs[-1]
	
	if latest_new_input.frame < game.frame - Game.NUM_SAVED_INPUTS:
		printerr("Received inputs from frame %d but the current frame is %d" % [latest_new_input.frame, game.frame])
		return
	
	if previous_inputs.size() == 0:
		game.player_inputs[player_id] = inputs
		for input in inputs:
			if input.state_index >= 0:
				game.earliest_desynced_frame = mini(game.earliest_desynced_frame, input.frame)
				break
	else:
		var latest_previous_input: ClientInput = previous_inputs[-1]
		if latest_new_input.frame > latest_previous_input.frame:
			game.player_inputs[player_id] = inputs
			for input in inputs:
				if input.frame > latest_previous_input.frame and input.state_index >= 0:
					game.earliest_desynced_frame = mini(game.earliest_desynced_frame, input.frame)
					break

func _send_game_frame_state() -> void:
	if sync_state_timer == 0:
		var game_frame_state: = GameFrameState.new(game.frame)
		for s: Squad in get_tree().get_nodes_in_group("squads"):
			game_frame_state.squad_names.append(s.name)
			game_frame_state.squad_frame_states.append(s.frame_states[-1])
		for b: Building in get_tree().get_nodes_in_group("buildings"):
			game_frame_state.building_names.append(b.name)
			game_frame_state.building_frame_states.append(b.frame_states[-1])
		#Global.console.print(game_frame_state.building_names.size())
		game.receive_game_frame_state.rpc(GameFrameState.to_bytes(game_frame_state))
		sync_state_timer = sync_interval
	sync_state_timer -= 1

func _check_game_end_condition() -> void:
	if Server.lobby.player_ids.size() == 1:
		return
	
	var team: = -1
	for building: Building in get_tree().get_nodes_in_group("buildings"):
		if not building is Base:
			continue
		if team != -1 and building.team != team:
			return
		elif team == -1:
			team = building.team
	if team == -1:
		return
	
	# If we get here, then the player with that team has won.
	Global.console.print("Player %d has won!" % team)
	
	var winning_player_id: = -1
	for player_id in Server.lobby.player_ids:
		if Server.lobby.get_player_info(winning_player_id).team == team:
			winning_player_id = player_id
			break
	
	_send_game_frame_state()
	game.end_game.rpc(winning_player_id, team)
	
	started = false
	set_physics_process(false)

func reset() -> void:
	started = false
	set_physics_process(false)
	if game:
		game.frame = 0
		game.queue_free()
		game = null
	sync_state_timer = sync_interval
