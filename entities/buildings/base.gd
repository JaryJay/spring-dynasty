extends Building

func _ready() -> void:
	super()
	$HealthBar.max_health = max_health

func _on_team_color_changed(color: Color) -> void:
	$Sprites/Fill.modulate = color

func _on_health_depleted(_health: int, source: Node2D) -> void:
	health = max_health
	team = source.team
