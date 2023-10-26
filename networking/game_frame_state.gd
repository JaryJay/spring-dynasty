extends RefCounted
class_name GameFrameState

var frame: int

var squad_names: PackedStringArray = []
var squad_frame_states: Array = []

func _init(f: int):
	frame = f

func _to_string() -> String:
	var squads_str: = str(squad_names)
	var states_str: = str(squad_frame_states)
	return Strings.pad(str(frame), 6) + " squads=%s, states=%s" % [squads_str, states_str]

static func create_from(bytes: PackedByteArray) -> GameFrameState:
	var arr: Array = bytes_to_var(bytes)
	var _frame: int = arr[0]
	var _squad_names: PackedStringArray = arr[1]
	var _squad_frame_states: Array = arr[2].map(SquadFrameState.create_from)
	
	var frame_state: = GameFrameState.new(_frame)
	frame_state.squad_names = _squad_names
	frame_state.squad_frame_states = _squad_frame_states
	return frame_state

static func to_bytes(state: GameFrameState) -> PackedByteArray:
	var squad_frame_states_bytes: = state.squad_frame_states.map(SquadFrameState.to_bytes)
	return var_to_bytes([state.frame, state.squad_names, squad_frame_states_bytes])
