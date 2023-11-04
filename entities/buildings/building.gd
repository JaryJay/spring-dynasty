@tool
extends StaticBody2D
class_name Building

signal team_color_changed(color)

@export_range(0, 5) var team: int = 0 : set = _set_team_index
@export_range(0, 500) var health: int

func _set_team_index(value: int) -> void:
	if value >= 0 and value < TeamColors.colors.size():
		team = value
		team_color_changed.emit(TeamColors.colors[team])
	else:
		printerr("Invalid color index: %d" % value)
