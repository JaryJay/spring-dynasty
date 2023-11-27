extends Control

@onready var player_list: = %PlayerList
@onready var status_label: = %StatusLabel

func _ready():
	%NameLabel.text = Client.user_info.name
	_on_lobby_updated()
	
	Client.lobby_updated.connect(_on_lobby_updated)
	# The game_started signal will emit when the server calls Client.start_game
	Client.game_started.connect(_on_game_started)

func _on_lobby_updated() -> void:
	var is_host: = Server.lobby.host_id == multiplayer.get_unique_id()
	%StartButton.visible = is_host
	if not is_host:
		%Label.text = "Waiting for Host..."
	else:
		%Label.text = "You are the Host"
	
	var lobby: = Server.lobby
	player_list.clear()
	for i in range(lobby.player_ids.size()):
		if lobby.player_ids[i] == lobby.host_id:
			player_list.add_item(lobby.player_names[i] + " (Host)")
		else:
			player_list.add_item(lobby.player_names[i])

func _on_start_button_pressed() -> void:
	print("%s: Requesting game start" % multiplayer.get_unique_id())
	Server.start_game.rpc_id(1)
	status_label.text = "Waiting for Server..."

func _on_game_started() -> void:
	print("%s: Game started" % multiplayer.get_unique_id())
	get_tree().change_scene_to_file("res://levels/multiplayer/multiplayer_level_1.tscn")
