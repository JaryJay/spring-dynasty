extends Node

# Autoload named Server
# A Node with this script attached is automatically created on startup.
# See docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# for more details!

const PORT = 45000
const DEFAULT_SERVER_IP = "99.250.93.242" # IPv4 localhost
const MAX_CONNECTIONS = 32

var lobby: Lobby = Lobby.new()

func _ready() -> void:
	if not "--server" in OS.get_cmdline_user_args():
		queue_free()
		return
	
	print("Initializing server...")
	
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		printerr("Error %d occurred while creating the server. Aborting..." % error)
		get_tree().quit()
		return
	multiplayer.multiplayer_peer = peer
	
	print("Server listening on port %d" % PORT)

func _on_player_connected(id: int) -> void:
	print("Player %d connected" % id)
	lobby.player_ids.append(id)
	if lobby.host_id == 0:
		lobby.host_id = id

func _on_player_disconnected(id: int) -> void:
	print("Player %d disconnected" % id)
	lobby.player_ids.erase(id)
	if lobby.host_id == id:
		if lobby.player_ids.size() > 0:
			lobby.host_id = lobby.player_ids[0]
		else:
			lobby.host_id = 0
