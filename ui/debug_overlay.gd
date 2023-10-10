extends VBoxContainer

@export_range(0, 30) var num_inputs_to_show: = 10

var game: Game
var actually_ready: = false

func _ready() -> void:
	var client_data_label_template: = $ClientDataLabelTemplate
	
	var lobby: Lobby = Client.lobby
	for i in lobby.player_ids.size():
		var p_team: int = lobby.player_info_list[i].team
		
		var data_label: = client_data_label_template.duplicate()
		data_label.name = "ClientDataLabel%d" % p_team
		add_child(data_label)
	
	client_data_label_template.queue_free()

func initialize(game: Game) -> void:
	self.game = game
	actually_ready = true

func _process(_delta) -> void:
	if not actually_ready:
		return
	
	var lobby: Lobby = Client.lobby
	for i in lobby.player_ids.size():
		var p_id: = lobby.player_ids[i]
		var p_name: = lobby.player_names[i]
		var p_team: int = lobby.player_info_list[i].team
		var p_inputs: Array = game.player_inputs[p_id]
		
		var data_label: Label = get_node("ClientDataLabel%d" % p_team)
		data_label.text = generate_text(p_id, p_name, p_team, p_inputs)

func generate_text(p_id: int, p_name: String, p_team: int, p_inputs: Array) -> String:
	var text: = "Client %s | Team %d\nLast %d inputs:" % [p_name, p_team, num_inputs_to_show]
	var num_inputs: = p_inputs.size()
	if num_inputs < num_inputs_to_show:
		for p_input in p_inputs:
			text += "\n" + str(p_input)
	else:
		for i in range(num_inputs - num_inputs_to_show - 1, num_inputs):
			text += "\n" + str(p_inputs[i])
	return text
