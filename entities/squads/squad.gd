@tool
extends CharacterBody2D
class_name Squad

## Emitted when the health changes
signal health_changed(old, new)
## Emitted when health reaches 0
signal health_depleted(health, source)

@export_range(0, 5) var team: int = 0 : set = _set_team
@export var unit_scene: PackedScene : set = _set_unit_scene
## The number of units in the squad
@export_range(0, 42) var size: int = 10 : set = _set_size

@export_group("Stats")
@export_range(0, 200) var health: int = 100 : set = _set_health
@export_range(0, 200) var attack: int = 10
@export_range(0, 400) var engage_range: int = 60
@export_range(0, 400) var range: int = 80
@export_range(0, 400) var sight_range: int = 256
@export_range(0, 500) var speed: int = 150
@export_range(0, 240) var attack_cooldown: int = 60

@onready var debug_label: Label = $DebugLabel
@onready var nav: NavigationAgent2D = $NavigationAgent2D
@onready var rays: Node2D = $Rays
@onready var push_area: Area2D = $PushArea
@onready var awareness_area: Area2D = $AwarenessArea
@onready var state_machine: StateMachine = $StateMachine

@onready var banner: = $SquadBanner
@onready var attack_particles: = $AttackParticles

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
	
	if Client.is_multiplayer():
		frame_states.append(SquadFrameState.new(Client.level.frame, health, position, rotation, 0, global_position))
	state_machine.initialize()
	
	$HealthBar.max_health = health
	$PointLight2D.texture_scale = 1.0 * sight_range / 32
	$PointLight2D.hide()

## Called in level.gd
func update(_frame: int) -> void:
	state_machine.process_state()
	
	$PointLight2D.visible = is_friendly()

## Called in level.gd after update() is called on all squads
func post_update(frame: int) -> void:
	if health <= 0:
		state_machine.state = $StateMachine/DyingState
	
	if frame_states.is_empty() or frame_states[-1].frame < frame:
		var s: = state_machine.state.get_index()
		var rot: = rays.global_rotation
		var frame_state: SquadFrameState
		if state_machine.state._requires_target():
			var target_name: String = state_machine.state.target.name
			frame_state = SquadFrameState.new(frame, health, position, rot, s, position, target_name)
		else:
			frame_state = SquadFrameState.new(frame, health, position, rot, s, nav.target_position)
		if state_machine.state is AttackingState:
			frame_state.attack_cooldown = state_machine.state.cooldown
		frame_states.append(frame_state)
		if frame_states.size() > 30:
			frame_states.remove_at(0)

## Public function to begin navigation.
func set_target_position(target_position: Vector2) -> void:
	nav.target_position = target_position

func rotate_and_move(direction: Vector2, speed_multiplier: float = 1) -> void:
	velocity = direction * speed * speed_multiplier
	rays.rotation = velocity.angle() - PI / 2
	move_and_slide()

## Returns the squad's state to what it was at the specified frame. Also deletes
## every element in frame_states with a later frame.
## Returns whether the frame_state at the specified frame exists.
func return_to_frame_state(frame: int) -> bool:
	for i in frame_states.size():
		var fs: = frame_states[i]
		if not fs.frame == frame:
			continue
		
		health = fs.health
		position = fs.position
		rays.rotation = fs.rotation
		nav.target_position = fs.target_position
		state_machine.state = state_machine.get_child(fs.state_index)
		
		var entities_parent: = get_tree().get_first_node_in_group("entities_parent")
		if state_machine.state._requires_target():
			var targ: Node2D = entities_parent.get_node(fs.target_name)
			state_machine.state.target = targ
		if state_machine.state is AttackingState:
			state_machine.state.cooldown = fs.attack_cooldown
		
		# Delete every element in frame_states with a later frame
		frame_states = frame_states.slice(0, i + 1)
		return true
	
	printerr("%s: Squad trying to return to frame %d, but the oldest frame is %d" % [name, frame, frame_states[-1].frame])
	return false

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

func change_health(change: int, source: Node2D) -> void:
	health += change
	if health <= 0:
		health_depleted.emit(health, source)

func is_alive() -> bool:
	return not state_machine.state is DyingState

func is_friendly() -> bool:
	if not get_tree().has_group("level"):
		printerr("You cannot call is_friendly outside of a level.")
		return false
	return team == get_tree().get_first_node_in_group("level").controlled_team

func is_friendly_to(other_team: int) -> bool:
	return team == other_team

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
	if health == value: return
	
	var old: = health
	health = value
	
	if not is_node_ready(): return
	
	health_changed.emit(old, health)

func _set_selected(value: bool) -> void:
	selected = value
	$SelectOval.visible = selected
