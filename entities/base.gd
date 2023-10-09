@tool
extends StaticBody2D

@export_range(0, 5) var team: int = 0 : set = _set_team_index

func _set_team_index(value: int) -> void:
	if value >= 0 and value < TeamColors.colors.size():
		team = value
		$Sprites/Fill.modulate = TeamColors.colors[team]
	else:
		print_debug("Invalid color index: %d" % value)
