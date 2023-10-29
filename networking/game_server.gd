extends Node

# Autoload named GameServer

var started: bool = false
var game: Game

var send_game_state_timer: = 144 * 1

func _ready() -> void:
	set_physics_process(false)

func start() -> void:
	started = true
	set_physics_process(true)

func _physics_process(_delta) -> void:	
	game.frame += 1
	game._rollback_and_resimulate()
	_send_inputs()
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
	var input_list: Array = []
	for serialized_input in serialized_input_list:
		input_list.append(ClientInput.create_from(serialized_input))
	
	var player_id: int = multiplayer.get_remote_sender_id()
	
	if input_list.size() > Game.NUM_SAVED_INPUTS:
		printerr("Received > %d inputs from %d" % [Game.NUM_SAVED_INPUTS, player_id])
		return
	if input_list.size() == 0:
		printerr("Received 0 inputs from %d" % player_id)
		return
	
	var previous_inputs: Array = game.player_inputs[player_id]
	var latest_new_input: ClientInput = input_list[-1]
	
	if previous_inputs.size() == 0:
		game.player_inputs[player_id] = input_list
	else:
		var latest_previous_input: ClientInput = previous_inputs[-1]
		if latest_new_input.frame > latest_previous_input.frame:
			# TODO: Sanitize inputs
			game.player_inputs[player_id] = input_list
		else:
			return
	
	for input in input_list:
		if input.state_index >= 0:
			game.earliest_desynced_frame = mini(game.earliest_desynced_frame, input.frame)
			break

func _send_game_frame_state() -> void:
	if send_game_state_timer == 0:
		var game_frame_state: = GameFrameState.new(game.frame)
		for _squad in get_tree().get_nodes_in_group("squads"):
			var squad: Squad = _squad
			game_frame_state.squad_names.append(squad.name)
			game_frame_state.squad_frame_states.append(squad.frame_states[-1])
			#print("Created frame state: " + str(squad.frame_states[-1]))
		print(str(game_frame_state))
		game.receive_game_frame_state.rpc(GameFrameState.to_bytes(game_frame_state))
		send_game_state_timer = 144 * 1 # 1 second
	send_game_state_timer -= 1

func reset() -> void:
	started = false
	set_physics_process(false)
	if game:
		game.frame = 0
		game.queue_free()
		game = null
