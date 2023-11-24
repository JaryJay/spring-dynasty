@tool
extends Squad
class_name AiSquad

enum Intelligence {
	LEAGUE_PLAYER,
	NORMAL,
	FIERCE,
	REMORSELESS,
}

@export var intelligence: Intelligence = Intelligence.NORMAL

func get_closest_enemy_squad() -> Squad:
	var enemy_squads: Array[Squad]
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
