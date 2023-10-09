@tool
extends Node2D

var team_index: int = 0 : set = _set_team_index

func _set_team_index(value: int) -> void:
	if value >= 0 and value < TeamColors.colors.size():
		team_index = value
		$Banner.modulate = TeamColors.colors[team_index]
	else:
		print_debug("Invalid color index: %d" % value)
