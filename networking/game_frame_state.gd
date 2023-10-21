extends RefCounted
class_name GameFrameState

var frame: int

var squad_names: PackedStringArray = []
var squad_frame_states: Array = []

func _init(f: int):
	frame = f
