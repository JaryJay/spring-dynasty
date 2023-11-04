extends Resource
class_name ClientInput

var frame: int
var target_position: Vector2
var squads: PackedStringArray
var state_index: int
var target_name: String

func _init(_frame: int, _state_index: int, _squads: PackedStringArray,
_target_position: Vector2, _target_name: String = ""):
	frame = _frame
	state_index = _state_index
	squads = _squads
	target_position = _target_position
	target_name = _target_name

static func create_from(bytes: PackedByteArray) -> ClientInput:
	var arr: Array = bytes_to_var(bytes)
	var _frame: int = arr[0]
	var _target_position: Vector2 = arr[1]
	var _squads: PackedStringArray = arr[2]
	var _state_index: int = arr[3]
	var _target_name: String = arr[4]
	return ClientInput.new(_frame, _state_index, _squads, _target_position, _target_name)

static func to_bytes(input: ClientInput) -> PackedByteArray:
	return var_to_bytes([input.frame, input.target_position, input.squads, input.state_index, input.target_name])

static func _test_serialization() -> void:
	var input: = ClientInput.new(1, 1, ["A", "B"], Vector2(100, 42))
	var bytes: PackedByteArray = ClientInput.to_bytes(input)
	var unserialized_input: ClientInput = ClientInput.create_from(bytes)
	assert(input.frame == unserialized_input.frame)
	assert(input.state_index == unserialized_input.state_index)
	assert(input.squads == unserialized_input.squads)
	assert(input.target_position == unserialized_input.target_position)
	assert(input.target_name == unserialized_input.target_name)

const _states: Array[String] = ["Idle", "Navigating", "Chasing", "Attacking", "Dying"]

func _to_string() -> String:
	var prefix: = Strings.pad(str(frame), 6)
	if state_index == -1:
		return prefix + " no input"
	var state: = Strings.pad(_states[state_index], 10)
	if target_name:
		return prefix + " state=%s, squads=%s, target=%s" % [state, squads, target_name]
	return prefix + " state=%s, squads=%s, target=%.v" % [state, squads, target_position]
