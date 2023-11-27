extends Control

@export_range(0, 30) var num_inputs_to_show: int
@export_range(0, 30) var num_states_to_show: int

var level: Level
var actually_ready: = false

@onready var frame_label: = $SquadInfoContainer/FrameLabel

func _create_client_input_labels() -> void:
	var client_input_label_template: = $ClientInputsContainer/Template
	
	var lobby: = Server.lobby
	
	for i in lobby.player_ids.size():
		var p_team: int = lobby.player_info_list[i].team
		var data_label: = client_input_label_template.duplicate()
		data_label.name = "ClientInputsLabel%d" % p_team
		$ClientInputsContainer.add_child(data_label)
	
	client_input_label_template.queue_free()

func _create_squad_info_labels() -> void:
	var squad_info_label_template: = $SquadInfoContainer/Template
	
	for squad in get_tree().get_nodes_in_group("squads"):
		var data_label: = squad_info_label_template.duplicate()
		data_label.name = "SquadInfoLabel%s" % squad.name
		$SquadInfoContainer.add_child(data_label)
	
	squad_info_label_template.queue_free()
	
	# Move FrameLabel to the bottom
	$SquadInfoContainer.move_child(frame_label, -1)

func initialize(_level: Level) -> void:
	_create_client_input_labels()
	_create_squad_info_labels()
	self.level = _level
	actually_ready = true

func _process(_delta) -> void:
	if not actually_ready:
		return
	
	var lobby: = Server.lobby
	for i in lobby.player_ids.size():
		var p_id: = lobby.player_ids[i]
		var p_name: = lobby.player_names[i]
		var p_team: int = lobby.player_info_list[i].team
		var p_inputs: Array = level.player_inputs[p_id]
		
		var label: Label = get_node("ClientInputsContainer/ClientInputsLabel%d" % p_team)
		label.text = _generate_client_input_text(p_name, p_team, p_inputs)
	
	for squad in get_tree().get_nodes_in_group("squads"):
		var label: Label = get_node("SquadInfoContainer/SquadInfoLabel%s" % squad.name)
		label.text = _generate_squad_info_text(squad)
	
	frame_label.text = "Frame: %s" % Strings.pad(str(Client.level.frame), 6)

func _generate_client_input_text(p_name: String, p_team: int, p_inputs: Array) -> String:
	var text: = "Client %s | Team %d\nLast %d inputs:" % [p_name, p_team, num_inputs_to_show]
	var num_inputs: = p_inputs.size()
	if num_inputs < num_inputs_to_show:
		for i in num_inputs_to_show - num_inputs:
			text += "\n"
		for p_input in p_inputs:
			text += "\n" + str(p_input)
	else:
		for i in range(num_inputs - num_inputs_to_show, num_inputs):
			text += "\n" + str(p_inputs[i])
	return text

func _generate_squad_info_text(squad: Squad) -> String:
	var text: = "Squad %s | Team %d\nLast %d states:" % [squad.name, squad.team, num_states_to_show]
	var num_states: = squad.frame_states.size()
	if num_states < num_states_to_show:
		for i in num_states_to_show - num_states:
			text += "\n"
		for state in squad.frame_states:
			text += "\n" + str(state)
	else:
		for i in range(num_states - num_states_to_show, num_states):
			text += "\n" + str(squad.frame_states[i])
	return text
