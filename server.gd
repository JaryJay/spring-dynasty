extends Node

# Autoload named Server
# A Node with this script attached is automatically created on startup.
# See docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
# for more details!

const PORT = 45000
const MAX_CONNECTIONS = 32

const game_scene: = preload("res://game.tscn")

var lobby: Lobby = Lobby.new()

enum GameState { LOBBY, WAITING, IN_GAME }
var state: GameState = GameState.LOBBY

var teams_in_use: Array[int] = []

func _ready() -> void:
	if not "--server" in OS.get_cmdline_user_args():
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

func _on_player_disconnected(id: int) -> void:
	print("Player %d disconnected" % id)
	
	if lobby.player_ids.find(id) == -1:
		return
	
	# Calculate new host
	var i: = lobby.player_ids.find(id)
	lobby.player_ids.remove_at(i)
	lobby.player_names.remove_at(i)
	if lobby.host_id == id:
		if lobby.player_ids.size() > 0:
			lobby.host_id = lobby.player_ids[0]
		else:
			lobby.host_id = 0
	
	print("Updating client lobbies")
	Client.update_lobby.rpc(lobby.player_ids, lobby.player_names)

# Any peer can call this RPC. See client.gd's _on_connected_ok function
@rpc("any_peer", "reliable")
func register_user_info(user_info: Dictionary) -> void:
	var id: = multiplayer.get_remote_sender_id()
	print("Registering peer %d" % id)
	
	if not ("name" in user_info and user_info.name is String):
		print("Kicking peer %d because name not found" % id)
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	
	var player_name: String = user_info.name
	if player_name.length() > 50:
		printerr("Kicking peer %d because name is too long" % player_name)
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	print("Peer %d successfully registered as '%s'" % [id, player_name])
	
	lobby.player_ids.append(id)
	lobby.player_names.append(player_name)
	if lobby.host_id == 0:
		lobby.host_id = id
	
	print("Updating client lobbies")
	Client.update_lobby.rpc(lobby.player_ids, lobby.player_names)

@rpc("any_peer", "reliable")
func start_game() -> void:
	state = GameState.WAITING
	var sender_id: = multiplayer.get_remote_sender_id()
	if not sender_id == lobby.host_id:
		printerr("Start game called by non-host player")
		return
	
	print("Game starting")
	
	var game: = game_scene.instantiate()
	game.is_server = true
	get_tree().root.add_child(game)
	
	var team_numbers: Array[int] = [0, 1, 2, 3, 4, 5]
	team_numbers.shuffle()
	for i in lobby.player_ids.size():
		var team_number: = team_numbers[i]
		lobby.player_info_list.append({ "team": team_number })
	
	for i in lobby.player_ids.size():
		Client.start_game.rpc_id(lobby.player_ids[i], lobby.player_info_list)
	teams_in_use = team_numbers.slice(0, lobby.player_ids.size())
