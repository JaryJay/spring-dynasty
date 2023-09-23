extends Node

# Autoload named GameServer

var started: bool = false
var game: Game

var frame: int = 0
## Maps from player_id (int) to list of last 30 inputs (Array[ClientInput])
var player_inputs: Dictionary = {}
## Maps from player_id (int) to whether that player needs a rollback (bool)
var needs_rollback: Dictionary = {}

func start() -> void:
	for player_id in Server.lobby.player_ids:
		player_inputs[player_id] = []
	started = true

func _physics_process(_delta) -> void:
	if not started:
		return
	_rollback_and_resimulate()
	_send_inputs()
	frame += 1

func _rollback_and_resimulate() -> void:
	for player_id in needs_rollback.keys():
		if needs_rollback[player_id]:
			print("%d needs rollback" % player_id)
			# TODO: Do rollback :)
			needs_rollback[player_id] = false

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
			if not input.state == "":
				needs_rollback[sender_id] = true
				break
	else:
		var latest_previous_input: ClientInput = previous_inputs[-1]
		# If the new input is more recent than the latest previous input
		if latest_new_input.frame > latest_previous_input.frame:
			player_inputs[sender_id] = input_list
			for input in input_list:
				if input.frame > latest_previous_input.frame and not input.state == "":
					needs_rollback[sender_id] = true
					break

