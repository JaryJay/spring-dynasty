extends Node

# Autoload named GameServer

var frame_number: = 0
## Maps from player_id (int) to list of last 30 inputs (Array[Dictionary])
var player_inputs: Dictionary = {}

func _ready():
	if not multiplayer.is_server():
		return
	
	for player_id in Server.lobby.player_ids:
		player_inputs[player_id] = []

@rpc("any_peer", "unreliable")
func receive_inputs(inputs: Array) -> void:
	if not multiplayer.is_server():
		printerr("game_server.gd: This is not supposed to happen!")
		return
	
	if inputs.size() > Game.NUM_SAVED_INPUTS:
		printerr("Number of inputs too large")
		return
	
	var has_non_empty_inputs: = false
	for _input in inputs:
		var input: Dictionary = _input
		if input.has("state"):
			has_non_empty_inputs = true
	
	if has_non_empty_inputs:
		print("============== Received inputs: ==============")
		for _input in inputs:
			var input: Dictionary = _input
			if input.has("state"):
				print(input)

