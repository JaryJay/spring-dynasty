extends Resource
class_name ClientInput

enum InputType {
	EMPTY,
	SQUADS_NAVIGATE,
	SQUADS_CHASE,
	ENTITIES_CHANGE,
}

var frame: int
var input_type: InputType

var entities: PackedStringArray

var target_position: Vector2
var target_name: String

var property: int

func _init(_frame: int, _input_type: InputType):
	frame = _frame
	input_type = _input_type

static func create_from(bytes: PackedByteArray) -> ClientInput:
	var arr: Array = bytes_to_var(bytes)
	var _frame: int = arr[0]
	var _input_type: InputType = arr[1]
	var input: = ClientInput.new(_frame, _input_type)
	match _input_type:
		InputType.SQUADS_NAVIGATE:
			input.entities = arr[2]
			input.target_position = arr[3]
		InputType.SQUADS_CHASE:
			input.entities = arr[2]
			input.target_name = arr[3]
		InputType.ENTITIES_CHANGE:
			input.entities = arr[2]
			input.property = arr[3]
	return input

static func to_bytes(input: ClientInput) -> PackedByteArray:
	var arr: Array = [input.frame, input.input_type]
	match input.input_type:
		InputType.SQUADS_NAVIGATE:
			arr.append(input.entities)
			arr.append(input.target_position)
		InputType.SQUADS_CHASE:
			arr.append(input.entities)
			arr.append(input.target_name)
		InputType.ENTITIES_CHANGE:
			arr.append(input.entities)
			arr.append(input.property)
	return var_to_bytes(arr)

static func _test_serialization() -> void:
	var input: = ClientInput.new(1, InputType.SQUADS_NAVIGATE)
	input.entities = ["A", "B"]
	input.target_position = Vector2(100, 42)
	var bytes: PackedByteArray = ClientInput.to_bytes(input)
	var unserialized_input: ClientInput = ClientInput.create_from(bytes)
	assert(input.frame == unserialized_input.frame)
	assert(input.input_type == unserialized_input.input_type)
	assert(input.entities == unserialized_input.entities)
	assert(input.target_position == unserialized_input.target_position)
	assert(input.target_name == unserialized_input.target_name)

const _states: Array[String] = ["Idle", "Navigating", "Chasing", "Attacking", "Dying"]

func _to_string() -> String:
	var prefix: = Strings.pad(str(frame), 6)
	if input_type == InputType.EMPTY:
		return prefix
	#var state: = Strings.pad(_states[state_index], 10)
	#if target_name:
		#return prefix + " state=%s, squads=%s, target=%s" % [state, squads, target_name]
	#return prefix + " state=%s, squads=%s, target=%.v" % [state, squads, target_position]
	return prefix + " type=%d, entities=%s" % [input_type, entities]
