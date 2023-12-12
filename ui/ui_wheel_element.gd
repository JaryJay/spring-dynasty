@tool
extends Node2D
class_name UIWheelElement

signal hover_changed(hovered)
signal pressed

@onready var circle: = $Circle

@export var disabled: bool = false : set = _set_disabled

@export var hovered_color: Color = Color.WHITE
@export var unhovered_color: Color = Color(1, 1, 1, 0.8)
@export var disabled_color: Color = Color(.8, .8, .8, 0.9)

var is_hovered: = false :
	set(val):
		is_hovered = val
		hover_changed.emit(is_hovered)

func _on_control_gui_input(event: InputEvent):
	if event.is_action_pressed("primary_interact") and is_visible_in_tree():
		$Control.accept_event()
		pressed.emit()

func _on_control_mouse_entered():
	if disabled: return
	is_hovered = true
	circle.modulate = hovered_color
func _on_control_mouse_exited():
	is_hovered = false
	circle.modulate = unhovered_color
	if disabled: return

func _set_disabled(val: bool) -> void:
	disabled = val
	is_hovered = false
	if not is_node_ready(): return
	if disabled:
		circle.modulate = disabled_color
	else:
		circle.modulate = hovered_color
