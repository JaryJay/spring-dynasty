extends Node

# Autoload named GameServer

var started: bool = false
var game: Game

## Maps from player_id (int) to list of last 30 inputs (Array[ClientInput])
var player_inputs: Dictionary = {}
## Maps from player_id (int) to whether that player needs a rollback (bool)
var needs_rollback: Dictionary = {}

var send_game_state_timer: = 144 * 1

func _ready() -> void:
	set_physics_process(false)

func start() -> void:
	for player_id in Server.lobby.player_ids:
		player_inputs[player_id] = []
	started = true
	set_physics_process(true)

func _physics_process(_delta) -> void:	
	game.frame += 1
	game._rollback_and_resimulate()
	_send_inputs()
#	_send_game_frame_state()

func _send_inputs() -> void:
	# Serialize player_inputs
	var serialized_inputs: Dictionary = {}
	for player_id in Server.lobby.player_ids:
		var serialized_input_list: Array = player_inputs[player_id].map(ClientInput.to_bytes)
		serialized_inputs[player_id] = serialized_input_list
	
	for player_id in Server.lobby.player_ids:
		game.receive_other_player_inputs.rpc_id(player_id, serialized_inputs)

@rpc("any_peer", "unreliable")
func receive_inputs(serialized_input_list: Array) -> void:
	# Deserialize inputs
	var input_list: Array = []
	for serialized_input in serialized_input_list:
		input_list.append(ClientInput.create_from(serialized_input))
	
	if not multiplayer.is_server():
		printerr("game_server.gd: This is not supposed to happen!")
		return
	if not started:
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	
	if input_list.size() > Game.NUM_SAVED_INPUTS:
		printerr("Received > %d inputs from %d" % [Game.NUM_SAVED_INPUTS, sender_id])
		return
	if input_list.size() == 0:
		printerr("Received 0 inputs from %d" % sender_id)
		return
	
	var latest_new_input: ClientInput = input_list[-1]
	
	var previous_inputs: Array = player_inputs[sender_id]
	if previous_inputs.size() == 0:
		player_inputs[sender_id] = input_list
		for input in input_list:
			if input.state_index >= 0:
				needs_rollback[sender_id] = true
				break
	else:
		var latest_previous_input: ClientInput = previous_inputs[-1]
		# If the new input is more recent than the latest previous input
		if latest_new_input.frame > latest_previous_input.frame:
#			if latest_new_input.state_index != -1:
#				print("Frame %d: Received new input from %d" % [game.frame, sender_id])
			player_inputs[sender_id] = input_list
			for input in input_list:
				if input.frame > latest_previous_input.frame and input.state_index >= 0:
					needs_rollback[sender_id] = true
					break

func _send_game_frame_state() -> void:
	if send_game_state_timer == 0:
		var game_frame_state: = GameFrameState.new(game.frame)
		for _squad in get_tree().get_nodes_in_group("squads"):
			var squad: Squad = _squad
			game_frame_state.squad_names.append(squad.name)
			game_frame_state.squad_frame_states.append(squad.frame_states[-1])
			print("Created frame state: " + str(squad.frame_states[-1]))
		
		game.receive_game_frame_state.rpc(GameFrameState.to_bytes(game_frame_state))
		send_game_state_timer = 144 * 1 # 10 seconds
	send_game_state_timer -= 1

func reset() -> void:
	started = false
	set_physics_process(false)
	if game:
		game.frame = 0
		game.queue_free()
		game = null
	player_inputs.clear()
	needs_rollback.clear()
