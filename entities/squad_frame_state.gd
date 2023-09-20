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

var target_position: Vector2
## The index of the squad's state in its finite state machine
var state_index: int

func _init(fr: int, h: int, tp: Vector2, st_idx: int) -> void:
	frame = fr
	health = h
	target_position = tp
	state_index = st_idx
