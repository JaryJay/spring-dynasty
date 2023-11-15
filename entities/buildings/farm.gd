extends Building

@export_range(0, 500) var gold_generation: int

func _ready() -> void:
	super()
	$HealthBar.max_health = max_health

func update() -> void:
	if ability_cooldown == 0:
		var players: = get_tree().get_nodes_in_group("players")
		var filtered_players: = players.filter(func(p): return p.team == team)
		var owner_player: Player = filtered_players[0]
		
		owner_player.gold += gold_generation
		ability_cooldown = ability_cooldown_time
	ability_cooldown -= 1

func _on_team_color_changed(color: Color):
	$Sprites/Fill.modulate = color

func _on_health_depleted(_health: int, source: Node2D):
	health = max_health
	team = source.team
