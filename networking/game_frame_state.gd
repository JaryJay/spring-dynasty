extends RefCounted
class_name GameFrameState

var frame: int

var squad_names: PackedStringArray = []
var squad_frame_states: Array = []

var building_names: PackedStringArray = []
var building_frame_states: Array = []

func _init(f: int):
	frame = f

func _to_string() -> String:
	var squads_str: = str(squad_names)
	var states_str: = str(squad_frame_states)
	var buildings_str: = str(building_names)
	var building_states_str: = str(building_frame_states)
	return Strings.pad(str(frame), 6) + \
		" squads=%s, states=%s, buildings=%s, b_states=%s" % \
		[squads_str, states_str, buildings_str, building_states_str]

static func create_from(bytes: PackedByteArray) -> GameFrameState:
	var arr: Array = bytes_to_var(bytes)
	var _frame: int = arr[0]
	var _squad_names: PackedStringArray = arr[1]
	var _squad_frame_states: Array = arr[2].map(SquadFrameState.create_from)
	var _building_names: PackedStringArray = arr[3]
	var _building_frame_states: Array = arr[4].map(BuildingFrameState.create_from)
	
	var frame_state: = GameFrameState.new(_frame)
	frame_state.squad_names = _squad_names
	frame_state.squad_frame_states = _squad_frame_states
	frame_state.building_names = _building_names
	frame_state.building_frame_states = _building_frame_states
	return frame_state

static func to_bytes(state: GameFrameState) -> PackedByteArray:
	var squad_frame_states_bytes: = state.squad_frame_states.map(SquadFrameState.to_bytes)
	var building_frame_states_bytes: = state.building_frame_states.map(BuildingFrameState.to_bytes)
	return var_to_bytes(
		[state.frame, state.squad_names, squad_frame_states_bytes, \
		state.building_names, building_frame_states_bytes]
	)
