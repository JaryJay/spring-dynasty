extends Control

@onready var error_label: Label = %ErrorLabel

const lobby_menu_scene: PackedScene = preload("res://ui/lobby_menu.tscn")
var lobby_id: int

func _ready() -> void:
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.lobby_message.connect(_on_lobby_message)
	Steam.persona_state_change.connect(_on_persona_change)
	
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	
	check_command_line()
	
	print("Requesting a lobby list")
	Steam.requestLobbyList()
	# Once the lobby list is returned, the _on_lobby_match_list callback
	# will be triggered
func check_command_line() -> void:
	var arguments: Array = OS.get_cmdline_args()
	if arguments.size() == 0:
		return
	# If a Steam connection argument exists
	if arguments[0] == "+connect_lobby" and int(arguments[1]) > 0:
		# Lobby invite exists so try to connect to it
		# At this point, you'll probably want to change scenes
		# Something like a loading into lobby screen
		print("Command line lobby ID: %s" % arguments[1])
		join_lobby(int(arguments[1]))

func join_lobby(join_lobby_id):
	var username: String = %NameInput.text
	var server_ip: String = %ServerIPInput.text
	var port: String = %PortInput.text
	
	if username == "" or server_ip == "" or port == "":
		error_label.text = "One or more inputs are empty"
		return
	elif not port.is_valid_int():
		error_label.text = "Invalid port"
		return
	
	Client.user_info["name"] = username
	var result: = Client.init(server_ip, int(port))
	if result != OK:
		error_label.text = "Error %s occurred" % result
	else:
		get_tree().change_scene_to_packed(lobby_menu_scene)

func _on_lobby_join_requested() -> void:
	print("_on_lobby_join_requested")
func _on_lobby_chat_update() -> void:
	print("_on_lobby_chat_update")
func _on_lobby_created(status: int, _lobby_id: int) -> void:
	if status != 1:
		print("Unsuccessful.")
	# Set the lobby ID
	lobby_id = _lobby_id
	print("Created a lobby: %s" % lobby_id)

	# Set this lobby as joinable, just in case, though this should be done by default
	Steam.setLobbyJoinable(lobby_id, true)

	# Set some lobby data
	Steam.setLobbyData(lobby_id, "name", "Jay's Test Lobby")
	Steam.setLobbyData(lobby_id, "mode", "Jay's Test Mode")

	# Allow P2P connections to fallback to being relayed through Steam if needed
	var set_relay: bool = Steam.allowP2PPacketRelay(true)
	print("Allowing Steam to be relay backup: %s" % set_relay)
	Steam.requestLobbyList()

func _on_lobby_data_update() -> void:
	print("_on_lobby_data_update")
func _on_lobby_invite() -> void:
	print("_on_lobby_invite")
func _on_lobby_joined(_lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void:
	print("_on_lobby_joined %s %s %s %s" % [_lobby_id, _permissions, _locked, _response])

func _on_lobby_match_list(lobbies: Array) -> void:
	%SearchingLabel.hide()
	
	if lobbies.is_empty():
		%EmptyLabel.show()
		return
	
	var server_list: ItemList = %ServerList
	server_list.show()
	
	for lobby in lobbies:
		print("lobby: %s" % lobby)
		# Pull lobby data from Steam, these are specific to our example
		var l_name: String = Steam.getLobbyData(lobby, "name")
		var l_mode: String = Steam.getLobbyData(lobby, "mode")
		# Get the current number of members
		var l_num_members: int = Steam.getNumLobbyMembers(lobby)
		server_list.add_item("[%s] %s - %s players" % [l_mode, l_name, l_num_members])

func _on_lobby_message() -> void:
	print("_on_lobby_message")
func _on_persona_change(user_steam_id: int, flag: int) -> void:
	if lobby_id == 0:
		return
	print("_on_persona_change %s %s" % [user_steam_id, flag])

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_host_button_pressed():
	print("Host button pressed")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 6)

func _process(_delta):
	Steam.run_callbacks()
