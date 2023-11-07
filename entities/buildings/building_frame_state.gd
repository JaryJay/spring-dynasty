## The stats of a building at a given frame
extends RefCounted
class_name BuildingFrameState

var frame: int

var health: int
var team: int
var ability_cooldown: int

func _init(fr: int, h: int, t: int, a_c: int) -> void:
	frame = fr
	health = h
	team = t
	ability_cooldown = a_c

func _to_string() -> String:
	var prefix: = Strings.pad(str(frame), 6)
	return prefix + " health=%d, team=%d, cooldown=%d" % [health, team, ability_cooldown]

static func create_from(bytes: PackedByteArray) -> BuildingFrameState:
	var arr: Array = bytes_to_var(bytes)
	var _frame: int = arr[0]
	var _health: int = arr[1]
	var _team: int = arr[2]
	var _ability_cooldown: int = arr[3]
	return BuildingFrameState.new(_frame, _health, _team, _ability_cooldown)

static func to_bytes(state: BuildingFrameState) -> PackedByteArray:
	return var_to_bytes([state.frame, state.health, state.team, state.ability_cooldown])
