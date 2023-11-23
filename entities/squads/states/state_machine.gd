extends Node
class_name StateMachine

@export var squad: Squad
@export var default_state: State

var state: State = default_state : set = _set_state

func initialize() -> void:
	state = default_state
	
	for child in get_children():
		if not child is State:
			printerr("StateMachine Error: Child %s is not a state." % child.name)

func process_state() -> void:
	state.process(squad)

func _set_state(value: State) -> void:
	if state:
		state._exit_state(squad)
	
	if not value:
		printerr("Hey! You're setting the state to null. That's not right")
		printerr("Transitioning from %s to null" % state.name)
		return
	
	if not state == value:
		state = value
		state._enter_state(squad)
	
