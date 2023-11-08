extends RefCounted
class_name PlayerFrameState

var frame: int
var gold: int = 0

func _init(_frame: int, _gold: int) -> void:
	frame = _frame
	gold = _gold

static func create_from(bytes: PackedByteArray) -> PlayerFrameState:
	var arr: Array = bytes_to_var(bytes)
	var _frame: int = arr[0]
	var _gold: int = arr[0]
	
	return PlayerFrameState.new(_frame, _gold)

static func to_bytes(state: PlayerFrameState) -> PackedByteArray:
	return var_to_bytes([state.frame, state.gold])
