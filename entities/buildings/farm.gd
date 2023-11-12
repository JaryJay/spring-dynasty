extends Building

func _ready() -> void:
	$HealthBar.max_health = max_health

func update(_frame: int) -> void:
	#if not multiplayer.is_server():
		#var game: Game = get_node("/root/Game")
		#game.player_frame_states[-1].gold += 1
	pass

func _on_team_color_changed(color: Color):
	$Sprites/Fill.modulate = color

func _on_health_depleted(_health: int, source: Node2D):
	health = max_health
	team = source.team
