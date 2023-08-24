@tool
extends CharacterBody2D
class_name Squad

@export var unit_scene: PackedScene : set = _set_unit_scene

## The number of units in the squad
@export_range(0, 42) var size: int = 10 : set = _set_size
@export_range(0, 500) var speed: float = 100

var units: Array[Unit] = []
var selected: = false : set = _set_selected

@onready var nav: = $NavigationAgent2D

# Called when the node enters the scene tree for the first time.
func _ready():
	_recreate_units()

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	if nav.is_navigation_finished():
		velocity = Vector2.ZERO
		print("Navigation finished for %s" % name)
		return
	
	var next_path_position: Vector2 = nav.get_next_path_position()
	var new_velocity: Vector2 = global_position.direction_to(next_path_position) * speed
	if nav.avoidance_enabled:
		nav.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _set_unit_scene(scene: PackedScene) -> void:
	if not unit_scene == scene:
		unit_scene = scene
		_recreate_units()

func _set_size(s: int) -> void:
	size = s
	if Engine.is_editor_hint():
		_recreate_units()

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
			add_child(unit, false, Node.INTERNAL_MODE_FRONT)
			unit.position = Vector2.RIGHT.rotated(rot_angle) * ring_radius
			unit.position.y *= 0.7
			units.append(unit)
			
			ring_fill_count += 1
			if ring_fill_count == ring_sizes[current_ring_index]:
				current_ring_index += 1
				ring_fill_count = 0

func _set_selected(value: bool) -> void:
	selected = value
	$SelectOval.visible = selected
