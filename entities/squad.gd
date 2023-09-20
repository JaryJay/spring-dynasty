@tool
extends CharacterBody2D
class_name Squad

## Emitted when health reaches 0
signal health_depleted(health)

@export_range(0, 5) var team: int = 0 : set = _set_team
@export var unit_scene: PackedScene : set = _set_unit_scene
## The number of units in the squad
@export_range(0, 42) var size: int = 10 : set = _set_size

@export_group("Stats")
@export_range(0, 200) var health: int = 100 : set = _set_health
@export_range(0, 200) var attack: int = 10
@export_range(0, 400) var engage_range: float = 60
@export_range(0, 400) var range: float = 80
@export_range(0, 500) var speed: float = 150
@export_range(0, 100) var attack_speed: float = 5

@onready var debug_label: Label = $DebugLabel
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var rays: Node2D = $Rays
@onready var personal_space_area: Area2D = $PersonalSpaceArea
@onready var awareness_area: Area2D = $AwarenessArea
@onready var state_machine: StateMachine = $StateMachine

var units: Array[Unit] = []
var selected: = false : set = _set_selected

# A record of the last 30 frame states
var frame_states: Array[SquadFrameState] = []

func _ready():
	_recreate_units()
	
	if Engine.is_editor_hint():
		return
	
	nav.target_position = global_position
	# The raycasts should only detect other objects, so we add self as an
	# exception (the ray will not detect this squad)
	for ray in rays.get_children():
		ray.add_exception(self)
	
	var f: = Client.frame
	frame_states.append(SquadFrameState.new(f, health, global_position, 0))
	
	state_machine.initialize()

func _physics_process(_delta):
	if Engine.is_editor_hint():
		return
	state_machine.process_state()
	
	var f: = Client.frame
	frame_states.append(SquadFrameState.new(f, health, nav.target_position, 0))

## Public function to begin navigation
func set_target_position(target_position: Vector2) -> void:
	nav.target_position = target_position

func rotate_and_move(direction: Vector2) -> void:
	velocity = direction * speed
	rays.rotation = velocity.angle() - PI / 2
	move_and_slide()

func return_to_frame_state(frame: int) -> bool:
	for i in frame_states.size():
		var fs: = frame_states[i]
		if fs.frame == frame:
			health = fs.health
			nav.target_position = fs.target_position
			state_machine.state = state_machine.get_child(fs.state_index)
			return true
	return false

func _is_obstacle_in_front() -> bool:
	return $Rays/RayCastFront.is_colliding()

## Called once, internally, when the squad is created, or every time the squad
## settings (e.g. unit_scene, size) change in the editor
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

func _set_team(value: int) -> void:
	team = value
	$SquadBanner.team_index = team

func _set_unit_scene(scene: PackedScene) -> void:
	if not unit_scene == scene:
		unit_scene = scene
		_recreate_units()

func _set_size(s: int) -> void:
	size = s
	if Engine.is_editor_hint():
		_recreate_units()

func _set_health(value: int) -> void:
	health = value
	if not Engine.is_editor_hint() and health <= 0:
		health_depleted.emit(health)

func _set_selected(value: bool) -> void:
	selected = value
	$SelectOval.visible = selected
