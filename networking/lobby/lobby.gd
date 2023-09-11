class_name Lobby

var host_id: int
var player_ids: PackedInt32Array = []
var player_names: PackedStringArray = []
var player_info_list: Array[Dictionary] = []

func get_player_name(player_id: int) -> String:
	return player_names[player_ids.find(player_id)]

func get_player_info(player_id: int) -> Dictionary:
	return player_info_list[player_ids.find(player_id)]
