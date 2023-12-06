@tool
extends Node2D
class_name UIWheelElement

signal hover_changed(hovered)
signal pressed

@onready var icon: = $Icon
@export var texture: Texture2D :
	set(val):
		texture = val
		icon.texture = val

@export var hovered_color: Color = Color.WHITE
@export var unhovered_color: Color = Color(1, 1, 1, 0.8)

var is_hovered: = false :
	set(val):
		is_hovered = val
		hover_changed.emit(is_hovered)

func _on_area_2d_mouse_entered():
	is_hovered = true
	icon.modulate = hovered_color
	print_debug("hi")
func _on_area_2d_mouse_exited():
	is_hovered = false
	icon.modulate = unhovered_color

