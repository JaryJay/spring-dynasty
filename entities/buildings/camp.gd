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
	$ProgressBar.max_value = ability_cooldown_time
	$HealthBar.max_health = max_health

func update(frame: int) -> void:
	# Team == 7 means that it is uncontrolled.
	if team == 7:
		return
	
	if ability_cooldown > 1:
		ability_cooldown -= 1
		$ProgressBar.on_value_changed(0, (ability_cooldown_time - ability_cooldown))
		return
	
	var ray: RayCast2D
	for ray_cast: RayCast2D in $Rays.get_children():
		if not ray_cast.is_colliding():
			ray = ray_cast
			break
	if not ray:
		# Not enough space to spawn a squad
		return
	
	# Use ability and spawn a squad
	ability_cooldown = ability_cooldown_time
	$ProgressBar.on_value_changed(0, (ability_cooldown_time - ability_cooldown))
	
	var squad_scene: PackedScene
	if is_ai:
		squad_scene = ai_squad_scenes[squad_type]
	else:
		squad_scene = controllable_squad_scenes[squad_type]
	var squad: = squad_scene.instantiate()
	squad.team = team
	squad.name = "S_%d_%d" % [team, frame]
	
	squad.position = global_position + ray.target_position.rotated(ray.global_rotation)
	get_tree().get_first_node_in_group("entities_parent").add_child(squad, true)

func _on_team_color_changed(color: Color):
	$Sprites/Fill.modulate = color

func _on_health_depleted(_health: int, source: Node2D):
	health = max_health
	team = source.team
