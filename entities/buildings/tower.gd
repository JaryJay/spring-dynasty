extends Building

@export_range(0, 500) var gold_generation: int

#@onready var particles: = $Particles
@onready var awareness_area: Area2D = $AwarenessArea
@onready var target_squad: Squad = null
@onready var damage: int = 10

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
	
	target_squad = _find_target(target_squad)
	
	if target_squad == null:
		return
	target_squad.change_health(-damage, self) # idk what the source should be

func _find_target(past_target: Squad) -> Squad:
	if past_target == null or not (awareness_area.overlaps_body(past_target) and past_target.is_alive()): # no target or past target gone
		return get_closest_enemy_squad()
	return past_target

# shamelessly stolen from ai_squad.gd
func get_closest_enemy_squad() -> Squad:
	var enemy_squads: Array[Squad] = []
	for body: PhysicsBody2D in awareness_area.get_overlapping_bodies():
		if body is Squad and not body.team == team and body.is_alive():
			enemy_squads.append(body)
	
	if enemy_squads.is_empty():
		return null
	
	var closest_dist: = INF
	var closest_squad: Squad = null
	for enemy: Squad in enemy_squads:
		if position.distance_squared_to(enemy.position) < closest_dist:
			closest_dist = position.distance_squared_to(enemy.position)
			closest_squad = enemy
	return closest_squad


# not sure if these will be needed yet

func _on_team_color_changed(color: Color):
	$Sprites/Fill.modulate = color

func _on_health_depleted(_health: int, source: Node2D):
	health = max_health
	team = source.team
	ability_cooldown = ability_cooldown_time
