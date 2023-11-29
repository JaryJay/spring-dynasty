extends Building

@export_range(0, 500) var gold_generation: int

func _ready() -> void:
	super()
	$HealthBar.max_health = max_health

func update(_frame: int) -> void:
	if ability_cooldown > 1:
		ability_cooldown -= 1
		return
	ability_cooldown = ability_cooldown_time
	
	var players: = get_tree().get_nodes_in_group("players")
	var filtered_players: = players.filter(func(p): return p.team == team)
	if not filtered_players.is_empty():
		var owner_player: Player = filtered_players[0]
		
		owner_player.gold += gold_generation
		ability_cooldown = ability_cooldown_time

func _on_team_color_changed(color: Color):
	$Sprites/Fill.modulate = color

func _on_health_depleted(_health: int, source: Node2D):
	health = max_health
	team = source.team
