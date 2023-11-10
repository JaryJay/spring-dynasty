extends StaticBody2D
class_name Building

signal team_color_changed(color)

## Emitted when the health changes
signal health_changed(old, new)
## Emitted when health reaches 0
signal health_depleted(health, source)

@export_range(0, 5) var team: int = 0 : set = _set_team_index
@export_range(0, 500) var max_health: int

@onready var health: int = max_health : set = _set_health

func update(_frame: int) -> void:
	pass

func change_health(change: int, source: Node2D) -> void:
	health += change
	if health <= 0:
		health_depleted.emit(health, source)

func _set_team_index(value: int) -> void:
	if value >= 0 and value < TeamColors.colors.size():
		team = value
		team_color_changed.emit(TeamColors.colors[team])
	else:
		printerr("Invalid color index: %d" % value)

func _set_health(value: int) -> void:
	if health == value: return
	
	var old: = health
	health = value
	
	if not is_node_ready() or Engine.is_editor_hint(): return
	
	health_changed.emit(old, health)
