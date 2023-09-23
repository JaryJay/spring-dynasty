extends Resource
class_name ClientInput

var frame: int
var target: Vector2
var squads: PackedStringArray
var state: StringName
var enemy_squad: String

func _init(_frame: int, _state: StringName, _squads: PackedStringArray,
_target: Vector2, _enemy_squad: String = ""):
	frame = _frame
	state = _state
	squads = _squads
	target = _target
	enemy_squad = _enemy_squad

static func create_from(bytes: PackedByteArray) -> ClientInput:
	var arr: Array = bytes_to_var(bytes)
	var _frame: int = arr[0]
	var _target: Vector2 = arr[1]
	var _squads: PackedStringArray = arr[2]
	var _state: StringName = arr[3]
	var _enemy_squad: String = arr[4]
	return ClientInput.new(_frame, _state, _squads, _target, _enemy_squad)

static func to_bytes(input: ClientInput) -> PackedByteArray:
	return var_to_bytes([input.frame, input.target, input.squads, input.state, input.enemy_squad])

static func _test_serialization() -> void:
	var input: = ClientInput.new(1, "1", ["A", "B"], Vector2(100, 42))
	var bytes: PackedByteArray = ClientInput.to_bytes(input)
	var unserialized_input: ClientInput = ClientInput.create_from(bytes)
	assert(input.frame == unserialized_input.frame)
	assert(input.state == unserialized_input.state)
	assert(input.squads == unserialized_input.squads)
	assert(input.target == unserialized_input.target)
	assert(input.enemy_squad == unserialized_input.enemy_squad)
