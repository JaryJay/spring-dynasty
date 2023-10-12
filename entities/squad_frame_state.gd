## The stats of a squad at a given frame
extends RefCounted
class_name SquadFrameState

var frame: int

## The number of units in the squad
#var size: int

var health: int
#var attack: int
#var speed: float
#var attack_speed: float

var position: Vector2
var rotation: float
## The index of the squad's state in its finite state machine
var state_index: int

var target_position: Vector2
var target_squad_name: String

func _init(fr: int, h: int, p: Vector2, r: float, st_idx: int, tp: Vector2, tss: String = "") -> void:
	frame = fr
	health = h
	position = p
	rotation = r
	state_index = st_idx
	target_position = tp
	target_squad_name = tss

const _states: Array[String] = ["Idle", "Navigating", "Repositioning", "Chasing", "Attacking", "Dying"]

# I know this is weird, but at least it works (sometimes)
func _pad(s: String, num: int) -> String:
	return "...................".substr(0, num - s.length()) + s

func _to_string() -> String:
	var prefix: = _pad(str(frame), 6)
	if state_index == -1:
		return prefix + " no input"
	var state: = _states[state_index]
	if target_squad_name:
		return prefix + " state=%s, rot=%.d, pos=%.v, target=%s" % [_pad(state, 13), rad_to_deg(rotation), position, target_squad_name]
	return prefix + " state=%s, rot=%.d, pos=%.v, target=%.v" % [_pad(state, 13), rad_to_deg(rotation), position, target_position]
