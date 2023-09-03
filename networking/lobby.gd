class_name Lobby

var host_id: int
var player_ids: PackedInt32Array = []
var player_names: PackedStringArray = []

func get_player_name(player_id: int) -> String:
	return player_names[player_ids.find(player_id)]
