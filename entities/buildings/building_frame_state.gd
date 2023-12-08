## The stats of a building at a given frame
extends RefCounted
class_name BuildingFrameState

var frame: int

var health: int
var team: int
var ability_cooldown: int
var misc_property_0: int
var misc_property_1: int

func _init(fr: int, h: int, t: int, a_c: int, m_0: int = 0, m_1: int = 0) -> void:
	frame = fr
	health = h
	team = t
	ability_cooldown = a_c
	misc_property_0 = m_0
	misc_property_1 = m_1

func _to_string() -> String:
	var prefix: = Strings.pad(str(frame), 6)
	return prefix + " health=%d, team=%d, cooldown=%d" % [health, team, ability_cooldown]

static func create_from(bytes: PackedByteArray) -> BuildingFrameState:
	var arr: Array = bytes_to_var(bytes)
	var _frame: int = arr[0]
	var _health: int = arr[1]
	var _team: int = arr[2]
	var _ability_cooldown: int = arr[3]
	var _m_0: int = arr[4]
	var _m_1: int = arr[5]
	return BuildingFrameState.new(_frame, _health, _team, _ability_cooldown, _m_0, _m_1)

static func to_bytes(s: BuildingFrameState) -> PackedByteArray:
	return var_to_bytes([s.frame, s.health, s.team, s.ability_cooldown, s.misc_property_0, s.misc_property_1])
