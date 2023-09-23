extends Resource
class_name ClientInput

var frame: int
var target: Vector2
var squads: PackedStringArray
var state: StringName
var enemy_squad: StringName

func _init(frame: int, state: StringName, squads: PackedStringArray,
	target: Vector2, enemy_squad: StringName = ""):
		self.frame = frame
		self.state = state
		self.squads = squads
		self.target = target
		self.enemy_squad = enemy_squad

static func create_from(bytes: PackedByteArray) -> ClientInput:
#	var frame: = bytes.decode_s64(0)
#	var target_x: = bytes.decode_float(8)
#	var target_y: = bytes.decode_float(16)
#	var target: = Vector2(target_x, target_y)
#	var _squads_size: = bytes.decode_var_size(24)
#	var squads: = bytes.decode_var(24)
#	var state: = bytes.decode_var(24 + _squads_size)
	return bytes_to_var_with_objects(bytes) as ClientInput

static func to_bytes(input: ClientInput) -> PackedByteArray:
#	var bytes: PackedByteArray = []
#	bytes.append_array(var_to_bytes(frame))
#	bytes.append_array(var_to_bytes(target))
#	bytes.append_array(var_to_bytes(state))
#	bytes.append_array(var_to_bytes(squads))
#	bytes.append_array(var_to_bytes(enemy_squad))
	return var_to_bytes_with_objects(input)
