extends Resource
class_name ClientInput

var frame: int
var target: Vector2
var squads: PackedStringArray
var state_index: int
var enemy_squad: String

func _init(_frame: int, _state_index: int, _squads: PackedStringArray,
_target: Vector2, _enemy_squad: String = ""):
	frame = _frame
	state_index = _state_index
	squads = _squads
	target = _target
	enemy_squad = _enemy_squad

static func create_from(bytes: PackedByteArray) -> ClientInput:
	var arr: Array = bytes_to_var(bytes)
	var _frame: int = arr[0]
	var _target: Vector2 = arr[1]
	var _squads: PackedStringArray = arr[2]
	var _state_index: int = arr[3]
	var _enemy_squad: String = arr[4]
	return ClientInput.new(_frame, _state_index, _squads, _target, _enemy_squad)

static func to_bytes(input: ClientInput) -> PackedByteArray:
	return var_to_bytes([input.frame, input.target, input.squads, input.state_index, input.enemy_squad])

static func _test_serialization() -> void:
	var input: = ClientInput.new(1, 1, ["A", "B"], Vector2(100, 42))
	var bytes: PackedByteArray = ClientInput.to_bytes(input)
	var unserialized_input: ClientInput = ClientInput.create_from(bytes)
	assert(input.frame == unserialized_input.frame)
	assert(input.state_index == unserialized_input.state_index)
	assert(input.squads == unserialized_input.squads)
	assert(input.target == unserialized_input.target)
	assert(input.enemy_squad == unserialized_input.enemy_squad)

const _states: Array[String] = ["Idle", "Navigating", "Repositioning", "Chasing", "Attacking", "Dying"]

# I know this is weird, but at least it works (sometimes)
func _pad(s: String, num: int) -> String:
	return "...................".substr(0, num - s.length()) + s

func _to_string() -> String:
	var prefix: = _pad(str(frame), 6)
	if state_index == -1:
		return prefix + " no input"
	var state: = _states[state_index]
	if enemy_squad:
		return prefix + " state=%s, squads=%s, enemy=%s" % [_pad(state, 13), squads, enemy_squad]
	return prefix + " state=%s, squads=%s, target=%.v" % [_pad(state, 13), squads, target]
