extends Building

enum SquadType {
	FOOTMAN,
	ARCHER,
	SWORDSMAN,
}

@export var squad_type: SquadType
@export var is_ai: bool
@export var controllable_squad_scenes: Array[PackedScene]
@export var ai_squad_scenes: Array[PackedScene]

func _ready() -> void:
	super()
	$HealthBar.max_health = max_health

func update() -> void:
	if ability_cooldown >= 0:
		ability_cooldown -= 1
		return
	ability_cooldown = ability_cooldown_time
	
	var squad_scene: PackedScene
	if is_ai:
		squad_scene = ai_squad_scenes[squad_type]
	else:
		squad_scene = controllable_squad_scenes[squad_type]
	var squad: = squad_scene.instantiate()
	squad.team = team
	
	var ray: RayCast2D = $Rays/Up
	for ray_cast: RayCast2D in $Rays.get_children():
		if not ray_cast.is_colliding():
			ray = ray_cast
			break
	
	squad.position = global_position + ray.target_position.rotated(ray.global_rotation)
	get_tree().get_first_node_in_group("entities_parent").add_child(squad)

func _on_team_color_changed(color: Color):
	$Sprites/Fill.modulate = color

func _on_health_depleted(_health: int, source: Node2D):
	health = max_health
	team = source.team
