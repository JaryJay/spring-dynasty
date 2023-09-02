extends Node

# Autoload named Client

var player_info: Dictionary

func _ready():
	if "--server" in OS.get_cmdline_user_args():
		queue_free()
		return

func init():
	print("Initializing client...")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(Server.DEFAULT_SERVER_IP, Server.PORT)
	if error:
		printerr("Error %d occurred while creating the client. Aborting..." % error)
		get_tree().quit()
		return
	multiplayer.multiplayer_peer = peer
	
	print("Client initialized")

func _on_player_connected(id: int) -> void:
	if id == 1:
		_register_player.rpc_id(id, player_info)

func _on_player_disconnected(id: int) -> void:
	print("Player %d disconnected" % id)
	player_info.erase(id)
	player_disconnected.emit(id)

func _on_connected_ok() -> void:
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

func _on_connected_fail() -> void:
	printerr("Connection failed")
	multiplayer.multiplayer_peer = null

func _on_server_disconnected() -> void:
	printerr("The server has disconnected")
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
