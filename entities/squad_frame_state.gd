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
