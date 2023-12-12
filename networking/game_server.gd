extends Node

## Autoload named GameServer

@onready var sync_interval: int = Engine.physics_ticks_per_second * .5

var started: bool = false
var level: MultiplayerLevel

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
	if not started: return
	
	level.frame += 1
	level.rollback_and_resimulate()
	_send_inputs()
	_check_eliminations()
	_check_game_end_condition()
	_send_game_frame_state()

func _send_inputs() -> void:
	# Serialize player_inputs
	var serialized_inputs: Dictionary = {}
	for player_id in Server.lobby.player_ids:
		var serialized_input_list: Array = level.player_inputs[player_id].map(ClientInput.to_bytes)
		serialized_inputs[player_id] = serialized_input_list
	
	for player_id in Server.lobby.player_ids:
		level.receive_other_player_inputs.rpc_id(player_id, serialized_inputs)

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
	
	if inputs.size() > Level.NUM_SAVED_INPUTS:
		printerr("Received > %d inputs from %d" % [Level.NUM_SAVED_INPUTS, player_id])
		return
	if inputs.size() == 0:
		printerr("Received 0 inputs from %d" % player_id)
		return
	
	var previous_inputs: Array = level.player_inputs[player_id]
	var latest_new_input: ClientInput = inputs[-1]
	
	if latest_new_input.frame < level.frame - Level.NUM_SAVED_INPUTS:
		printerr("Received inputs from frame %d but the current frame is %d" % [latest_new_input.frame, level.frame])
		return
	
	if previous_inputs.size() == 0:
		level.player_inputs[player_id] = inputs
		for input in inputs:
			if input.input_type != 0:
				level.earliest_desynced_frame = mini(level.earliest_desynced_frame, input.frame)
				break
	else:
		var latest_previous_input: ClientInput = previous_inputs[-1]
		if latest_new_input.frame > latest_previous_input.frame:
			level.player_inputs[player_id] = inputs
			for input in inputs:
				if input.frame > latest_previous_input.frame and input.input_type != 0:
					level.earliest_desynced_frame = mini(level.earliest_desynced_frame, input.frame)
					break

func _send_game_frame_state() -> void:
	if sync_state_timer == 0:
		var game_frame_state: = GameFrameState.new(level.frame)
		for s: Squad in get_tree().get_nodes_in_group("squads"):
			game_frame_state.squad_names.append(s.name)
			game_frame_state.squad_frame_states.append(s.frame_states[-1])
		for b: Building in get_tree().get_nodes_in_group("buildings"):
			game_frame_state.building_names.append(b.name)
			game_frame_state.building_frame_states.append(b.frame_states[-1])
		#Global.console.print(game_frame_state.building_names.size())
		level.receive_game_frame_state.rpc(GameFrameState.to_bytes(game_frame_state))
		sync_state_timer = sync_interval
	sync_state_timer -= 1

func _check_eliminations() -> void:
	for player: Player in get_tree().get_nodes_in_group("players"):
		var bases: = get_tree().get_nodes_in_group("bases")
		if bases.filter(func(b): return b.team == player.team).is_empty():
			level.lose_game.rpc_id(player.id, [], [])
			player.queue_free()

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
	for player: Player in get_tree().get_nodes_in_group("players"):
		if player.team == team:
			winning_player_id = player.id
			break
	
	_send_game_frame_state()
	level.end_game.rpc(winning_player_id, team)
	
	started = false
	
	var tween: = create_tween()
	tween.tween_interval(10)
	tween.tween_callback(reset)

func reset() -> void:
	started = false
	set_physics_process(false)
	if level:
		level.frame = 0
		level.queue_free()
		level = null
	sync_state_timer = sync_interval
