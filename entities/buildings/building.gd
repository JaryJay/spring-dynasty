extends StaticBody2D
class_name Building

signal team_color_changed(color)

## Emitted when the health changes
signal health_changed(old, new)
## Emitted when health reaches 0
signal health_depleted(health, source)

@export_range(0, 7) var team: int = 0 : set = _set_team_index
@export_range(1, 500) var max_health: int
@export_range(0, 400) var sight_range: int = 256

@export_group("Ability")
@export var has_ability: bool = false
@export_range(1, 1000) var ability_cooldown_time: int = 0

@onready var health: int = max_health : set = _set_health
@onready var ability_cooldown: int = ability_cooldown_time
var misc_property_0: int
var misc_property_1: int

var frame_states: Array[BuildingFrameState] = []

func _ready() -> void:
	post_update(0)
	$PointLight2D.texture_scale = 1.0 * sight_range / 32

func update(_frame: int) -> void:
	$PointLight2D.visible = is_friendly()

func post_update(frame: int) -> void:
	var fs: = BuildingFrameState.new(frame, health, team, ability_cooldown, misc_property_0, misc_property_1)
	frame_states.append(fs)
	if frame_states.size() > 30:
		frame_states.remove_at(0)

## Returns the building's state to what it was at the specified frame. Also
## deletes every element in frame_states with a later frame.
## Returns whether the frame_state at the specified frame exists.
func return_to_frame_state(frame: int) -> bool:
	for i in frame_states.size():
		var fs: BuildingFrameState = frame_states[i]
		if fs.frame == frame:
			health = fs.health
			team = fs.team
			ability_cooldown = fs.ability_cooldown
			misc_property_0 = fs.misc_property_0
			misc_property_1 = fs.misc_property_1
			
			# Delete every element in frame_states with a later frame
			frame_states = frame_states.slice(0, i + 1)
			return true
	
	printerr("%s: Building trying to return to frame %d, but the latest frame is %d" % [name, frame, frame_states[-1].frame])
	return false

func change_health(change: int, source: Node2D) -> void:
	health += change
	if health <= 0:
		health_depleted.emit(health, source)

func get_player() -> Player:
	var players: = get_tree().get_nodes_in_group("players")
	var filtered_players: = players.filter(func(p): return p.team == team)
	if filtered_players.is_empty():
		return null
	return filtered_players[0] as Player

func _set_team_index(value: int) -> void:
	if value >= 0 and value < TeamColors.colors.size():
		team = value
		team_color_changed.emit(TeamColors.colors[team])
	else:
		printerr("Invalid color index: %d" % value)

func _set_health(value: int) -> void:
	if health == value: return
	
	var old: = health
	health = value
	
	if not is_node_ready() or Engine.is_editor_hint(): return
	
	health_changed.emit(old, health)

func is_friendly() -> bool:
	if not get_tree().has_group("level"):
		printerr("You cannot call is_friendly outside of a level.")
		return false
	return team == get_tree().get_first_node_in_group("level").controlled_team

func is_friendly_to(other_team: int) -> bool:
	return team == other_team
