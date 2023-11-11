extends Resource
class_name ConsoleCommand

var name: StringName
var num_args: int = 0
var f: Callable

func _init(_name: StringName, _num_args: int, _f: Callable):
	name = _name
	num_args = _num_args
	f = _f
