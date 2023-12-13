extends Building

@export_range(0, 500) var gold_generation: int

@onready var particles: = $Particles

func _ready() -> void:
	super()
	$HealthBar.max_health = max_health
	$ProgressBar.max_value = ability_cooldown_time

func update(frame: int) -> void:
	super.update(frame)
	if ability_cooldown > 1:
		ability_cooldown -= 1
		$ProgressBar.on_value_changed(0, (ability_cooldown_time - ability_cooldown))
		return
	ability_cooldown = ability_cooldown_time
	$ProgressBar.on_value_changed(0, (ability_cooldown_time - ability_cooldown))
	
	var players: = get_tree().get_nodes_in_group("players")
	var filtered_players: = players.filter(func(p): return p.team == team)
	if not filtered_players.is_empty():
		var owner_player: Player = filtered_players[0]
		
		owner_player.gold += gold_generation
		ability_cooldown = ability_cooldown_time
		
		particles.emit_particle(Transform2D.IDENTITY, Vector2.ZERO, Color.WHITE, Color.WHITE, 0)

func _on_team_color_changed(color: Color):
	$Sprites/Fill.modulate = color

func _on_health_depleted(_health: int, source: Node2D):
	health = max_health
	team = source.team
	ability_cooldown = ability_cooldown_time
