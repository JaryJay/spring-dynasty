@tool
extends Node2D

@export var team_colors: Array[Color] = []

var team_index: int = 0 : set = _set_team_index

func _set_team_index(value: int) -> void:
	if value >= 0 and value < team_colors.size():
		team_index = value
		$Banner.modulate = team_colors[team_index]
	else:
		print_debug("Invalid color index: %d" % value)
