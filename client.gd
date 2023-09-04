extends Node

# Autoload named Client

signal server_disconnected
signal player_connected(id)
signal player_disconnected(id)

var user_info: Dictionary = { "name": "Bob" }

var lobby: Lobby = Lobby.new()

func _ready():
	if "--server" in OS.get_cmdline_user_args():
		return
	init()

func init():
	print("Initializing client...")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	var peer = ENetMultiplayerPeer.new()
	
	const SERVER_IP: = Server.DEFAULT_SERVER_IP
	const SERVER_PORT: = Server.PORT
	
	print("Attempting to connect to %s:%d..." % [SERVER_IP, SERVER_PORT])
	var error = peer.create_client(SERVER_IP, SERVER_PORT)
	if error:
		printerr("Error %d occurred while creating the client. Aborting..." % error)
		get_tree().quit()
		return
	multiplayer.multiplayer_peer = peer
	
	print("Client initialized")

@rpc("authority", "reliable")
func update_lobby(player_ids: PackedInt32Array, player_names: PackedStringArray) -> void:
	print("Updating lobby")
	lobby.player_ids = player_ids
	lobby.player_names = player_names
	print(player_names)

func _on_player_connected(id: int) -> void:
	player_connected.emit(id)

func _on_player_disconnected(id: int) -> void:
	print("Player %d disconnected" % id)
	player_disconnected.emit(id)

func _on_connected_ok() -> void:
	print("Connected to server")
	var peer_id = multiplayer.get_unique_id()
	Server.register_user_info.rpc_id(1, user_info)

func _on_connected_fail() -> void:
	printerr("client.gd: Connection failed")
	multiplayer.multiplayer_peer = null

func _on_server_disconnected() -> void:
	printerr("Disconnected from server")
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()

# Note: this function will not work until steam_appid.txt has a valid app id
func init_steam() -> void:
	var init: Dictionary = Steam.steamInit()
	print("user.gd: Initializing steam...")
	print(init)
	
	if init.status != 1:
		print("user.gd: Failed to initialize Steam. Error message:")
		print(init.verbal)
		print("Shutting down...")
		get_tree().quit()
