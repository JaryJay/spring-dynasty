@tool
extends Node
class_name StateMachine

@export var squad: Squad
@export var default_state: State

var state: State = default_state : set = _set_state

func initialize() -> void:
	state = default_state

func process_state() -> void:
	state.process(squad)

func _set_state(value: State) -> void:
	if state:
		state._exit_state(squad)
	if not value:
		print_debug("Hey! You're setting the state to null. That's not right")
		print_debug("Transitioning from %s to null" % state.name)
		return
	state = value
	state._enter_state(squad)

# Tool-related functions

func _enter_tree():
	if Engine.is_editor_hint():
		child_entered_tree.connect(func(_n): update_configuration_warnings())

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	for child in get_children():
		if not child is State:
			warnings.append("Not all children are states: %s" % child.name)
	return warnings
