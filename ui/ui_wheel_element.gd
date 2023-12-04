extends Node2D
class_name UIWheelElement

signal hovered

var is_hovered: = false

func _on_area_2d_mouse_entered():
	is_hovered = true
	hovered.emit()

func _on_area_2d_mouse_exited():
	is_hovered = false
