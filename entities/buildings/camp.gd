class_name Camp extends Building

enum SquadType {
	FOOTMAN,
	ARCHER,
	SWORDSMAN,
}

@export var squad_type: SquadType
@export var is_ai: bool
@export var controllable_squad_scenes: Array[PackedScene]
@export var ai_squad_scenes: Array[PackedScene]

@export_group("Ability")
@export_range(1, 200) var change_cooldown_time: int
@export_range(1, 200) var training_cost: int

func _ready() -> void:
	super()
	$ChangeProgressBar.max_value = change_cooldown_time
	$ProgressBar.max_value = ability_cooldown_time
	$HealthBar.max_health = max_health
	misc_property_0 = -1 # We use misc_property_0 as our change cooldown.
	
	$UIWheel.select($"UIWheel/0")

func update(frame: int) -> void:
	super.update(frame)
	# If local player is not the owner of this building, then disable ui_wheel.
	var local_player_team: int = get_tree().get_first_node_in_group("level").controlled_team
	$UIWheel.disabled = not local_player_team == team
	
	# Team == 7 means that it is uncontrolled.
	if team == 7:
		return
	
	# If a squad type change is in progress
	if misc_property_0 != -1:
		if misc_property_0 > 1:
			misc_property_0 -= 1
			$ChangeProgressBar.on_value_changed(0, change_cooldown_time - misc_property_0)
			return
		misc_property_0 = -1
		$UIWheel.disabled = false
		$ChangeProgressBar.on_value_changed(0, change_cooldown_time - misc_property_0)
		# misc_property_1 is the squad type to change to
		squad_type = misc_property_1 as SquadType
		return
	
	if ability_cooldown > 1:
		if ability_cooldown == ability_cooldown_time:
			var player: = get_player()
			# Only start ability cooldown if player has enough gold
			if player.gold >= training_cost:
				player.gold -= training_cost
				ability_cooldown -= 1
			return
		
		ability_cooldown -= 1
		$ProgressBar.on_value_changed(0, (ability_cooldown_time - ability_cooldown))
		return
	
	# Use raycasts to check if there is enough space to spawn a squad.
	var ray: RayCast2D
	for ray_cast: RayCast2D in $Rays.get_children():
		ray_cast.force_raycast_update()
		if not ray_cast.is_colliding():
			ray = ray_cast
			break
	if not ray:
		# All rays are colliding, thus there is no space to spawn a squad.
		# Note that we don't reset the ability cooldown.
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

func change_type_to(type: int) -> void:
	$UIWheel.disabled = true
	misc_property_0 = change_cooldown_time
	misc_property_1 = type

func _on_team_color_changed(color: Color):
	$Sprites/Fill.modulate = color

func _on_health_depleted(_health: int, source: Node2D):
	health = max_health
	team = source.team
	ability_cooldown = ability_cooldown_time

func _on_ui_wheel_element_pressed(element: UIWheelElement):
	if element.name.to_int() == squad_type: return
	# Create ClientInput and add it to local_input_queue
	var input: = ClientInput.new(0, ClientInput.InputType.ENTITIES_CHANGE)
	input.entities = [name]
	input.property = element.name.to_int() # kinda a hack but whatever
	
	var level: Level = get_tree().get_first_node_in_group("level")
	level.local_input_queue.append(input)
	
	$UIWheel.select(element)

