extends Node
class_name Player

var team: int
var frame_states: Array[PlayerFrameState] = []
var gold: int

func _ready() -> void:
	add_to_group("players")
	frame_states.append(PlayerFrameState.new(0, gold))

func update() -> void:
	pass

func post_update(frame: int) -> void:
	var new_fs: = PlayerFrameState.new(frame, gold)
	frame_states.append(new_fs)
	if frame_states.size() > 30:
		frame_states.remove_at(0)

func return_to_frame_state(f: int) -> bool:
	var index: = 0
	
	for i in frame_states.size():
		var fs: PlayerFrameState = frame_states[i]
		if fs.frame == f:
			index = i
			
			# Delete every element in frame_states with a later frame
			frame_states = frame_states.slice(0, index + 1)
			return true
	
	printerr("%s: Player trying to return to frame %d, but the latest frame is %d" % [name, f, frame_states[-1].frame])
	return false
