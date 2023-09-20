extends Node

# Autoload named GameServer

var started: bool = false
var game: Game

var frame: int = 0
## Maps from player_id (int) to list of last 30 inputs (Array[Dictionary])
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
	for player_id in Server.lobby.player_ids:
		game.receive_other_player_inputs.rpc_id(player_id, player_inputs)

@rpc("any_peer", "unreliable")
func receive_inputs(inputs: Array) -> void:
	if not multiplayer.is_server():
		printerr("game_server.gd: This is not supposed to happen!")
		return
	if not started:
		return
	
	var sender_id: int = multiplayer.get_remote_sender_id()
	
	if inputs.size() > Game.NUM_SAVED_INPUTS:
		printerr("Received > %d inputs from %d" % [Game.NUM_SAVED_INPUTS, sender_id])
		return
	if inputs.size() == 0:
		printerr("Received 0 inputs from %d" % sender_id)
		return
	
	var latest_new_input: Dictionary = inputs[-1]
	
	var previous_inputs: Array = player_inputs[sender_id]
	if previous_inputs.size() == 0:
		player_inputs[sender_id] = inputs
		for input in inputs:
			if input.keys().size() > 1:
				needs_rollback[sender_id] = true
				break
	else:
		var latest_previous_input: Dictionary = previous_inputs[-1]
		# If the new input is more recent than the latest previous input
		if latest_new_input.f > latest_previous_input.f:
			player_inputs[sender_id] = inputs
			for input in inputs:
				if input.f > latest_previous_input.f and input.keys().size() > 1:
					needs_rollback[sender_id] = true
					break

