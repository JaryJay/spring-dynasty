extends Node

# Autoload named Client

signal server_disconnected
signal lobby_updated
signal game_started(team_number)

signal player_connected(id)
signal player_disconnected(id)

var _is_multiplayer: = false

var user_info: Dictionary = { "name": "Bob" }
var team_number: int = -1

var level: Level = null

func init(server_ip: String, server_port: int) -> Error:
	print("Initializing client...")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	var peer = ENetMultiplayerPeer.new()
	
	print("Attempting to connect to %s:%d..." % [server_ip, server_port])
	var error = peer.create_client(server_ip, server_port)
	if error:
		printerr("Error %d occurred while creating the client" % error)
		return error
	multiplayer.multiplayer_peer = peer
	
	print("%s: Client initialized" % multiplayer.get_unique_id())
	_is_multiplayer = true
	return OK

func disconnect_from_server() -> void:
	if not _is_multiplayer:
		Global.console.print("You are not connected to the server.")
		return
	multiplayer.multiplayer_peer.close()
	_is_multiplayer = false

@rpc("authority", "reliable")
func update_lobby(player_ids: PackedInt32Array, player_names: PackedStringArray) -> void:
	print("%s: Updating lobby" % multiplayer.get_unique_id())
	Server.lobby.player_ids = player_ids
	Server.lobby.player_names = player_names
	Server.lobby.host_id = Server.lobby.player_ids[0] if Server.lobby.player_ids.size() > 0 else 0
	lobby_updated.emit()

@rpc("authority", "reliable")
func start_game(player_info_list: Array) -> void:
	Server.lobby.player_info_list.clear()
	for i in player_info_list.size():
		Server.lobby.player_info_list.append(player_info_list[i])
	team_number = Server.lobby.get_player_info(multiplayer.get_unique_id()).team
	print("%s: Starting game as team %d" % [multiplayer.get_unique_id(), team_number])
	game_started.emit()

func _on_player_connected(id: int) -> void:
	player_connected.emit(id)

func _on_player_disconnected(id: int) -> void:
	player_disconnected.emit(id)

func _on_connected_ok() -> void:
	print("%s: Connected to server" % multiplayer.get_unique_id())
	Server.register_user_info.rpc_id(1, user_info)

func _on_connected_fail() -> void:
	printerr("%s: Connection failed" % multiplayer.get_unique_id())
	multiplayer.multiplayer_peer = null

func _on_server_disconnected() -> void:
	printerr("Disconnected from server.")
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()

func is_multiplayer() -> bool:
	return _is_multiplayer

# Note: this function will not work until steam_appid.txt has a valid app id
func init_steam() -> void:
	var init_status: Dictionary = Steam.steamInit()
	print("client.gd: Initializing steam...")
	print(init_status)
	
	if init_status.status != 1:
		print("client.gd: Failed to initialize Steam. Error message:")
		print(init_status.verbal)
		#print("Shutting down...")
		#get_tree().quit()
