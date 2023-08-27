@tool
extends CharacterBody2D
class_name Squad

@export var unit_scene: PackedScene : set = _set_unit_scene
## The number of units in the squad
@export_range(0, 42) var size: int = 10 : set = _set_size

@export_range(0, 500) var speed: float = 100

@onready var nav: = $NavigationAgent2D
@onready var rays: = $Rays
@onready var personal_space_area: = $PersonalSpaceArea
@onready var awareness_area: = $AwarenessArea

var units: Array[Unit] = []
var selected: = false : set = _set_selected

enum SquadState { IDLE, NAVIGATING, REPOSITIONING, CHASING, ATTACKING }
var state: SquadState = SquadState.IDLE

func _ready():
	_recreate_units()
	nav.target_position = global_position
	# The raycasts should only detect other objects, so we add self as an
	# exception (the ray will not detect this squad)
	for ray in rays.get_children():
		ray.add_exception(self)

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	
	match state:
		SquadState.IDLE:
			return
		SquadState.NAVIGATING:
			if nav.is_navigation_finished():
				state = SquadState.REPOSITIONING
				velocity = Vector2.ZERO
			else:
				# Recalculate path
#				nav.target_position = nav.target_position
				
				var next_path_position: Vector2 = nav.get_next_path_position()
				var new_velocity: Vector2 = global_position.direction_to(next_path_position) * speed
				if nav.avoidance_enabled:
					nav.set_velocity(new_velocity)
				else:
					_rotate_and_move(new_velocity)
			return
		SquadState.REPOSITIONING:
			if personal_space_area.get_overlapping_bodies().size() == 1:
				# The only thing in its person space is itself
				state = SquadState.IDLE
			else:
				for _ray in rays.get_children():
					var ray: RayCast2D = _ray
					if not ray.is_colliding():
						_rotate_and_move(Vector2.DOWN.rotated(ray.global_rotation) * speed)
						return
				_rotate_and_move(-position.direction_to(nav.get_final_position()) * speed)
			return
		SquadState.CHASING:
			pass
		SquadState.ATTACKING:
			pass

## Public function to begin navigation
func set_target_position(target_position: Vector2) -> void:
	nav.target_position = target_position
	state = SquadState.NAVIGATING

func _rotate_and_move(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	rays.rotation = velocity.angle() - PI / 2
	move_and_slide()

func _is_obstacle_in_front() -> bool:
	return $Rays/RayCastFront.is_colliding()

## Called once when the squad is created, or every time the squad settings
## (e.g. unit_scene, size) change in the editor
func _recreate_units() -> void:
	for unit in units:
		unit.queue_free()
	units.clear()
	if unit_scene:
		const ring_sizes: Array[int] = [2, 8, 12, 20]
		const ring_radii: Array[int] = [8, 24, 44, 64]
		
		var current_ring_index: = 0
		var ring_fill_count: = 0
		for i in range(size):
			var ring_size: = ring_sizes[current_ring_index]
			var ring_radius: = ring_radii[current_ring_index]
			
			var rot_angle: = 2 * PI * ring_fill_count / ring_size
			
			var unit: = unit_scene.instantiate()
			add_child(unit, false, Node.INTERNAL_MODE_BACK)
			unit.position = Vector2.RIGHT.rotated(rot_angle) * ring_radius
			unit.position.y *= 0.7
			units.append(unit)
			
			ring_fill_count += 1
			if ring_fill_count == ring_sizes[current_ring_index]:
				current_ring_index += 1
				ring_fill_count = 0

# Private setters

func _set_unit_scene(scene: PackedScene) -> void:
	if not unit_scene == scene:
		unit_scene = scene
		_recreate_units()

func _set_size(s: int) -> void:
	size = s
	if Engine.is_editor_hint():
		_recreate_units()

func _set_selected(value: bool) -> void:
	selected = value
	$SelectOval.visible = selected
