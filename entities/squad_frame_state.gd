## The stats of a squad at a given frame
extends RefCounted
class_name SquadFrameState

var frame: int

## The number of units in the squad
#var size: int

var health: int
#var attack: int
#var speed: float
#var attack_cooldown: float

var position: Vector2
var rotation: float
## The index of the squad's state in its finite state machine
var state_index: int

var target_position: Vector2
var target_squad_name: String
var attack_cooldown: int

func _init(fr: int, h: int, p: Vector2, r: float, st_idx: int, tp: Vector2, \
tss: String = "", att_cd: int = 0) -> void:
	frame = fr
	health = h
	position = p
	rotation = r
	state_index = st_idx
	target_position = tp
	target_squad_name = tss
	attack_cooldown = att_cd

const _states: Array[String] = ["Idle", "Navigating", "Repositioning", "Chasing", "Attacking", "Dying"]

func _to_string() -> String:
	var prefix: = Strings.pad(str(frame), 6)
	if state_index == -1:
		return prefix + " no input"
	var state: = Strings.pad(_states[state_index], 13)
	var rot: = rad_to_deg(rotation)
	if target_squad_name:
		return prefix + " state=%s, rot=%4.d, pos=%4.v, target=%s" % [state, rot, position, target_squad_name]
	return prefix + " state=%s, rot=%4.d, pos=%4.v, target=%4.v" % [state, rot, position, target_position]
